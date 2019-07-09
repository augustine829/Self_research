#!/usr/bin/env python2

# Copyright (c) 2014-2015 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

import sys
from os.path import dirname, realpath
sys.path.insert(0, dirname(realpath(__file__)) + '/../../pycommon')

import json
import os
import tempfile
import unittest

from configuration import ReviewConfiguration
from configuration import ReviewConfigurationFile
from configuration import ReviewState
from configuration import ReviewStateFile
from configuration import ReviewFileSet
from common import ExecutionError


class TestReviewConfiguration(unittest.TestCase):
    def test_initial_state(self):
        c = ReviewConfiguration()
        self.assertEqual(str(c), "")
        self.assertEqual(len(tuple(c)), 0)

    def test_add_review(self):
        c = ReviewConfiguration()
        c.add_review("123", "-i hal/*")
        c.add_review(None, "-x hal/*")

        cl = tuple(c)
        self.assertEqual(cl[0].review_id, "123")
        self.assertEqual(cl[0].filter_args, "-i hal/*")
        self.assertTrue(cl[1].review_id is None)
        self.assertEqual(cl[1].filter_args, "-x hal/*")

        self.assertEqual(str(c).split("\n"), ["123 -i hal/*", "new -x hal/*"])
        self.assertEqual(len(cl), 2)

    def test_error_for_adding_review_with_invalid_id(self):
        c = ReviewConfiguration()
        with self.assertRaisesRegexp(ExecutionError, "invalid review_id"):
            c.add_review("invalid", "-i hal/*")

    def test_load(self):
        c = ReviewConfiguration()
        c.load(["123 -i hal/*", "new -x hal/*"])

        cl = tuple(c)
        self.assertEqual(cl[0].review_id, "123")
        self.assertEqual(cl[0].filter_args, "-i hal/*")
        self.assertTrue(cl[1].review_id is None)
        self.assertEqual(cl[1].filter_args, "-x hal/*")

        self.assertEqual(str(c).split("\n"), ["123 -i hal/*", "new -x hal/*"])
        self.assertEqual(len(cl), 2)

    def test_load_with_comments(self):
        c = ReviewConfiguration()
        c.load(["# some comment...", "123 -i hal/*"])
        self.assertEqual(len(tuple(c)), 1)

    def test_load_with_empty_lines(self):
        c = ReviewConfiguration()
        c.load(["", "123 -i hal/*"])
        self.assertEqual(len(tuple(c)), 1)

    def test_load_with_review_spanning_multiple_lines(self):
        c = ReviewConfiguration()
        c.load(["123 -i hal/* \\",
                "  -i platform/* \\",
                "  -i manuals/*",
                "new -x hal/*"])
        cl = tuple(c)
        self.assertEqual(len(cl), 2)
        self.assertEqual(cl[0].review_id, "123")
        self.assertEqual(
            cl[0].filter_args, "-i hal/* -i platform/* -i manuals/*")
        self.assertTrue(cl[1].review_id is None)
        self.assertEqual(cl[1].filter_args, "-x hal/*")

    def test_error_for_loading_invalid_review_row(self):
        c = ReviewConfiguration()
        with self.assertRaisesRegexp(ExecutionError,
                                     "invalid config format: row 1"):
            c.load(["invalid -i hal/*"])
        with self.assertRaisesRegexp(ExecutionError,
                                     "invalid config format: row 4"):
            c.load(["123 -i hal/* \\",
                    "  -i platform/* \\",
                    "  -i manuals/*",
                    "invalid -x hal/*"])

    def test_add_text(self):
        c = ReviewConfiguration()
        c.add_text("\n# Some comment...\n")

        cl = tuple(c)
        self.assertEqual(len(cl), 0)
        self.assertEqual(str(c).split("\n"), ["", "# Some comment...", ""])

    def test_error_for_add_invalid_text(self):
        c = ReviewConfiguration()
        with self.assertRaisesRegexp(ExecutionError, "invalid text"):
            c.add_text("\nLine not prefixed with #...\n")

    def test_uncommitted_option_default_value(self):
        c = ReviewConfiguration()
        self.assertEqual(c.get_option("uncommitted"), "false")

    def test_uncommitted_selected(self):
        c = ReviewConfiguration()
        c.set_option("uncommitted", "true")
        self.assertEqual(c.get_option("uncommitted"), "true")

    def test_load_option_uncommitted(self):
        c = ReviewConfiguration()
        c.load([])
        self.assertEqual(c.get_option("uncommitted"), "false")
        c = ReviewConfiguration()
        c.load(["@uncommitted = false"])
        self.assertEqual(c.get_option("uncommitted"), "false")
        c = ReviewConfiguration()
        c.load(["@uncommitted = true"])
        self.assertEqual(c.get_option("uncommitted"), "true")
        c = ReviewConfiguration()
        c.load(["@uncommitted=true"])
        self.assertEqual(c.get_option("uncommitted"), "true")

    def test_error_for_getting_invalid_option(self):
        c = ReviewConfiguration()
        with self.assertRaisesRegexp(ExecutionError, "invalid config option"):
            c.get_option("does_not_exist")

    def test_error_for_loading_invalid_option(self):
        c = ReviewConfiguration()
        with self.assertRaisesRegexp(ExecutionError, "invalid config option"):
            c.load(["@does_not_exist = true"])

    def test_error_for_invalid_option_value(self):
        c = ReviewConfiguration()
        with self.assertRaisesRegexp(ExecutionError, "invalid option value"):
            c.load(["@uncommitted = 1"])

    def test_error_for_loading_invalid_option_row(self):
        c = ReviewConfiguration()
        with self.assertRaisesRegexp(ExecutionError, "invalid config format"):
            c.load(["@uncommitted"])

    def test_config_rows_appear_in_same_order_as_added(self):
        c = ReviewConfiguration()
        c.add_review("123", "-i hal/*")
        c.add_text("# comment ...")
        c.add_review("456", "-i platform/*")
        self.assertEqual(str(c).split("\n"), ["123 -i hal/*",
                                              "# comment ...",
                                              "456 -i platform/*"])

    def test_config_rows_appear_in_same_order_as_loaded(self):
        c = ReviewConfiguration()
        rows = ["123 -i hal/*", "# comment", "456 -i platform/*"]
        c.load(rows)
        self.assertEqual(str(c).split("\n"), rows)

    def test_config_rows_appear_the_same_for_loaded_multi_line_review(self):
        c = ReviewConfiguration()
        rows = ["123 -i hal/* \\",
                "  -i platform/* \\",
                "  -i manuals/*",
                "new -x hal/*"]
        c.load(rows)
        self.assertEqual(str(c).split("\n"), rows)

    def test_config_rows_can_update_without_change_of_order(self):
        c = ReviewConfiguration()
        c.add_review("123", "-i hal/*")
        c.add_text("# comment ...")

        self.assertEqual(str(c).split("\n"), ["123 -i hal/*", "# comment ..."])

        cl = tuple(c)
        cl[0].review_id = "567"

        self.assertEqual(str(c).split("\n"), ["567 -i hal/*", "# comment ..."])

    def test_deprecated_option_item_is_remove_from_output(self):
        c = ReviewConfiguration()
        c.add_review("123", "-i hal/*")
        c.set_option("uncommitted", "true")

        self.assertEqual(str(c).split("\n"), ["123 -i hal/*"])


class TestReviewConfigurationFile(unittest.TestCase):
    def test_save_and_reload(self):
        config = tempfile.NamedTemporaryFile()

        c1 = ReviewConfigurationFile(config.name)
        c1.add_review("123", "-i hal/*")
        c1.add_review(None, "-x hal/*")
        c1.save()

        c2 = ReviewConfigurationFile(config.name)
        cl = tuple(c2)
        self.assertEqual(cl[0].review_id, "123")
        self.assertEqual(cl[0].filter_args, "-i hal/*")
        self.assertTrue(cl[1].review_id is None)
        self.assertEqual(cl[1].filter_args, "-x hal/*")
        self.assertEqual(len(cl), 2)


class TestReviewState(unittest.TestCase):
    def test_initial_state(self):
        s = ReviewState()
        state = {'version': 2,
                 'diff-checksums': {},
                 'uncommitted': False,
                 'unpushed': False,
                 'parent': None}
        self.assertDictEqual(state, s._state)
        self.assertEqual(json.dumps(state), str(s))

    def test_reset_state(self):
        s = ReviewState()
        s.set_checksum("12345", "abc123")
        s.set_uncommitted(True)

        s.reset()

        self.assertIsNone(s.get_checksum("12345"))
        self.assertFalse(s.get_uncommitted())

    def test_load_state(self):
        s = ReviewState()

        state = {'version': 1,
                 'diff-checksums': {"12345": "abc123", "12346": "abc456"},
                 'uncommitted': True}
        s.load(json.dumps(state))

        self.assertEqual("abc123", s.get_checksum("12345"))
        self.assertEqual("abc456", s.get_checksum("12346"))
        self.assertTrue(s.get_uncommitted())

    def test_set_and_get_checksum(self):
        s = ReviewState()
        self.assertIsNone(s.get_checksum("12345"))
        s.set_checksum("12345", "abc123")
        self.assertEqual("abc123", s.get_checksum("12345"))

    def test_set_and_get_uncommitted(self):
        s = ReviewState()
        self.assertFalse(s.get_uncommitted())
        s.set_uncommitted(True)
        self.assertTrue(s.get_uncommitted())

    def test_error_if_loading_wrong_state_version(self):
        s = ReviewState()
        state = {'version': 100, 'somekey': 'somevalue'}
        with self.assertRaisesRegexp(ExecutionError,
                                     "unsupported state file version"):
            s.load(json.dumps(state))

    def test_error_if_loading_state_with_missing_data(self):
        s = ReviewState()
        state = {'version': 1}
        with self.assertRaisesRegexp(ExecutionError,
                                     "malformed state file"):
            s.load(json.dumps(state))

    def test_error_if_loading_state_with_wrongly_typed_data(self):
        s = ReviewState()
        state = {'version': 1,
                 'diff-checksums': "type dict expected, not str",
                 'uncommitted': True}
        with self.assertRaisesRegexp(ExecutionError,
                                     "malformed state file"):
            s.load(json.dumps(state))


class TestReviewStateFile(unittest.TestCase):
    def test_save_and_reload(self):
        state = tempfile.NamedTemporaryFile()

        s1 = ReviewStateFile(state.name)
        s1.set_checksum("12345", "abc123")
        s1.set_checksum("12346", "abc456")
        s1.save()

        s2 = ReviewStateFile(state.name)
        self.assertEqual("abc123", s2.get_checksum("12345"))
        self.assertEqual("abc456", s2.get_checksum("12346"))


class TestReviewFileSet(unittest.TestCase):
    def setUp(self):
        self._config_file = "config_12345.reviewconfig"
        self._state_file = "config_12345.reviewconfig.state"

    def test_config_and_state_do_not_exist(self):
        self.assertFalse(os.path.isfile(self._config_file))
        self.assertFalse(os.path.isfile(self._state_file))

        s = ReviewFileSet(self._config_file)

        self.assertIsInstance(s.review_config, ReviewConfigurationFile)
        self.assertIsInstance(s.review_state, ReviewStateFile)
        self.assertFalse(os.path.isfile(self._config_file))
        self.assertFalse(os.path.isfile(self._state_file))

    def test_derive_state_filepath(self):
        self.assertEqual("config.state",
                         ReviewFileSet._state_filepath("config"))
        self.assertEqual("my.config.state",
                         ReviewFileSet._state_filepath("my.config"))
        self.assertEqual("my.reviewconfig.state",
                         ReviewFileSet._state_filepath("my.reviewconfig"))

    def test_error_if_state_exist_but_not_config(self):
        open(self._state_file, "w").close()
        self.assertFalse(os.path.isfile(self._config_file))
        self.assertTrue(os.path.isfile(self._state_file))

        with self.assertRaisesRegexp(ExecutionError, "state file found"):
            ReviewFileSet(self._config_file)

    def tearDown(self):
        if os.path.isfile(self._config_file):
            os.remove(self._config_file)
        if os.path.isfile(self._state_file):
            os.remove(self._state_file)


if __name__ == '__main__':
    unittest.main(verbosity=2)
