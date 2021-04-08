#!/usr/bin/env python
from __future__ import print_function
from collections import namedtuple
import argparse
import sys
import os
import vcstools
import yaml
import rospkg
from catkin_pkg.package import parse_package
from future.utils import iteritems

DEPENDENCY_TYPES =  [
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
    parser.add_argument('repository', type=str)
    args = parser.parse_args()

    # Load the distribution file.
    with open(args.distribution_file, 'rb') as distribution_file:
        distribution_raw = yaml.load(distribution_file, Loader=yaml.FullLoader)

    packages_raw = distribution_raw.get('repositories')
    if packages_raw is None:
        raise ValueError('Distribution is missing the "repositories" key.')

    repositories = {
        name: Repository(name, options)
        for name, options in iteritems(packages_raw) }

    print(' '.join(repositories[args.repository].packages))

if __name__ == '__main__':
    main()
