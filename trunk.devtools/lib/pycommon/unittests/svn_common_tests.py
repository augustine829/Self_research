#!/usr/bin/env python2

import unittest

from svn_common import looks_like_branch_url, get_branch_root


class BasicTests(unittest.TestCase):
    def test_looks_like_branch_url(self):
        self.assertTrue(looks_like_branch_url('http://foo/bar/trunk'))
        self.assertTrue(looks_like_branch_url('http://foo/bar/trunk/'))
        self.assertTrue(looks_like_branch_url('http://foo/bar/branches/baz'))
        self.assertTrue(looks_like_branch_url('http://foo/bar/deadwood/baz'))
        self.assertTrue(looks_like_branch_url('http://foo/bar/tags/baz'))

        self.assertFalse(looks_like_branch_url('http://foo/bar'))
        self.assertFalse(looks_like_branch_url('http://foo/bar/'))
        self.assertFalse(looks_like_branch_url('http://foo/bar/trunk/subdir'))

        self.assertFalse(looks_like_branch_url('/foo/bar/trunk'))
        self.assertFalse(looks_like_branch_url('/foo/bar/branches/foo'))

    def test_get_branch_root(self):
        self.assertEqual(get_branch_root(''), None)
        self.assertEqual(get_branch_root('/'), None)
        self.assertEqual(get_branch_root('foo'), None)
        self.assertEqual(get_branch_root('/foo'), None)
        self.assertEqual(get_branch_root('http://foo/bar'), None)
        self.assertEqual(get_branch_root('http://foo/bar/trunk'),
                         'http://foo/bar/trunk')
        self.assertEqual(get_branch_root('http://foo/bar/trunk/subdir'),
                         'http://foo/bar/trunk')
        self.assertEqual(get_branch_root('http://foo/bar/branches/baz/subdir'),
                         'http://foo/bar/branches/baz')
        self.assertEqual(get_branch_root('http://foo/bar/deadwood/baz/subdir'),
                         'http://foo/bar/deadwood/baz')
        self.assertEqual(get_branch_root('http://foo/bar/tags/baz/subdir'),
                         'http://foo/bar/tags/baz')


if __name__ == '__main__':
    unittest.main(verbosity=2)
