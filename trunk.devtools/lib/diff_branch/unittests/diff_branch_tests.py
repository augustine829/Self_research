#!/usr/bin/env python2

import os
import re
import shutil
import tempfile
import unittest

from diff_branch import (get_branch_diff_command,
                         get_highest_merged_revision,
                         pegged_url)
from os.path import basename, join
from subprocess import check_call, check_output


def create_revision(svn_args):
    """Call 'svn' with svn_args and return the new revision printed by svn."""
    svn_command = ['svn'] + svn_args
    svn_stdout = check_output(svn_command)
    committed_revision_match = re.search(
        r'Committed revision (?P<revision>\d+)\.', svn_stdout)
    assert committed_revision_match is not None
    return int(committed_revision_match.group('revision'))


class RepoDependentTests(unittest.TestCase):
    def setUp(self):
        self._cleanup_dirs = []
        self._repo_dir = self._create_temp_dir()
        check_call(['svnadmin', 'create', self._repo_dir])
        self._repo_url = 'file://%s' % self._repo_dir

        # Create trunk
        self._trunk_url = join(self._repo_url, 'trunk')
        self._trunk_created_revision = create_revision(
            ['mkdir', '-m', 'Created trunk.', self._trunk_url])

        # Create a 'foo' branch
        self._branches_url = join(self._repo_url, 'branches')
        create_revision(['mkdir', '-m', 'Created branches dir.',
                         self._branches_url])
        self._foo_url = join(self._branches_url, 'foo')
        self._foo_created_revision = create_revision(
            ['copy', '-m', 'Created foo.',
             pegged_url(self._trunk_url, self._trunk_created_revision),
             self._foo_url])

        # Create deadwood
        self._deadwood_url = join(self._repo_url, 'deadwood')
        create_revision(['mkdir', '-m', 'Created deadwood.',
                         self._deadwood_url])

    def tearDown(self):
        for cleanup_dir in self._cleanup_dirs:
            shutil.rmtree(cleanup_dir)

    def _create_temp_dir(self):
        path = tempfile.mkdtemp()
        self._cleanup_dirs.append(path)
        return path

    def _checkout(self, url):
        wc_dir = self._create_temp_dir()
        check_call(['svn', 'checkout', url, wc_dir])
        return wc_dir

    def _rebase(self, branch_url, ancestor_branch_url):
        wd = os.getcwd()
        branch_wc = self._checkout(branch_url)
        os.chdir(branch_wc)
        try:
            check_call(['svn', 'merge', ancestor_branch_url, '.'])
            revision = create_revision(['commit',
                                        '-m',
                                        'Rebased %s.' % basename(branch_url),
                                        branch_wc])
        finally:
            os.chdir(wd)
        return revision

    def test_simple_branching(self):
        _, _, left, right = get_branch_diff_command(self._foo_url)
        self.assertEqual(left, pegged_url(self._trunk_url,
                                          self._trunk_created_revision))
        self.assertEqual(right, self._foo_url)

    def test_simple_branching_with_pegged_url(self):
        pegged_foo_url = pegged_url(self._foo_url, self._foo_created_revision)
        _, _, left, right = get_branch_diff_command(pegged_foo_url)
        self.assertEqual(left, pegged_url(self._trunk_url,
                                          self._trunk_created_revision))
        self.assertEqual(right, pegged_url(self._foo_url,
                                           self._foo_created_revision))

    def test_rebased_branch(self):
        new_trunk_subdir = join(self._trunk_url, 'fish')
        trunk_modified_revision = create_revision(
            ['mkdir', '-m', 'Created trunk subdir.', new_trunk_subdir])
        self._rebase(self._foo_url, self._trunk_url)
        _, _, left, right = get_branch_diff_command(self._foo_url)
        self.assertEqual(left, pegged_url(self._trunk_url,
                                          trunk_modified_revision))
        self.assertEqual(right, self._foo_url)

    def test_renamed_branch(self):
        new_foo_location = join(self._branches_url, 'bar')
        create_revision(['move', '-m', 'Renamed branch foo to bar.',
                         self._foo_url, new_foo_location])
        _, _, left, right = get_branch_diff_command(new_foo_location)
        self.assertEqual(left, pegged_url(self._trunk_url,
                                          self._trunk_created_revision))
        self.assertEqual(right, new_foo_location)

    def test_renamed_branch_with_pegged_url(self):
        new_foo_location = join(self._branches_url, 'bar')
        bar_created_revision = create_revision(
            ['move', '-m', 'Renamed branch foo to bar.', self._foo_url,
             new_foo_location])
        pegged_new_foo_url = pegged_url(new_foo_location, bar_created_revision)
        _, _, left, right = get_branch_diff_command(pegged_new_foo_url)
        self.assertEqual(left, pegged_url(self._trunk_url,
                                          self._trunk_created_revision))
        self.assertEqual(right, pegged_new_foo_url)

    def test_deadwooded_branch(self):
        deadwooded_foo_url = join(self._deadwood_url, basename(self._foo_url))
        create_revision(['move', '-m', 'Deadwooded foo.',
                         self._foo_url, deadwooded_foo_url])
        _, _, left, right = get_branch_diff_command(deadwooded_foo_url)
        self.assertEqual(left, pegged_url(self._trunk_url,
                                          self._trunk_created_revision))
        self.assertEqual(right, deadwooded_foo_url)

    def test_multiple_moves_and_rebases(self):
        # Modify trunk and rebase
        create_revision(['mkdir', '-m', 'Created trunk subdir1.',
                         join(self._trunk_url, 'subdir1')])
        self._rebase(self._foo_url, self._trunk_url)

        # Rename foo to bar, modify trunk and rebase
        bar_url = join(self._branches_url, 'bar')
        create_revision(['move', '-m', 'Renamed branch foo to bar',
                         self._foo_url, bar_url])
        trunk_last_modified_revision = create_revision(
            ['mkdir', '-m', 'Created trunk subdir2', join(self._trunk_url,
                                                          'sbudir2')])
        self._rebase(bar_url, self._trunk_url)

        # Rename bar to baz
        baz_url = join(self._branches_url, 'baz')
        create_revision(['move', '-m', 'Renamed branch bar to baz',
                         bar_url, baz_url])

        # Deadwood baz
        deadwooded_baz_url = join(self._deadwood_url, 'baz')
        create_revision(['move', '-m', 'Deadwooded baz.',
                         baz_url, deadwooded_baz_url])

        _, _, left, right = get_branch_diff_command(deadwooded_baz_url)
        self.assertEqual(left, pegged_url(self._trunk_url,
                                          trunk_last_modified_revision))
        self.assertEqual(right, deadwooded_baz_url)


class BasicTests(unittest.TestCase):
    def test_highest_merged_revision_single_revision(self):
        svn_mergeinfo_prop = """
/bsg/trunk:1
/bsg/branches/foo:2
/bar:3
"""
        self.assertEqual(get_highest_merged_revision(svn_mergeinfo_prop,
                                                     '/bsg/trunk'), 1)
        self.assertEqual(get_highest_merged_revision(svn_mergeinfo_prop,
                                                     '/bsg/branches/foo'), 2)
        self.assertEqual(get_highest_merged_revision(svn_mergeinfo_prop,
                                                     '/bar'), 3)

    def test_highest_merged_revision_multiple_revisions(self):
        svn_mergeinfo_prop = """
/bsg/trunk:2-11,26,35-39
/bsg/branches/foo:3,14-15,17-21,22
"""
        self.assertEqual(
            get_highest_merged_revision(svn_mergeinfo_prop, '/bsg/trunk'), 39)
        self.assertEqual(get_highest_merged_revision(svn_mergeinfo_prop,
                                                     '/bsg/branches/foo'), 22)


if __name__ == '__main__':
    unittest.main(verbosity=2)
