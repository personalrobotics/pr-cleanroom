#!/usr/bin/env python
from collections import defaultdict
from xml.etree import ElementTree
import argparse


class Color:
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    DARKCYAN = '\033[36m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'


class TestSuite(object):
    def __init__(self, element=None):
        self.element = element
        self.tests = []
        self.fixtures = dict()

    @property
    def name(self):
        return self.element.attrib['name']

    @property
    def num_tests(self):
        return int(self.element.attrib['tests'])

    @property
    def num_succeeded(self):
        return self.num_tests - self.num_disabled - self.num_failed

    @property
    def num_disabled(self):
        num_disabled = self.element.attrib.get('num_disabled')
        if num_disabled is not None:
            return int(num_disabled) # gtest uses num_disabled

        num_skipped = self.element.attrib.get('num_skipped')
        if num_skipped is not None:
            return int(num_skipped) # nosetest uses num_skipped

        return 0

    @property
    def num_failed(self):
        return int(self.element.attrib['failures'])

class TestFixture(object):
    def __init__(self, name):
        self.name = name
        self.tests = []

    @property
    def num_succeeded(self):
        return sum(int(test.is_successful)
                   for test in self.tests)

    @property
    def num_disabled(self):
        return sum(int(not test.is_run)
                   for test in self.tests)

    @property
    def num_failed(self):
        return sum(int(test.is_run and not test.is_successful)
                   for test in self.tests)


class Test(object):
    def __init__(self, element):
        self.element = element

    @property
    def name(self):
        return self.element.attrib['name']

    @property
    def is_successful(self):
        return self.is_run and not list(self.failures)

    @property
    def is_run(self):
        return self.element.attrib.get('status', 'run') == 'run'

    @property
    def failures(self):
        for child_element in self.element.getchildren():
            if child_element.tag == 'failure':
                error_type = child_element.attrib.get('type', '')
                error_message = child_element.attrib.get('message', 'unknown')

                if error_type:
                    yield '{:s}: {:s}'.format(error_type, error_message)
                else:
                    yield error_message


def parse(element, fixture_map):
    if element.tag == 'testcase':
        test = Test(element)

        classname = element.attrib.get('classname')
        if classname is not None:
            fixture = fixture_map.get(classname)
            if fixture is None:
                fixture = TestFixture(classname)
                fixture_map[classname] = fixture

            fixture.tests.append(test)
            return None
        else:
            return test
    elif element.tag == 'testsuite':
        suite = TestSuite(element)

        for child_element in element.getchildren():
            child_output = parse(child_element, suite.fixtures)

            if child_output is None:
                pass
            elif isinstance(child_output, Test):
                suite.tests.append(child_output)
            else:
                raise TypeError('Output "{:s}" has unknown type.'.format(child_output))

        return suite
    elif element.tag == 'testsuites':
        return [parse(child_element, fixture_map)
                for child_element in element.getchildren()]
    else:
        return None


def get_indent(n):
    return ' ' * n


def get_formatted_header(title):
    return Color.BOLD + title + Color.END


def get_formatted_status(node):
    if not node.is_run:
        return Color.YELLOW + 'skipped' + Color.END
    elif node.is_successful:
        return Color.GREEN + 'succeeded' + Color.END
    else:
        return Color.RED + 'failed' + Color.END


def get_formatted_summary(node):
    warnings = []

    if node.num_succeeded > 0:
        warnings.append('{:d} {:s}'.format(node.num_succeeded, 'succeeded'))

    if node.num_failed > 0:
        warnings.append('{:d} {:s}'.format(node.num_failed, Color.RED + 'failed' + Color.END))

    if node.num_disabled > 0:
        warnings.append('{:d} {:s}'.format(node.num_disabled, Color.YELLOW + 'skipped' + Color.END))

    if warnings:
        return ', '.join(warnings)
    else:
        return 'empty'


def output(node, indent=0):
    if node is None:
        pass

    elif isinstance(node, list):
        for child_node in node:
            output(child_node, indent=indent)

    elif isinstance(node, Test):
        print '{:s}+ {:s} ({:s})'.format(get_indent(indent), node.name, get_formatted_status(node))

        has_failure = False
        for failure in node.failures:
            print '-' * 80
            print failure
            has_failure = True

        if has_failure:
            print '-' * 80
            print

    elif isinstance(node, TestFixture):
        warnings_str = get_formatted_summary(node)
        if warnings_str:
            print '{:s}+ {:s} - {:s}'.format(get_indent(indent), get_formatted_header(node.name), warnings_str)
        else:
            print '{:s}+ {:s}'.format(get_indent(indent), get_formatted_header(node.name))

        output(node.tests, indent=indent + 1)

    elif isinstance(node, TestSuite):
        warnings_str = get_formatted_summary(node)
        if warnings_str:
            print '{:s}+ {:s} - {:s}'.format(get_indent(indent), get_formatted_header(node.name), warnings_str)
        else:
            print '{:s}+ {:s}'.format(get_indent(indent), get_formatted_header(node.name))

        output(node.fixtures.values(), indent=indent + 1)
        output(node.tests, indent=indent + 1)

    else:
        raise TypeError('Node "{:s} has unknown type.'.format(node))


def collapse_nosetest(nodes):
    if len(nodes) == 1 and isinstance(nodes[0], TestSuite) and nodes[0].name == 'nosetests':
        return nodes[0].fixtures.values() + nodes[0].tests
    else:
        return nodes


def collapse_gtest(node):
    if node is None:
        pass
    elif isinstance(node, list):
        for child_node in node:
            collapse_gtest(child_node)
    elif isinstance(node, TestSuite):
        if len(node.fixtures) == 1 and node.fixtures.keys()[0] == node.name:
            fixture = node.fixtures.values()[0]
            node.tests += fixture.tests
            node.fixtures = dict()

    return node


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('input_file', type=str)
    args = parser.parse_args()

    with open(args.input_file, 'rb') as input_file:
        tree = ElementTree.parse(input_file)

    root = tree.getroot()

    root_fixtures = dict()
    root_node = parse(tree.getroot(), root_fixtures)
    root_nodes = root_fixtures.values() + [root_node]

    root_nodes = collapse_nosetest(root_nodes)
    root_nodes = collapse_gtest(root_nodes)

    output(root_nodes)


if __name__ == '__main__':
    main()
