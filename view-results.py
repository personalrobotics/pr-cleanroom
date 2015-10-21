#!/usr/bin/env python
from collections import defaultdict
from xml.etree import ElementTree
import argparse


class TestSuite(object):
    def __init__(self, name, element=None):
        self.name = name
        self.element = element
        self.tests = []
        self.fixtures = dict()


class TestFixture(object):
    def __init__(self, name):
        self.name = name
        self.tests = []


class Test(object):
    def __init__(self, name, element):
        self.name = name
        self.element = element


def parse(element, fixture_map):
    if element.tag == 'testcase':
        test = Test(element.attrib['name'], element)

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
        suite = TestSuite(element.attrib['name'], element)

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
        print '{:s}+ Test: {:s}'.format(get_indent(indent), node.name)

    elif isinstance(node, TestFixture):
        print '{:s}+ Fixture: {:s}'.format(get_indent(indent), node.name)
        output(node.tests, indent=indent + 1)

    elif isinstance(node, TestSuite):
        print '{:s}+ Suite: {:s}'.format(get_indent(indent), node.name)
        output(node.fixtures.values(), indent=indent + 1)
        output(node.tests, indent=indent + 1)

    else:
        raise TypeError('Node "{:s} has unknown type.'.format(node))

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

    output(root_fixtures.values() + [root_node])


if __name__ == '__main__':
    main()
