#!/usr/bin/env python2

# Copyright (c) 2013-2015 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

import os
import shutil
import tempfile
import unittest
from license_parser import LicenseInfo, ParserError, LicenseParser


class OpenSourceNoticeConfigMock:
    def get_valid_targets(self):
        return set(["kit", "bi:vip28x3", "bi:bcm45"])


class TestSettingNameValue(unittest.TestCase):
    def setUp(self):
        self.info = LicenseInfo("3PPLICENSE", OpenSourceNoticeConfigMock())

    def test_valid_value(self):
        self.info.set_value("NAME", "foobar")
        self.assertEqual("foobar", self.info.get_name())

    def test_no_value(self):
        self.assertEqual("", self.info.get_name())

    def test_setting_second_time_raises_error(self):
        self.info.set_value("NAME", "foobar")
        self.assertRaisesRegexp(
            ParserError, "cannot be added a second time",
            self.info.set_value, "NAME", "bar")

    def test_setting_with_index_raises_error(self):
        self.assertRaisesRegexp(
            ParserError, "invalid indexed attribute",
            self.info.set_indexed_value, "NAME", "1", "foobar")


class TestSettingLicenseValue(unittest.TestCase):
    def setUp(self):
        self.info = LicenseInfo("3PPLICENSE", OpenSourceNoticeConfigMock())

    def test_valid_value(self):
        self.info.set_value("LICENSE", "BSDish")
        self.assertEqual("BSDish", self.info.get_license())

    def test_invalid_value(self):
        self.assertRaisesRegexp(
            ParserError, "invalid LICENSE value",
            self.info.set_value, "LICENSE", "foolicense")

    def test_no_value(self):
        self.assertEqual(None, self.info.get_license())

    def test_setting_second_time_raises_error(self):
        self.info.set_value("LICENSE", "BSDish")
        self.assertRaisesRegexp(
            ParserError, "cannot be added a second time",
            self.info.set_value, "LICENSE", "Custom")

    def test_setting_with_index_raises_error(self):
        self.assertRaisesRegexp(
            ParserError, "invalid indexed attribute",
            self.info.set_indexed_value, "LICENSE", "1", "BSDish")


class TestSettingFileNameValue(unittest.TestCase):
    def setUp(self):
        self.info = LicenseInfo("3PPLICENSE", OpenSourceNoticeConfigMock())

    def test_single_filename(self):
        self.info.set_value("FILENAME", "foo.tgz")
        self.assertEqual({"": "foo.tgz"}, self.info.get_file_names())

    def test_indexed_filenames(self):
        self.info.set_indexed_value("FILENAME", "1", "foo.tgz")
        self.info.set_indexed_value("FILENAME", "2", "bar.tgz")
        self.assertEqual({"1": "foo.tgz", "2": "bar.tgz"},
                         self.info.get_file_names())

    def test_no_value(self):
        self.assertEqual({}, self.info.get_file_names())

    def test_setting_second_time_raises_error(self):
        self.info.set_value("FILENAME", "foo.tgz")
        self.assertRaisesRegexp(
            ParserError, "cannot be added a second time",
            self.info.set_value, "FILENAME", "foo.tgz")

    def test_setting_index_second_time_raises_error(self):
        self.info.set_indexed_value(
            "FILENAME", "1", "http://comp.com/download")
        self.assertRaisesRegexp(
            ParserError, "cannot be added a second time",
            self.info.set_indexed_value,
            "FILENAME", "1", "http://comp.com/download2")


class TestSettingSha1Value(unittest.TestCase):
    def setUp(self):
        self.info = LicenseInfo("3PPLICENSE", OpenSourceNoticeConfigMock())

    def test_single_sha1(self):
        self.info.set_value("SHA1", "ea45fc00.....")
        self.assertEqual({"": "ea45fc00....."}, self.info.get_sha1_checksums())

    def test_indexed_sha1s(self):
        self.info.set_indexed_value("SHA1", "1", "ea45fc00.....")
        self.info.set_indexed_value("SHA1", "2", "ea45fc00.....")
        self.assertEqual({"1": "ea45fc00.....", "2": "ea45fc00....."},
                         self.info.get_sha1_checksums())

    def test_no_value(self):
        self.assertEqual({}, self.info.get_sha1_checksums())

    def test_setting_second_time_raises_error(self):
        self.info.set_value("SHA1", "ea45fc00.....")
        self.assertRaisesRegexp(
            ParserError, "cannot be added a second time",
            self.info.set_value, "SHA1", "ea45fc00.....")

    def test_setting_index_second_time_raises_error(self):
        self.info.set_indexed_value("SHA1", "1", "ea45fc00.....")
        self.assertRaisesRegexp(
            ParserError, "cannot be added a second time",
            self.info.set_indexed_value, "SHA1", "1", "ea45fc00.....")


class TestSettingOriginValue(unittest.TestCase):
    def setUp(self):
        self.info = LicenseInfo("3PPLICENSE", OpenSourceNoticeConfigMock())

    def test_valid_non_url_value(self):
        self.info.set_value("ORIGIN", "FromSupplier")
        self.assertEqual("FromSupplier", self.info.get_origin())

    def test_valid_url_value(self):
        self.info.set_value("ORIGIN", "http://comp.com/download")
        self.assertEqual("http://comp.com/download", self.info.get_origin())

    def test_invalid_value(self):
        self.assertRaisesRegexp(
            ParserError, "invalid ORIGIN value",
            self.info.set_value, "ORIGIN", "origin-invalid")

    def test_no_value(self):
        self.assertEqual(None, self.info.get_origin())

    def test_setting_second_time_raises_error(self):
        self.info.set_value("ORIGIN", "http://comp.com/download")
        self.assertRaisesRegexp(
            ParserError, "cannot be added a second time",
            self.info.set_value, "ORIGIN", "http://comp.com/download2")

    def test_setting_with_index_raises_error(self):
        self.assertRaisesRegexp(
            ParserError, "invalid indexed attribute",
            self.info.set_indexed_value, "ORIGIN", "1", "FromSupplier")


class TestSettingUsageValue(unittest.TestCase):
    def setUp(self):
        self.info = LicenseInfo("3PPLICENSE", OpenSourceNoticeConfigMock())

    def test_valid_value(self):
        self.info.set_value("USAGE", "InternalUseOnly")
        self.assertEqual("InternalUseOnly", self.info.get_usage())

    def test_invalid_value(self):
        self.assertRaisesRegexp(
            ParserError, "invalid USAGE value",
            self.info.set_value, "USAGE", "usage-foobar")

    def test_no_value(self):
        self.assertEqual("", self.info.get_usage())

    def test_setting_second_time_raises_error(self):
        self.info.set_value("USAGE", "Restricted")
        self.assertRaisesRegexp(
            ParserError, "cannot be added a second time",
            self.info.set_value, "USAGE", "InternalUseOnly")

    def test_setting_with_index_raises_error(self):
        self.assertRaisesRegexp(
            ParserError, "invalid indexed attribute",
            self.info.set_indexed_value, "USAGE", "1", "InternalUseOnly")


class TestSettingTargetValue(unittest.TestCase):
    def setUp(self):
        self.info = LicenseInfo("3PPLICENSE", OpenSourceNoticeConfigMock())

    def test_valid_value_with_single_target(self):
        self.info.set_value("TARGET", "kit")
        self.assertEqual(set(["kit"]), self.info.get_target_set())

    def test_valid_value_with_multiple_targets(self):
        self.info.set_value("TARGET", "kit bi:bcm45")
        self.assertEqual(set(["kit", "bi:bcm45"]), self.info.get_target_set())

    def test_no_value(self):
        self.assertEqual(None, self.info.get_target_set())

    def test_invalid_value_raises_error(self):
        self.assertRaisesRegexp(
            ParserError, "invalid TARGET value",
            self.info.set_value, "TARGET", "kit2")

    def test_setting_second_time_raises_error(self):
        self.info.set_value("TARGET", "kit")
        self.assertRaisesRegexp(
            ParserError, "cannot be added a second time",
            self.info.set_value, "TARGET", "kit")

    def test_setting_with_index_raises_error(self):
        self.assertRaisesRegexp(
            ParserError, "invalid indexed attribute",
            self.info.set_indexed_value, "TARGET", "1", "kit")


class TestSettingVersionValue(unittest.TestCase):
    def setUp(self):
        self.info = LicenseInfo("3PPLICENSE", OpenSourceNoticeConfigMock())

    def test_valid_value(self):
        self.info.set_value("VERSION", "1.2")
        self.assertEqual("1.2", self.info.get_version())

    def test_no_value(self):
        self.assertEqual("", self.info.get_version())

    def test_setting_second_time_raises_error(self):
        self.info.set_value("VERSION", "1.2")
        self.assertRaisesRegexp(
            ParserError, "cannot be added a second time",
            self.info.set_value, "VERSION", "1.3")

    def test_setting_with_index_raises_error(self):
        self.assertRaisesRegexp(
            ParserError, "invalid indexed attribute",
            self.info.set_indexed_value, "VERSION", "1", "1.2")


class TestSettingEmbeddedNameValue(unittest.TestCase):
    def setUp(self):
        self.info = LicenseInfo("3PPLICENSE", OpenSourceNoticeConfigMock())

    def test_valid_value(self):
        self.info.set_value("EMBEDDED_NAME", "foobar")
        self.assertIn("foobar", self.info.get_embedded_names().values())

    def test_no_value(self):
        self.assertEqual([], self.info.get_embedded_names().values())

    def test_setting_index_second_time_raises_error(self):
        self.info.set_indexed_value("EMBEDDED_NAME", "1", "foobar")
        self.assertRaisesRegexp(
            ParserError, "cannot be added a second time",
            self.info.set_indexed_value, "EMBEDDED_NAME", "1", "foobar")


class TestSettingEmbeddedLicenseValue(unittest.TestCase):
    def setUp(self):
        self.info = LicenseInfo("3PPLICENSE", OpenSourceNoticeConfigMock())

    def test_valid_value(self):
        self.info.set_value("EMBEDDED_LICENSE", "BSDish")
        self.assertIn("BSDish", self.info.get_embedded_licenses().values())

    def test_invalid_value(self):
        self.assertRaisesRegexp(
            ParserError, "invalid EMBEDDED_LICENSE value",
            self.info.set_value, "EMBEDDED_LICENSE", "foolicense")

    def test_no_value(self):
        self.assertEqual([], self.info.get_embedded_licenses().values())

    def test_setting_index_second_time_raises_error(self):
        self.info.set_indexed_value("EMBEDDED_LICENSE", "1", "Custom")
        self.assertRaisesRegexp(
            ParserError, "cannot be added a second time",
            self.info.set_indexed_value, "EMBEDDED_LICENSE", "1", "Custom")


class TestAttributeValidity(unittest.TestCase):
    def setUp(self):
        self.info = LicenseInfo("3PPLICENSE", OpenSourceNoticeConfigMock())

    def test_setting_invalid_attribute(self):
        self.assertRaisesRegexp(
            ParserError, "invalid attribute",
            self.info.set_value, "FOO", "123")


class TestLicenseFileNameValidity(unittest.TestCase):
    def test_invalid_license_file_name_raises_error(self):
        file_name_tests = {"3PPLICENSE": False,
                           "3PPLICENSE.foo": False,
                           "KTVLICENSE": False,
                           "KTVLICENSE.foo": False,
                           "OTHERNAME": True}
        for name in file_name_tests:
            try:
                LicenseInfo(name, OpenSourceNoticeConfigMock())
                self.assertFalse(file_name_tests[name])
            except ParserError as ex:
                self.assertRegexpMatches(
                    ex.__str__(), "invalid license file name")
                self.assertTrue(file_name_tests[name])


class TestParse3pplicenseFile(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.temp_dir)

    def create_file(self, basename, content):
        path = os.path.join(self.temp_dir, basename)
        with open(path, "w") as f:
            f.write(content)
        return path

    def test_parsing_valid_file(self):
        content = """\
NAME=foobar
LICENSE=GPLv2
FILENAME=foobar.tgz
SHA1=eacf34ef....
ORIGIN=http://foobar.com
USAGE=Unrestricted
END_HEADER
notes text
notes text
END_NOTES
attribution text
attribution text
END_ATTRIBUTION
"""
        file_path = self.create_file("3PPLICENSE", content)

        parser = LicenseParser(file_path, OpenSourceNoticeConfigMock())

        info = parser.get_license_info()
        info.check_completeness()

        self.assertEqual("foobar", info.get_name())
        self.assertEqual("GPLv2", info.get_license())
        self.assertEqual({"": "foobar.tgz"}, info.get_file_names())
        self.assertEqual({"": "eacf34ef...."}, info.get_sha1_checksums())
        self.assertEqual("http://foobar.com", info.get_origin())
        self.assertEqual("Unrestricted", info.get_usage())
        self.assertEqual("attribution text\nattribution text",
                         info.get_attribution())

        os.remove(file_path)

    def test_parsing_with_missing_attribute_raises_error(self):
        content = """\
NAME=foobar
END_HEADER
END_ATTRIBUTION
"""
        file_path = self.create_file("KTVLICENSE", content)

        parser = LicenseParser(file_path, OpenSourceNoticeConfigMock())
        info = parser.get_license_info()

        self.assertRaisesRegexp(
            ParserError, "attribute .* is missing",
            info.check_completeness)

        os.remove(file_path)

    def test_parsing_with_missing_index_raises_error(self):
        content = """\
NAME=foobar
LICENSE=GPLv2
FILENAME[0]=foobar.tgz
FILENAME=foobar2.tgz
SHA1[0]=eacf34ef....
SHA1=eacf456f....
ORIGIN=http://foobar.com
USAGE=Unrestricted
END_HEADER
END_ATTRIBUTION
"""
        file_path = self.create_file("3PPLICENSE", content)

        parser = LicenseParser(file_path, OpenSourceNoticeConfigMock())
        info = parser.get_license_info()

        self.assertRaisesRegexp(
            ParserError, "missing index for attribute FILENAME",
            info.check_completeness)

        os.remove(file_path)

    def test_filename_index_not_paired_with_sha1_index_raises_error(self):
        content = """\
NAME=foobar
LICENSE=GPLv2
FILENAME[0]=foobar.tgz
SHA1[1]=eacf34ef....
ORIGIN=http://foobar.com
USAGE=Unrestricted
END_HEADER
END_ATTRIBUTION
"""
        file_path = self.create_file("3PPLICENSE", content)

        parser = LicenseParser(file_path, OpenSourceNoticeConfigMock())
        info = parser.get_license_info()

        self.assertRaisesRegexp(
            ParserError, "found FILENAME\[0\] but SHA1\[0\] is missing",
            info.check_completeness)

        os.remove(file_path)

    def test_sha1_index_not_paired_with_filename_index_raises_error(self):
        content = """\
NAME=foobar
LICENSE=GPLv2
FILENAME[0]=foobar.tgz
SHA1[0]=eacf34ef....
SHA1[1]=eacf34ef....
ORIGIN=http://foobar.com
USAGE=Unrestricted
END_HEADER
END_ATTRIBUTION
"""
        file_path = self.create_file("3PPLICENSE", content)

        parser = LicenseParser(file_path, OpenSourceNoticeConfigMock())
        info = parser.get_license_info()

        self.assertRaisesRegexp(
            ParserError, "found SHA1\[1\] but FILENAME\[1\] is missing",
            info.check_completeness)

        os.remove(file_path)

    def test_missing_end_header_raises_error(self):
        content = """\
NAME=foobar
LICENSE=GPLv2
END_ATTRIBUTION
"""
        file_path = self.create_file("KTVLICENSE", content)

        self.assertRaisesRegexp(
            ParserError, "END_HEADER is missing",
            LicenseParser, file_path, OpenSourceNoticeConfigMock())

        os.remove(file_path)

    def test_text_after_end_attribution_raises_error(self):
        content = """\
NAME=foobar
LICENSE=GPLv2
END_HEADER
END_ATTRIBUTION
text after attribution
"""
        file_path = self.create_file("KTVLICENSE", content)

        self.assertRaisesRegexp(
            ParserError, "no text shall be placed after.*END_ATTRIBUTION",
            LicenseParser, file_path, OpenSourceNoticeConfigMock())

        os.remove(file_path)

    def test_adding_end_header_second_time_raises_error(self):
        content = """\
NAME=foobar
LICENSE=GPLv2
END_HEADER
END_HEADER
END_ATTRIBUTION
"""
        file_path = self.create_file("KTVLICENSE", content)

        self.assertRaisesRegexp(
            ParserError, "cannot contain more than one END_HEADER",
            LicenseParser, file_path, OpenSourceNoticeConfigMock())

        os.remove(file_path)

    def test_adding_end_attribution_second_time_raises_error(self):
        content = """\
NAME=foobar
LICENSE=GPLv2
END_HEADER
END_ATTRIBUTION
END_ATTRIBUTION
"""
        file_path = self.create_file("KTVLICENSE", content)

        self.assertRaisesRegexp(
            ParserError, "cannot contain more than one END_ATTRIBUTION",
            LicenseParser, file_path, OpenSourceNoticeConfigMock())

        os.remove(file_path)

    def test_wrong_header_line_format_raises_error(self):
        content = """\
NAME =foobar
LICENSE=GPLv2
END_HEADER
END_ATTRIBUTION
"""
        file_path = self.create_file("KTVLICENSE", content)

        self.assertRaisesRegexp(
            ParserError, "wrong format: 'NAME =foobar'",
            LicenseParser, file_path, OpenSourceNoticeConfigMock())

        os.remove(file_path)


class TestParsingWithEmbeddedLicenses(TestParse3pplicenseFile):
    REQUIRED_SET = """\
NAME=foobar
LICENSE=Proprietary
FILENAME=foobar.tgz
SHA1=eacf34ef....
ORIGIN=http://foobar.com
USAGE=Unrestricted\
"""

    def test_parsing_valid_file_with_embedded_attribution(self):
        content = """\
%s
EMBEDDED_NAME[0]=giraffe
EMBEDDED_VERSION[0]=1.0.1
EMBEDDED_LICENSE[0]=GPLv2
EMBEDDED_NAME[1]=lion
EMBEDDED_LICENSE[1]=Custom
END_HEADER
foobar attribution text
END_ATTRIBUTION
giraffe attribution text
END_ATTRIBUTION_giraffe
lion attribution text
END_ATTRIBUTION_lion
""" % self.REQUIRED_SET

        file_path = self.create_file("3PPLICENSE", content)

        parser = LicenseParser(file_path, OpenSourceNoticeConfigMock())

        info = parser.get_license_info()
        info.check_completeness()

        self.assertDictEqual({"0": "giraffe", "1": "lion"},
                             info.get_embedded_names())
        self.assertDictEqual({"0": "1.0.1"},
                             info.get_embedded_versions())
        self.assertDictEqual({"0": "GPLv2", "1": "Custom"},
                             info.get_embedded_licenses())

        self.assertEqual("foobar attribution text",
                         info.get_attribution())
        self.assertEqual("giraffe attribution text",
                         info.get_embedded_attribution("giraffe"))
        self.assertEqual("lion attribution text",
                         info.get_embedded_attribution("lion"))

        embedded_info = info.get_embedded_license_info()
        order = (0, 1) if embedded_info[0].get_name() == "giraffe" else (1, 0)
        self.assertEqual("giraffe", embedded_info[order[0]].get_name())
        self.assertEqual("1.0.1", embedded_info[order[0]].get_version())
        self.assertEqual("GPLv2", embedded_info[order[0]].get_license())
        self.assertEqual("giraffe attribution text",
                         embedded_info[order[0]].get_attribution())
        self.assertEqual("lion", embedded_info[order[1]].get_name())
        self.assertEqual("", embedded_info[order[1]].get_version())
        self.assertEqual("Custom", embedded_info[order[1]].get_license())
        self.assertEqual("lion attribution text",
                         embedded_info[order[1]].get_attribution())

        os.remove(file_path)

    def test_empty_license_info(self):
        content = """\
%s
END_HEADER
END_ATTRIBUTION
""" % self.REQUIRED_SET

        file_path = self.create_file("3PPLICENSE", content)

        parser = LicenseParser(file_path, OpenSourceNoticeConfigMock())
        info = parser.get_license_info()
        self.assertListEqual([], info.get_embedded_license_info())

        os.remove(file_path)

    def test_invalid_attribution_ending_raises_error(self):
        content = """\
%s
END_HEADER
END_ATTRIBUTION_foobar
END_ATTRIBUTION
""" % self.REQUIRED_SET

        file_path = self.create_file("3PPLICENSE", content)

        self.assertRaisesRegexp(
            ParserError, "invalid attribution ending: END_ATTRIBUTION_foobar",
            LicenseParser, file_path, OpenSourceNoticeConfigMock())

        os.remove(file_path)

    def test_name_index_not_paired_with_license_index_raises_error(self):
        content = """\
%s
EMBEDDED_NAME[0]=giraffe
END_HEADER
END_ATTRIBUTION_giraffe
END_ATTRIBUTION
""" % self.REQUIRED_SET

        file_path = self.create_file("3PPLICENSE", content)

        parser = LicenseParser(file_path, OpenSourceNoticeConfigMock())
        info = parser.get_license_info()

        self.assertRaisesRegexp(
            ParserError,
            "found EMBEDDED_NAME\[0\] but EMBEDDED_LICENSE\[0\] is missing",
            info.check_completeness)

        os.remove(file_path)

    def test_version_index_not_paired_with_name_index_raises_error(self):
        content = """\
%s
EMBEDDED_VERSION[0]=Custom
END_HEADER
END_ATTRIBUTION
""" % self.REQUIRED_SET

        file_path = self.create_file("3PPLICENSE", content)

        parser = LicenseParser(file_path, OpenSourceNoticeConfigMock())
        info = parser.get_license_info()

        self.assertRaisesRegexp(
            ParserError,
            "found EMBEDDED_VERSION\[0\] but EMBEDDED_NAME\[0\] is missing",
            info.check_completeness)

        os.remove(file_path)

    def test_license_index_not_paired_with_name_index_raises_error(self):
        content = """\
%s
EMBEDDED_LICENSE[0]=Custom
END_HEADER
END_ATTRIBUTION
""" % self.REQUIRED_SET

        file_path = self.create_file("3PPLICENSE", content)

        parser = LicenseParser(file_path, OpenSourceNoticeConfigMock())
        info = parser.get_license_info()

        self.assertRaisesRegexp(
            ParserError,
            "found EMBEDDED_LICENSE\[0\] but EMBEDDED_NAME\[0\] is missing",
            info.check_completeness)

        os.remove(file_path)

    def test_notes_section_in_wrong_place_raises_error(self):
        content = """\
%s
EMBEDDED_NAME[0]=giraffe
EMBEDDED_LICENSE[0]=Custom
END_HEADER
END_ATTRIBUTION
Notes...
END_NOTES
END_ATTRIBUTION_giraffe
""" % self.REQUIRED_SET

        file_path = self.create_file("3PPLICENSE", content)

        self.assertRaisesRegexp(
            ParserError, "END_NOTES is in the wrong place",
            LicenseParser, file_path, OpenSourceNoticeConfigMock())

        os.remove(file_path)

    def test_missing_attribution_ending_raises_error(self):
        content = """\
%s
EMBEDDED_NAME[0]=giraffe
EMBEDDED_LICENSE[0]=Custom
END_HEADER
END_ATTRIBUTION
""" % self.REQUIRED_SET

        file_path = self.create_file("3PPLICENSE", content)

        self.assertRaisesRegexp(
            ParserError, "missing section endings: END_ATTRIBUTION_giraffe",
            LicenseParser, file_path, OpenSourceNoticeConfigMock())

        os.remove(file_path)


if __name__ == "__main__":
    unittest.main()
