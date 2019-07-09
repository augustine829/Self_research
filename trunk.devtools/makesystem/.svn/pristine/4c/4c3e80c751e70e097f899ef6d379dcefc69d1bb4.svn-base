# Copyright (c) 2013-2015 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

import os.path
import re


USAGE_URL = ("http://kreatvdocs.arrisi.com/trunk/resources/documentation/"
             "3pplicense_ktvlicense_structure_usage.html")


class ParserError(Exception):
    def __init__(self, message, license_file):
        Exception.__init__(self, message)
        self.license_file = license_file


class LicenseInfo:
    def __init__(self, license_file, config):
        self.license_file = license_file
        self.config = config
        self.attribution = ""
        self.embedded_attributions = dict()
        self.values = dict()

        license_file_type = os.path.basename(license_file)
        if license_file_type.startswith("3PPLICENSE"):
            self.expected_attributes = [
                "NAME", "LICENSE", "FILENAME", "SHA1", "ORIGIN", "USAGE"]
            self.optional_attributes = ["TARGET", "VERSION"]
        elif license_file_type.startswith("KTVLICENSE"):
            self.expected_attributes = ["NAME", "LICENSE"]
            self.optional_attributes = [
                "TARGET", "FILENAME", "SHA1", "VERSION", "ORIGIN", "USAGE"]
        else:
            self._raise_error("invalid license file name: %s"
                              % license_file_type)

        self.valid_as_indexed = [
            "FILENAME", "SHA1", "EMBEDDED_NAME", "EMBEDDED_VERSION",
            "EMBEDDED_LICENSE"]

        for attribute in self.valid_as_indexed:
            self.values[attribute] = dict()

        # LICENSE value 'Unknown' is valid only when USAGE is 'InternalUseOnly'
        self.valid_licenses = sorted([
            "Apachev11", "Apachev2", "MPLv11", "OpenSSL",
            "BSDish", "Custom", "Proprietary", "PublicDomain", "Unknown",
            "GPLv2", "GPLv2+", "LGPLv21", "LGPLv21+", "LGPLv2", "LGPLv2+",
            "GPLv3", "GPLv3+", "LGPLv3", "LGPLv3+", "GPLv2/BSD",
            "GPLv3+ with GCC runtime library exception v3.1"])

        self.valid_usages = [
            "InternalUseOnly", "Restricted", "Unrestricted"]
        self.valid_predefined_origins = ["FromSupplier", "Unknown"]

    def _raise_error(self, message):
        raise ParserError(message, self.license_file)

    def _create_target_set(self, value):
        target_set = set(value.split())
        valid_target_set = self.config.get_valid_targets()
        if target_set.issubset(valid_target_set):
            return target_set
        else:
            self._raise_error("invalid TARGET value: %s"
                              " (expected a subset of '%s')"
                              % (value, " ".join(valid_target_set)))

    def set_value(self, attribute, value):
        if attribute in self.valid_as_indexed:
            self.set_indexed_value(attribute, "", value)
            return
        if attribute in self.values:
            self._raise_error("%s cannot be added a second time" % attribute)
        if attribute not in self.expected_attributes \
                and attribute not in self.optional_attributes:
            self._raise_error("invalid attribute: %s" % attribute)

        if attribute == "LICENSE":
            if value not in self.valid_licenses:
                self._raise_error("invalid LICENSE value: %s"
                                  " (expected value matching '%s')"
                                  % (value, "|".join(self.valid_licenses)))
        elif attribute == "ORIGIN":
            if "://" not in value and \
                    value not in self.valid_predefined_origins:
                self._raise_error("invalid ORIGIN value: %s"
                                  " (expected a URL or value matching '%s')"
                                  % (value,
                                     "|".join(self.valid_predefined_origins)))
        elif attribute == "USAGE":
            if value not in self.valid_usages:
                self._raise_error("invalid USAGE value: %s"
                                  " (expected value matching '%s')"
                                  % (value, "|".join(self.valid_usages)))
        elif attribute == "TARGET":
            value = self._create_target_set(value)

        self.values[attribute] = value

    def set_indexed_value(self, attribute, index, value):
        if attribute not in self.valid_as_indexed:
            self._raise_error("invalid indexed attribute: %s" % attribute)
        if index in self.values[attribute]:
            index_str = ("[%s]" % index) if index != "" else ""
            self._raise_error("%s%s cannot be added a second time"
                              % (attribute, index_str))

        if attribute == "EMBEDDED_LICENSE":
            if value not in self.valid_licenses:
                self._raise_error("invalid EMBEDDED_LICENSE value: %s"
                                  " (expected value matching '%s')"
                                  % (value, "|".join(self.valid_licenses)))

        self.values[attribute][index] = value

    def check_completeness(self):
        for attribute in self.expected_attributes:
            if attribute not in self.values:
                self._raise_error("attribute %s is missing" % attribute)

        # Indexed attributes are initially in self.values as dictionaries.
        # The contents of the dictionary needs to be examined in other to
        # determine if the attribute has been added or not.
        for attribute in self.valid_as_indexed:
            if attribute in self.expected_attributes \
                    and len(self.values[attribute]) == 0:
                self._raise_error("attribute %s is missing" % attribute)
            if "" in self.values[attribute] \
                    and len(self.values[attribute]) > 1:
                self._raise_error("missing index for attribute %s" % attribute)

        for index in self.values["FILENAME"]:
            if index not in self.values["SHA1"]:
                self._raise_error("found FILENAME[%s] but SHA1[%s] is missing"
                                  % (index, index))
        for index in self.values["SHA1"]:
            if index not in self.values["FILENAME"]:
                self._raise_error("found SHA1[%s] but FILENAME[%s] is missing"
                                  % (index, index))

        for index in self.values["EMBEDDED_NAME"]:
            if index not in self.values["EMBEDDED_LICENSE"]:
                self._raise_error("found EMBEDDED_NAME[%s]"
                                  " but EMBEDDED_LICENSE[%s] is missing"
                                  % (index, index))
        for index in self.values["EMBEDDED_VERSION"]:
            if index not in self.values["EMBEDDED_NAME"]:
                self._raise_error("found EMBEDDED_VERSION[%s] but"
                                  " EMBEDDED_NAME[%s] is missing"
                                  % (index, index))
        for index in self.values["EMBEDDED_LICENSE"]:
            if index not in self.values["EMBEDDED_NAME"]:
                self._raise_error("found EMBEDDED_LICENSE[%s] but"
                                  " EMBEDDED_NAME[%s] is missing"
                                  % (index, index))

        if self.values["LICENSE"] == "Unknown" \
                and self.values["USAGE"] != "InternalUseOnly":
            self._raise_error("LICENSE=Unknown is valid only"
                              " when USAGE=InternalUseOnly")

    def get_name(self):
        return self.values.get("NAME", "")

    def get_version(self):
        return self.values.get("VERSION", "")

    def get_file_names(self):
        return self.values["FILENAME"].copy()

    def get_sha1_checksums(self):
        return self.values["SHA1"].copy()

    def get_license(self):
        return self.values.get("LICENSE", None)

    def get_target_set(self):
        return self.values.get("TARGET", None)

    def get_usage(self):
        return self.values.get("USAGE", "")

    def get_origin(self):
        return self.values.get("ORIGIN", None)

    def set_attribution(self, text):
        self.attribution = text

    def get_attribution(self):
        return self.attribution

    def get_embedded_names(self):
        return self.values["EMBEDDED_NAME"].copy()

    def get_embedded_versions(self):
        return self.values["EMBEDDED_VERSION"].copy()

    def get_embedded_licenses(self):
        return self.values["EMBEDDED_LICENSE"].copy()

    def set_embedded_attribution(self, name, text):
        self.embedded_attributions[name] = text

    def get_embedded_attribution(self, name):
        return self.embedded_attributions.get(name)

    def get_embedded_license_info(self):
        return [EmbeddedLicenseInfo(self, index)
                for index in self.values["EMBEDDED_NAME"]]

    def get_license_file(self):
        return self.license_file


class EmbeddedLicenseInfo:
    def __init__(self, parent, index):
        self._parent = parent
        self._index = index

    def get_name(self):
        return self._parent.get_embedded_names()[self._index]

    def get_version(self):
        return self._parent.get_embedded_versions().get(self._index, "")

    def get_license(self):
        return self._parent.get_embedded_licenses()[self._index]

    def get_usage(self):   # Unsupported info for embedded licenses
        return None

    def get_attribution(self):
        return self._parent.get_embedded_attribution(self.get_name())


class LicenseParser:
    def __init__(self, license_file, config):
        self.license_file = license_file

        self.required_attrib_endings = set(["END_ATTRIBUTION"])
        self.section_endings_found = list()
        self.section_lines = list()

        self.info = LicenseInfo(license_file, config)
        self.header_line_regex = re.compile(
            r'^(?P<attribute>[^=\[]+)(\[(?P<index>\d+)\])?=(?P<value>(.+))')

        with open(license_file, "r") as f:
            for line in f:
                self._parse_line(line.strip())

        self._validate_section_endings()

    def _raise_error(self, message):
        raise ParserError(message, self.license_file)

    def _raise_wrong_format_error(self, line):
        self._raise_error("wrong format: '%s'"
                          " (expected ATTR=VALUE or ATTR[NUM]=VALUE)" % line)

    def _parse_line(self, line):
        if line.startswith("END_ATTRIBUTION") \
                and line not in self.required_attrib_endings:
            self._raise_error("invalid attribution ending: %s" % line)

        if line in ["END_HEADER", "END_NOTES"] \
                or line in self.required_attrib_endings:
            if line in self.section_endings_found:
                self._raise_error("cannot contain more than one %s" % line)
            self.section_endings_found.append(line)

            if line == "END_ATTRIBUTION":
                text = "\n".join(self.section_lines).strip()
                self.info.set_attribution(text)
            elif line.startswith("END_ATTRIBUTION_"):
                name = line[16:]
                text = "\n".join(self.section_lines).strip()
                self.info.set_embedded_attribution(name, text)

            self.section_lines = list()
            return

        if self.required_attrib_endings.issubset(
                set(self.section_endings_found)) and line != "":
            self._raise_error("no text shall be placed after the last"
                              " END_ATTRIBUTION or END_ATTRIBUTION_<name>")

        self.section_lines.append(line)

        if "END_HEADER" not in self.section_endings_found:
            self._parse_header_line(line)

    def _parse_header_line(self, line):
        if line == "":
            return

        match = self.header_line_regex.search(line)

        # Additional check not handled by the regex
        if not match or \
                match.group("attribute").strip() != match.group("attribute"):
            self._raise_wrong_format_error(line)

        if match.group("attribute") == "EMBEDDED_NAME":
            self.required_attrib_endings.add("END_ATTRIBUTION_%s"
                                             % match.group("value"))

        if match.group("index") is None:
            self.info.set_value(match.group("attribute"), match.group("value"))
        else:
            self.info.set_indexed_value(match.group("attribute"),
                                        match.group("index"),
                                        match.group("value"))

    def _validate_section_endings(self):
        endings = self.section_endings_found[:]

        if endings[0] != "END_HEADER":
            self._raise_error("END_HEADER is missing or in the wrong place")
        endings = endings[1:]

        if "END_NOTES" in endings:
            if endings[0] != "END_NOTES":
                self._raise_error("END_NOTES is in the wrong place. The notes"
                                  " section should be placed directly after"
                                  " END_HEADER.")
            endings = endings[1:]

        if set(endings) != self.required_attrib_endings:
            self._raise_error(
                "missing section endings: %s"
                % ", ".join(self.required_attrib_endings - set(endings)))

    def get_license_info(self):
        return self.info


class LicenseFinder(list):
    def __init__(self, license_dir):
        os.path.walk(license_dir, LicenseFinder._collect, self)

    def _is_license(self, name):
        return name.startswith("3PPLICENSE") or name.startswith("KTVLICENSE")

    def _collect(self, dirname, names):
        self.extend(os.path.join(dirname, name)
                    for name in names
                    if self._is_license(name))


class LicenseInfoCollection(list):
    def __init__(self, license_dir):
        for license_file in LicenseFinder(license_dir):
            parser = LicenseParser(license_file, OpenSourceNoticeConfig())
            self.append(parser.get_license_info())


class OpenSourceNoticeConfig:
    def __init__(self):
        path1 = os.path.join(os.path.dirname(__file__),
                             "opensourcenotice.config")
        path2 = os.path.join(os.path.dirname(__file__),
                             "../config/opensourcenotice.config")
        path3 = os.path.join(os.path.dirname(__file__),
                             "../dist/config/opensourcenotice.config")

        if os.path.isfile(path1):
            config_file = path1
        elif os.path.isfile(path2):
            config_file = path2
        elif os.path.isfile(path3):
            config_file = path3
        else:
            raise IOError("couldn't find opensourcenotice.config in either"
                          " of these locations: %s, %s, %s"
                          % (path1, path2, path3))

        import ConfigParser
        self.config = ConfigParser.ConfigParser()
        self.config.read(config_file)

    def get_valid_targets(self):
        value = self.config.get("opensourcenotice", "valid_targets")
        return set(value.split())
