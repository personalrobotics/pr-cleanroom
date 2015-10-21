#!/usr/bin/env python
from collections import defaultdict
from xml.etree import ElementTree
import argparse


class TestSuite(object):
    def __init__(self, element=None):
        self.element = element
        self.tests = []
        self.fixtures = dict()

    @property
    def name(self):
        return self.element.attrib['name']


class TestFixture(object):
    def __init__(self, name):
        self.name = name
        self.tests = []


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
    def status(self):
        if not self.is_run:
            return 'skipped'
        elif self.is_successful:
            return 'succeeded'
        else:
            return 'failed'

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


def output(node, indent=0):
    if node is None:
        pass

    elif isinstance(node, list):
        for child_node in node:
            output(child_node, indent=indent)

    elif isinstance(node, Test):
        print '{:s}+ Test: {:s} ({:s})'.format(get_indent(indent), node.name, node.status)

    elif isinstance(node, TestFixture):
        print '{:s}+ Fixture: {:s}'.format(get_indent(indent), node.name)
        output(node.tests, indent=indent + 1)

    elif isinstance(node, TestSuite):
        print '{:s}+ Suite: {:s}'.format(get_indent(indent), node.name)
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

    num_tests = int(root.attrib['tests'])
    num_errors = int(root.attrib['errors'])
    num_failures = int(root.attrib['failures'])

    root_fixtures = dict()
    root_node = parse(tree.getroot(), root_fixtures)
    root_nodes = root_fixtures.values() + [root_node]

    root_nodes = collapse_nosetest(root_nodes)
    root_nodes = collapse_gtest(root_nodes)

    output(root_nodes)


if __name__ == '__main__':
    main()
