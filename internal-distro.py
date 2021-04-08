#!/usr/bin/env python
from __future__ import print_function
from collections import namedtuple
import argparse
import os
import re
import sys
import vcstools
import yaml
import rospkg
from catkin_pkg.package import parse_package

DEPENDENCY_TYPES = [
    'build_depends',
    'build_export_depends',
    'buildtool_depends',
    'buildtool_export_depends',
    'doc_depends',
    'exec_depends',
    'test_depends',
]

class Repository(object):
    def __init__(self, name, options):
        self.name = name
        self.location = None

        source_dict = options.get('source')
        if source_dict is None:
            raise ValueError(
                'Repository "{:s}" is missing the "source" key.'.format(name))

        self.vcs_version = source_dict.get('version')
        self.packages = source_dict.get('packages', [name])

        self.vcs_type = source_dict.get('type')
        if self.vcs_type is None:
            raise ValueError(
                'Repository "{:s}" source settings is missing the "type"'
                ' field.'.format(name))

        self.vcs_uri = source_dict.get('url')
        if self.vcs_uri is None:
            raise ValueError(
                'Repository "{:s}" source settings is missing the "url"'
                ' field.'.format(name))


class Package(object):
    def __init__(self, name, repository):
        self.name = name
        self.repository = repository
        self.location = None


class WstoolClient(object):
    def __init__(self, directory, filename='.rosinstall'):
        self.directory = directory
        self.filename = filename

    def __enter__(self):
        import os.path.join

        self.rosinstall_file = open(
            os.path.join(self.directory, self.filename), 'r')
        self.rosinstall_file.__enter__()

        return self

    def __exit__(self, type, value, traceback):
        return self.rosinstall_file.__exit__(type, value, traceback)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--workspace', type=str, default='.')
    parser.add_argument('distribution_file', type=str)
    parser.add_argument('--package', type=str, action='append', dest='target_packages', default=[])
    parser.add_argument('--repository', type=str, action='append', dest='target_repositories', default=[])
    parser.add_argument('--required-only', action='store_true', dest='required_dependencies_only')
    args = parser.parse_args()

    if not os.path.exists(args.workspace):
        os.makedirs(args.workspace)

    if not os.path.isdir(args.workspace):
        raise ValueError('Workspace "{:s}" is not a directory.'.format(args.workspace))

    # Load the distribution file.
    with open(args.distribution_file, 'rb') as distribution_file:
        distribution_raw = yaml.load(distribution_file, Loader=yaml.FullLoader)

    packages_raw = distribution_raw.get('repositories')
    if packages_raw is None:
        raise ValueError('Distribution is missing the "repositories" key.')

    repositories = {
        name: Repository(name, options)
        for name, options in packages_raw.items()
    }

    # Build a map from package name to the repository that contains it, based
    # soley on the information in the distribution file.
    distribution_package_map = dict()

    for repository in repositories.values():
        for package_name in repository.packages:
            existing_repository = distribution_package_map.get(package_name)
            if existing_repository is not None:
                raise ValueError(
                    'Duplicate package "{:s}" in repositories "{:s}" and'
                    ' "{:s}".'.format(
                        package_name, existing_repository.name,
                        repository.name))

            distribution_package_map[package_name] = Package(
                package_name, repository)

    # Aggregate a map of packages that we know about.
    package_map = dict(distribution_package_map)
    done_packages = set() # installed and processed
    installed_packages = set() # installed, but not processed yet
    pending_packages = set(args.target_packages)

    for repository_name in args.target_repositories:
        repository = repositories.get(repository_name)
        if repository is None:
            raise ValueError('There is no repository named "{:s}".'.format(
                repository_name))

        pending_packages.update(repository.packages)

    while pending_packages:
        package_name = pending_packages.pop()

        print('Processing package "{:s}"'.format(package_name))

        package = package_map.get(package_name)
        if package is None:
            raise ValueError(
                'Package "{:s}" is not in the distribution.'.format(
                    package_name))

        # Checkout the repository.
        repository = package.repository

        if repository.location is None:
            repository.location = os.path.join(args.workspace, repository.name)

            print('  Checking out "{:s}" repository => {:s}'.format(
                repository.name, repository.location))

            client = vcstools.get_vcs_client(
                repository.vcs_type, repository.location)

            if client.detect_presence():
                detected_url = client.get_url()

                if not client.url_matches(detected_url, repository.vcs_uri):
                    raise ValueError(
                        'Directory "{:s}" already contains a VCS repository with'
                        ' URL "{:s}". This does not match the requested URL'
                        ' "{:s}".'.format(repository_name, detected_url, repository.vcs_uri))

                client.update(version=repository.vcs_version)
            else:
                client.checkout(repository.vcs_uri, version=repository.vcs_version)

            # Search for packages in the repository.
            repository_package_map = dict()
            rospkg.list_by_path(
                manifest_name='package.xml',
                path=repository.location,
                cache=repository_package_map)

            if package.name not in repository_package_map:
                raise ValueError(
                    'Repository "{:s}" checked out from the "{:s}" repository'
                    ' "{:s}" does not contain the package "{:s}".'.format(
                        repository.name, repository.vcs_type,
                        repository.vcs_uri, package.name))

            # Mark all of these packages as installed.
            for package_name, location in repository_package_map.items():
                installed_package = package_map.get(package_name)

                if installed_package is None:
                    installed_package = Package(package_name, repository)
                    package_map[package_name] = installed_package
                elif (installed_package.repository != repository or
                      installed_package.location is not None):
                    raise ValueError(
                        'Repository "{:s} installed duplicate package "{:s}"'
                        ' in directory "{:s}". This package was already installed'
                        ' by repository "{:s}" in directory "{:s}".'.format(
                            repository.name, package_name, location,
                            installed_package.repository.name,
                            installed_package.location))

                installed_package.location = location

                print('    Found package "{:s}" => {:s}'.format(
                    installed_package.name, installed_package.location))

            installed_packages.update(repository_package_map.keys())

        # Crawl dependencies.
        package_xml_path = os.path.join(package.location, 'package.xml')
        package_manifest = parse_package(package_xml_path)

        all_depends = set()
        for dependency_type in DEPENDENCY_TYPES:
            for dependency in getattr(package_manifest, dependency_type):
                all_depends.add(dependency.name)

        # Remove optional dependencies
        if args.required_dependencies_only:
            optional_depends = set()
            for export in package_manifest.exports:
                if export.tagname != 'optional':
                    continue

                dependency_name = export.content
                if dependency_name not in all_depends:
                    raise ValueError(
                        'Optional dependency "{:s}" not found in package "{:s}".'.format(
                            dependency_name, package.name))

                optional_depends.add(dependency_name)

            # Note: this rewriting procedure assumes that only one <depend> tag
            # is on each line.
            depend_re = re.compile(r'<depend>(.*?)</depend>')
            def is_optional_dependency(line):
                depend_matches = re.findall(depend_re, line)
                return len(depend_matches) == 1 and depend_matches[0] in optional_depends

            with open(package_xml_path) as f:
                lines = f.readlines()

            with open(package_xml_path, 'w') as f:
                f.writelines(
                    [line for line in lines if not is_optional_dependency(line)]
                )

            all_depends -= optional_depends

        # Only keep the dependencies that we know about.
        def annotate_package_name(package_name):
            if package_name in done_packages:
                return package_name + '*'
            elif package_name in installed_packages:
                return package_name + '^'
            else:
                return package_name

        known_depends = all_depends.intersection(
            distribution_package_map.keys())
        if known_depends:
            print('  Depends on:', ' '.join(
                sorted(map(annotate_package_name, known_depends))))

        done_packages.add(package.name)
        pending_packages.update(known_depends)

    # Print a summary and generate CATKIN_IGNORE files for installed packages
    # that we do not explicitly depend on.
    for package_name in installed_packages:
        package = package_map[package_name]

        if package_name not in done_packages:
            catkin_ignore_path = os.path.join(package.location, 'CATKIN_IGNORE')
            with open(catkin_ignore_path, 'wb'):
                pass

            suffix = ' [IGNORED]'
        else:
            suffix = ''

        print('Package "{:s}" => {:s}{:s}'.format(package.name, package.location, suffix))


if __name__ == '__main__':
    main()
