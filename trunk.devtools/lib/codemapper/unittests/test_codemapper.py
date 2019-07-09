#!/usr/bin/env python2

import sys

from StringIO import StringIO
from os import chdir, getcwd, makedirs
from os.path import dirname, isdir, join
from shutil import rmtree
from tempfile import mkdtemp
from unittest import TestCase, main

sys.path.insert(0, dirname(__file__) + "/..")
from commandexecutor import arity, CommandExecutor
from common import ExecutionError, UsageError
from main import SVN_BASE_URL
from serverapi import ResourceConflict, ResourceNotFound
from svnapi import SvnApi, SvnWcInfo


def create_empty_file(path):
    if dirname(path) and not isdir(dirname(path)):
        makedirs(dirname(path))
    open(path, "w").close()


class FakeServerApi:
    def __init__(self, groups, mappings):
        self._groups = {x["id"]: x for x in groups}
        self._mappings = {x["id"]: x for x in mappings}
        if mappings:
            self._highest_mapping_id = max(int(x) for x in self._mappings)
        else:
            self._highest_mapping_id = None

    def add_mapping(self, pattern, group_id, triggers_katt2):
        self._highest_mapping_id += 1
        mapping = {
            "id": str(self._highest_mapping_id),
            "group_id": group_id,
            "pattern": pattern,
            "triggers_katt2": triggers_katt2
        }
        self._mappings[mapping["id"]] = mapping
        return mapping

    def delete_group(self, group_id):
        mappings = self.get_mappings_by_group(group_id)
        if mappings:
            raise ResourceConflict
        del self._groups[group_id]

    def get_groups(self):
        return self._groups.values()

    def get_group_by_name(self, group_name):
        matches = [x for x in self._groups.values() if x["name"] == group_name]
        if matches:
            return matches[0]
        else:
            raise ResourceNotFound

    def get_mapping_by_id(self, mapping_id):
        return self._mappings[mapping_id]

    def get_group_by_id(self, group_id):
        return self._groups[group_id]

    def get_mappings(self):
        return self._mappings.values()

    def get_mappings_by_group(self, group_id):
        return [x for x in self._mappings.values()
                if x["group_id"] == group_id]

    def update_mapping(self, mapping):
        self._mappings[mapping["id"]] = mapping


class FakeSvnApi(SvnApi):
    def __init__(self, paths=None):
        SvnApi.__init__(self, SVN_BASE_URL)
        self._path_map = paths

    def get_wc_files_under_path(self, path):
        return self._path_map.get(path, [])

    def get_wc_path_info(self, path):
        if path == "does/not/exist":
            return None
        url = join("http://svn.arrisi.com/dev/project/trunk",
                   path if path != "." else "").rstrip("/")
        return SvnWcInfo(url, "dev", "project", path)

    def path_exists_in_repo(self, url):
        return (
            "*" not in url
            and "ANYBRANCH" not in url
            and not url.startswith(self.get_url("dev", "does/not/exist")))


class FixtureBase(TestCase):
    def setUp(self, groups=None, mappings=None, paths=None):
        if groups is None:
            groups = []
        if mappings is None:
            mappings = []
        self._groups = groups
        self._mappings = mappings
        self._server = FakeServerApi(groups, mappings)
        self._svn = FakeSvnApi(paths)
        self._stdout = StringIO()
        self._command_executor = CommandExecutor(
            self._server, self._svn, self._stdout)
        self._saved_cwd = getcwd()
        self._tmpdir = mkdtemp(suffix="test-codemapper", dir="/tmp")
        chdir(self._tmpdir)

    def tearDown(self):
        chdir(self._saved_cwd)
        rmtree(self._tmpdir)


class TestArityDecorator(TestCase):
    def test_decorator_forwards_arguments(self):
        def func(self_, arg1):
            self.assertEqual(self_, self)
            self.assertEqual(arg1, "foo")
            called[0] = True

        called = [False]
        decorator = arity(1)
        decorator(func)(self, "foo")
        self.assertTrue(called[0])

    def test_only_lower_bound_implies_same_upper_bound(self):
        def func(self_, arg1, arg2, arg3):
            pass
        decorator = arity(3)
        self.assertRaises(UsageError, decorator(func), (self, 1, 2))
        decorator(func)(self, 1, 2, 3)  # Does not raise
        self.assertRaises(UsageError, decorator(func), (self, 1, 2, 3, 4))

    def test_different_upper_and_lower_bounds(self):
        def func(self_, arg1, arg2, arg3):
            pass
        decorator = arity(2, 3)
        self.assertRaises(UsageError, decorator(func), (self, 1))
        decorator(func)(self, 1, 2)  # Does not raise
        decorator(func)(self, 1, 2, 3)  # Does not raise
        self.assertRaises(UsageError, decorator(func), (self, 1, 2, 3, 4))

    def test_missing_arguments_are_set_to_None(self):
        def func(self_, arg1, arg2, arg3):
            self.assertEqual(arg1, 1)
            self.assertTrue(arg2 is None)
            self.assertTrue(arg3 is None)
            called[0] = True

        called = [False]
        decorator = arity(1, 3)
        decorator(func)(self, 1)
        self.assertTrue(called[0])

    def test_usage_error_messages(self):
        def func(self_):
            pass

        with self.assertRaisesRegexp(UsageError,
                                     "subcommand expects 0 arguments"):
            arity(0)(func)(self, 1)

        with self.assertRaisesRegexp(UsageError,
                                     "subcommand expects 1 argument"):
            arity(1)(func)(self, 1, 2)

        with self.assertRaisesRegexp(UsageError,
                                     "subcommand expects 2 arguments"):
            arity(2)(func)(self, 1, 2, 3)

        with self.assertRaisesRegexp(
                UsageError,
                "subcommand expects between 1 and 2 arguments"):
            arity(1, 2)(func)(self, 1, 2, 3)


class FixtureWithDummyData(FixtureBase):
    def setUp(self):
        groups = [
            {"id": "1", "name": "Ignored"},
            {"id": "17", "name": "basil"},
            {"id": "18", "name": "sage"},
        ]
        mappings = [
            {"id": "8", "group_id": "17", "pattern": "dev:monkey",
             "triggers_katt2": "false"},
            {"id": "50", "group_id": "17", "pattern": "stuff:sloth",
             "triggers_katt2": "false"},
            {"id": "471", "group_id": "18", "pattern": "dev:basking shark",
             "triggers_katt2": "false"},
        ]
        FixtureBase.setUp(self, groups, mappings)


class TestCommandExecutor(FixtureWithDummyData):
    def test_list_all_mappings(self):
        self._command_executor.cmd_list()
        expected_stdout = """\
[id: 471] dev:basking shark -> sage
[id:   8] dev:monkey        -> basil
[id:  50] stuff:sloth       -> basil
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)

    def test_list_mappings_for_single_group(self):
        self._command_executor.cmd_list("basil")
        expected_stdout = """\
[id:  8] dev:monkey  -> basil
[id: 50] stuff:sloth -> basil
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)

    def test_list_mappings_for_nonexistent_group(self):
        with self.assertRaises(ExecutionError) as context:
            self._command_executor.cmd_list("parsley")
        self.assertEqual(context.exception.message,
                         "Group parsley does not exist")

    def test_merging_groups(self):
        self._command_executor._merge_groups("basil", "sage")

        # The "basil" group should have been deleted.
        self.assertRaises(ResourceNotFound,
                          self._server.get_group_by_name, "basil")
        sage_group = self._server.get_group_by_name("sage")

        # All mappings should have been transferred to the "sage" group.
        mappings = self._server.get_mappings()
        self.assertEqual(len(mappings), 3)
        self.assertTrue(all(x["group_id"] == sage_group["id"]
                            for x in mappings))

    def test_ignoring_pattern(self):
        self._command_executor.cmd_ignore("dev:foo/*/bar")
        ignored_group = self._server.get_group_by_name("Ignored")
        mappings = self._server.get_mappings_by_group(ignored_group["id"])
        self.assertEqual(len(mappings), 1)
        mapping = mappings[0]
        self.assertEqual(mapping["group_id"], ignored_group["id"])
        self.assertEqual(mapping["pattern"], "dev:foo/*/bar")

    def test_list_single_mapping(self):
        self._command_executor.cmd_info("471")
        expected_stdout = """\
[id: 471] dev:basking shark -> sage
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)


class TestPatternGuessing(FixtureWithDummyData):
    def setUp(self):
        FixtureWithDummyData.setUp(self)
        makedirs("wc/dir0/dir1/dir2")
        chdir("wc/dir0")
        for path in ["file1", "dir1/file2"]:
            create_empty_file(path)

    def _guess(self, pattern):
        return self._command_executor._guess_pattern(pattern, False)

    def test_default_repository_is_added(self):
        self.assertEqual(self._guess("pattern"), "dev:pattern")

    def test_pattern_is_left_as_is_when_not_matching_locally(self):
        self.assertEqual(self._guess("project/*"), "dev:project/*")

    def test_pattern_with_http_url_is_converted_to_standard_form(self):
        self.assertEqual(self._guess("http://svn.arrisi.com/repo/project/*"),
                         "repo:project/*")

    def test_suitable_pattern_is_guessed_when_matching_locally(self):
        self.assertEqual(self._guess("file1"), "dev:project/ANYBRANCH/file1")
        self.assertEqual(self._guess("dir1/file2"),
                         "dev:project/ANYBRANCH/dir1/file2")
        self.assertEqual(self._guess("dir1"), "dev:project/ANYBRANCH/dir1/*")
        self.assertEqual(self._guess("dir1/"), "dev:project/ANYBRANCH/dir1/*")
        self.assertEqual(self._guess("dir1/*"), "dev:project/ANYBRANCH/dir1/*")
        self.assertEqual(self._guess("."), "dev:project/ANYBRANCH/*")
        self.assertEqual(self._guess("*/*"), "dev:project/ANYBRANCH/*")


class TestPatternVerification(FixtureWithDummyData):
    def setUp(self):
        FixtureWithDummyData.setUp(self)
        self._verify = self._command_executor._verify_pattern

    def test_empty_pattern_should_fail(self):
        self.assertRaises(ExecutionError, self._verify, "")

    def test_empty_path_should_fail(self):
        self.assertRaises(ExecutionError, self._verify, "dev:")

    def test_repository_with_slash_should_fail(self):
        self.assertRaises(ExecutionError, self._verify, "re/po:project/*")

    def test_existing_project_should_succeed(self):
        self._verify("dev:project/*")  # Does not raise
        self._verify("http://svn.arrisi.com/dev/project/*")  # Does not raise
        self._verify(
            "http://svn.arrisi.com/dev/project/ANYBRANCH")  # Does not # raise

    def test_nonexisting_project_should_fail(self):
        self.assertRaises(ExecutionError, self._verify, "dev:does/not/exist/*")


class FixtureWithDummyPathData(FixtureBase):
    def setUp(self):
        groups = [
            {"id": "1", "name": "basil"},
            {"id": "2", "name": "sage"},
        ]
        mappings = [
            {"id": "1",
             "group_id": "1",
             "pattern": "dev:project/ANYBRANCH/foo/*",
             "triggers_katt2": "false"},
            {"id": "2",
             "group_id": "2",
             "pattern": "dev:project/ANYBRANCH/foo/bar/*",
             "triggers_katt2": "false"},
            {"id": "3",
             "group_id": "1",
             "pattern": "dev:project/ANYBRANCH/fum/*",
             "triggers_katt2": "false"},
        ]
        self._paths = {
            ".": ["foo/file", "foo/bar/file", "fie/file"],
            "fie": ["fie/file"],
            "foo": ["foo/file", "foo/bar/file"],
            "foo/bar": ["foo/bar/file"],
        }
        FixtureBase.setUp(self, groups, mappings, self._paths)


class TestLocalFileMapping(FixtureWithDummyPathData):
    def test_default_path(self):
        self._command_executor.cmd_map()
        expected_stdout = """\
[id: 1] dev:project/ANYBRANCH/foo/*     -> basil
[id: 2] dev:project/ANYBRANCH/foo/bar/* -> sage
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)

    def test_explicit_path(self):
        self._command_executor.cmd_map(".")
        expected_stdout = """\
[id: 1] dev:project/ANYBRANCH/foo/*     -> basil
[id: 2] dev:project/ANYBRANCH/foo/bar/* -> sage
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)

    def test_subpath(self):
        self._command_executor.cmd_map("foo/bar")
        expected_stdout = """\
[id: 1] dev:project/ANYBRANCH/foo/*     -> basil
[id: 2] dev:project/ANYBRANCH/foo/bar/* -> sage
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)

    def test_subpath_with_trailing_slash(self):
        self._command_executor.cmd_map("foo/bar/")
        expected_stdout = """\
[id: 1] dev:project/ANYBRANCH/foo/*     -> basil
[id: 2] dev:project/ANYBRANCH/foo/bar/* -> sage
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)

    def test_nonexisting_path(self):
        self.assertRaises(ExecutionError,
                          self._command_executor.cmd_map,
                          "does/not/exist")

    def test_nonmatching_path(self):
        self._command_executor.cmd_map("fie")
        expected_stdout = ""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)


class TestPatternTesting(FixtureWithDummyPathData):
    def test_default_path(self):
        self._command_executor.cmd_test("1")
        expected_stdout = """\
foo/bar/file
foo/file
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)

    def test_explicit_path(self):
        self._command_executor.cmd_test("1", ".")
        expected_stdout = """\
foo/bar/file
foo/file
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)

    def test_subpath(self):
        self._command_executor.cmd_test("1", "foo/bar")
        expected_stdout = """\
foo/bar/file
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)

    def test_subpath_with_trailing_slash(self):
        self._command_executor.cmd_test("1", "foo/bar/")
        expected_stdout = """\
foo/bar/file
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)

    def test_nonexisting_path(self):
        self.assertRaises(ExecutionError,
                          self._command_executor.cmd_test,
                          "1", "does/not/exist")

    def test_nonmatching_path(self):
        self._command_executor.cmd_test("1", "fie")
        expected_stdout = ""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)


class TestOrphans(FixtureWithDummyPathData):
    def test_orphans_default_path(self):
        self._command_executor.cmd_find_orphans()
        expected_stdout = """\
fie/file
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)

    def test_orphans_explicit_path(self):
        self._command_executor.cmd_find_orphans(".")
        expected_stdout = """\
fie/file
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)

    def test_no_orphans(self):
        self._paths["."].remove("fie/file")
        self._command_executor.cmd_find_orphans()
        expected_stdout = ""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)


class TestDiffMapping(FixtureBase):
    def _get_patternish_paths_from_diff(self, diff):
        diff_fp = StringIO(diff)
        return self._command_executor._get_patternish_paths_from_diff(diff_fp)

    def test_plain_diff(self):
        diff = """\
Blah blah, description of patch, etc.

--- foo/file1.txt
+++ foo/file2.txt
@@ meta
 context
 context
 context
-removed
+added
 context
--- foo/file3.txt
+++ bar/file4.txt
@@ meta
+added
"""
        patternish_paths = self._get_patternish_paths_from_diff(diff)
        expected_patternish_paths = set([
            "dev:project/trunk/foo/file2.txt",
            "dev:project/trunk/bar/file4.txt",
        ])
        self.assertEqual(patternish_paths, expected_patternish_paths)

    def test_plain_diff_with_unknown_unknown_files(self):
        diff = """\
--- does/not/exist
+++ does/not/exist
"""
        with self.assertRaises(ExecutionError) as context:
            self._get_patternish_paths_from_diff(diff)
        self.assertTrue("does/not/exist" in context.exception.message)

    def test_diff_from_svn_diff_in_wc(self):
        diff = """\
--- foo/file1.txt      (revision 387960)
+++ foo/file2.txt      (working copy)
@@ meta
 context
 context
 context
-removed
+added
 context
--- foo/file3.txt
+++ bar/file4.txt
@@ meta
+added
"""
        patternish_paths = self._get_patternish_paths_from_diff(diff)
        expected_patternish_paths = set([
            "dev:project/trunk/foo/file2.txt",
            "dev:project/trunk/bar/file4.txt",
        ])
        self.assertEqual(patternish_paths, expected_patternish_paths)

    def test_diff_from_svn_diff_with_urls(self):
        diff = """\
--- foo/file1.txt   (.../trunk)     (revision 387179)
+++ foo/file1.txt   (.../branches/DEV_branch) (revision 387990)
"""
        with self.assertRaises(ExecutionError) as context:
            self._get_patternish_paths_from_diff(diff)
        self.assertTrue("--summarize" in context.exception.message)

    def test_diff_from_svn_diff_summarize_with_urls(self):
        diff = """\
A       http://svn.arrisi.com/dev/project/trunk/foo/file1.txt
M       http://svn.arrisi.com/dev/project/trunk/foo/file2.txt
D       http://svn.arrisi.com/dev/project/trunk/foo/file3.txt
"""
        patternish_paths = self._get_patternish_paths_from_diff(diff)
        expected_patternish_paths = set([
            "dev:project/trunk/foo/file1.txt",
            "dev:project/trunk/foo/file2.txt",
            "dev:project/trunk/foo/file3.txt",
        ])
        self.assertEqual(patternish_paths, expected_patternish_paths)

    def test_diff_from_svn_diff_summarize_in_wc(self):
        diff = """\
A       foo/file1.txt
M       foo/file2.txt
D       foo/file3.txt
"""
        patternish_paths = self._get_patternish_paths_from_diff(diff)
        expected_patternish_paths = set([
            "dev:project/trunk/foo/file1.txt",
            "dev:project/trunk/foo/file2.txt",
            "dev:project/trunk/foo/file3.txt",
        ])
        self.assertEqual(patternish_paths, expected_patternish_paths)


class FixtureWithDummyTriggersKatt2Data(FixtureBase):
    def setUp(self):
        groups = [
            {"id": "17", "name": "basil"},
            {"id": "18", "name": "sage"},
        ]
        mappings = [
            {"id": "8", "group_id": "17", "pattern": "dev:monkey",
             "triggers_katt2": "true"},
            {"id": "50", "group_id": "17", "pattern": "stuff:sloth",
             "triggers_katt2": "false"},
            {"id": "471", "group_id": "18", "pattern": "dev:basking shark",
             "triggers_katt2": "true"},
        ]
        FixtureBase.setUp(self, groups, mappings)


class TestTriggersKatt2Printing(FixtureWithDummyTriggersKatt2Data):
    def test_list_all_mappings(self):
        self._command_executor.cmd_list()
        expected_stdout = """\
[id: 471, triggers KATT2] dev:basking shark -> sage
[id:   8, triggers KATT2] dev:monkey        -> basil
[id:  50                ] stuff:sloth       -> basil
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)

    def test_list_single_mapping(self):
        self._command_executor.cmd_info("471")
        expected_stdout = """\
[id: 471, triggers KATT2] dev:basking shark -> sage
"""
        self.assertEqual(self._stdout.getvalue(), expected_stdout)


if __name__ == "__main__":
    main()
