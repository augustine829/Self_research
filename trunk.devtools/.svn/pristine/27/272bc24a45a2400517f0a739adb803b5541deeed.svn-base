#!/usr/bin/env python2

# Copyright (c) 2014-2016 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

from svn.main import _rewrite_diff_headers

import tempfile
import unittest


class TestMoveBranchNamesToPrefixPaths(unittest.TestCase):
    def test_function(self):
        diff_file = tempfile.NamedTemporaryFile()
        content = """\
line with text
--- path/to/file\t(.../BRANCH_NAME)\t(revision 12345)
+++ path/to/file\t(.../BRANCH_NAME)\t(revision 12345)
contents1
--- path/to/file\t(revision 12345)
+++ path/to/file\t(revision 12345)
contents2
--- path/to/file
+++ path/to/file
contents3
"""
        open(diff_file.name, "w").write(content)

        _rewrite_diff_headers(diff_file.name)

        expected = """\
line with text
--- BRANCH_NAME/path/to/file\t(revision 12345)
+++ BRANCH_NAME/path/to/file\t(working copy)
contents1
--- path/to/file\t(revision 12345)
+++ path/to/file\t(revision 12345)
contents2
--- path/to/file
+++ path/to/file
contents3
"""
        actual = open(diff_file.name).read()
        self.assertEqual(expected, actual)


if __name__ == '__main__':
    unittest.main(verbosity=2)
