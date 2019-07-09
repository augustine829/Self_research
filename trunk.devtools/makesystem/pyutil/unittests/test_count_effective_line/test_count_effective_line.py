#!/usr/bin/env python2

import os
import re
import sys
sys.path.append(os.getcwd() + "/../..")
import count_effective_line

expected_effective_lines_re = \
    r"//@ The correct count of effective lines is : (\d+)"

disabled_case_re = r"//@ Disabled"


def is_case_disabled(filename):
    for line in open(filename).readlines():
        match_object = re.match(disabled_case_re, line)
        if match_object:
            return True
    return False


def get_expected_line_count(filename):
    for line in open(filename).readlines():
        count = re.match(expected_effective_lines_re, line)
        if count:
            return int(count.group(count.lastindex))
    return -1


def check_effective_line_count(filename):
    effective_line_count = count_effective_line.count_effective_line(filename)
    expected_effective_line_count = get_expected_line_count(filename)
    disabled = is_case_disabled(filename)
    msg = "effective lines: %4d, expected: %4d" \
          % (effective_line_count, expected_effective_line_count)
    if effective_line_count == expected_effective_line_count:
        print "[  SUCCESS  ] " + msg
    elif disabled:
        print "[  FAILURE DISABLED  ] " + msg
    else:
        print "[  FAILURE ] " + msg
        sys.exit(1)


if len(sys.argv) <= 1:
    print "Usage: %s <filename1> [<filename2> ...]" % sys.argv[0]
    exit

for i in range(1, len(sys.argv)):
    print "\n## Start counting effective lines in file: %s" % sys.argv[i]
    check_effective_line_count(sys.argv[i])
