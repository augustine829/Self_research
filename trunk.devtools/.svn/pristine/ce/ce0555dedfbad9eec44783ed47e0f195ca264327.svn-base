# Copyright (c) 2014-2016 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

import json
import os
import re

from common import error


class ReviewItem(object):
    def __init__(self, review_id, filter_lines):
        self.review_id = review_id
        self._filter_lines = filter_lines

    @property
    def review_id(self):
        return self._review_id

    @review_id.setter
    def review_id(self, id):
        if id == "new":
            id = None
        if id is None or (hasattr(id, "isdigit") and id.isdigit()):
            self._review_id = id
        else:
            error("invalid review_id argument")

    @property
    def filter_args(self):
        return " ".join(line.strip() for line in self._filter_lines)

    def __str__(self):
        return "%s %s" % ("new" if self.review_id is None else self.review_id,
                          "\\\n".join(self._filter_lines))


class OptionItem(object):
    def __init__(self, name):
        self.name = name
        self.value = None

    def __str__(self):
        return "@%s = %s" % (self.name, self.value)


OPTION_UNCOMMITTED = 'uncommitted'


class ReviewConfiguration:
    REVIEW_ROW_RE = r'(?P<review_id>\d+|new) (?P<filter_args>.+)'
    OPTION_ROW_RE = r'@(?P<name>\w+)\s*=\s*(?P<value>.+)'
    VALID_OPTIONS = {OPTION_UNCOMMITTED: {'values': ('true', 'false'),
                                          'default': 'false'}}

    def __init__(self):
        self._lines = []

    def load(self, lines):
        self._lines = []
        enumerated_lines = list(enumerate(lines, 1))
        while len(enumerated_lines) > 0:
            line_nr, line = enumerated_lines.pop(0)
            line = line.strip()
            if line == "" or line.startswith("#"):
                self._lines.append(line)
                continue
            match = re.match(ReviewConfiguration.REVIEW_ROW_RE, line)
            if match:
                self._handle_review_row_match(match, enumerated_lines)
                continue
            match = re.match(ReviewConfiguration.OPTION_ROW_RE, line)
            if match:
                self._handle_option_row_match(match)
                continue
            self._raise_invalid_format(line_nr)

    def _handle_review_row_match(self, match, enumerated_lines):
        review_id, filter_args = match.group('review_id', 'filter_args')

        if not filter_args.endswith("\\"):
            self._add_review_multi_line(review_id, [filter_args])
            return

        filter_lines = []
        filter_lines.append(filter_args[:-1])
        while len(enumerated_lines) > 0:
            _, filter_args = enumerated_lines.pop(0)
            filter_args = filter_args.rstrip()
            if filter_args.endswith("\\"):
                filter_lines.append(filter_args[:-1])
                continue
            else:
                filter_lines.append(filter_args)
                break
        self._add_review_multi_line(review_id, filter_lines)

    def _handle_option_row_match(self, match):
        name, value = match.group('name', 'value')
        self.set_option(name, value)

    def add_review(self, review_id, filter_args):
        self._add_review_multi_line(review_id, [filter_args])

    def _add_review_multi_line(self, review_id, filter_lines):
        config_item = ReviewItem(review_id, filter_lines)
        self._lines.append(config_item)

    def add_text(self, text):
        lines = text.split("\n")
        if not all([line.strip().startswith("#") or line.strip() == ""
                    for line in lines]):
            error("invalid text: lines must be prefixed with"
                  " # (as comment) or empty")
        self._lines.extend(lines)

    def _raise_invalid_format(self, line_nr):
        error("invalid config format: row %d, use format:"
              " (<REVIEWNR>|new) <FILTERARGS>" % line_nr)

    def set_option(self, name, value):
        if name not in ReviewConfiguration.VALID_OPTIONS:
            error("invalid config option: %s" % name)
        if value not in ReviewConfiguration.VALID_OPTIONS[name]['values']:
            error("invalid option value for '%s': %s" % (name, value))
        option_item = self._find_option_in_use(name)
        if option_item is None:
            option_item = OptionItem(name)
            self._lines.append(option_item)
        option_item.value = value

    def get_option(self, name):
        if name not in ReviewConfiguration.VALID_OPTIONS:
            error("invalid config option: %s" % name)
        option_item = self._find_option_in_use(name)
        if option_item is None:
            return ReviewConfiguration.VALID_OPTIONS[name]['default']
        else:
            return option_item.value

    def _find_option_in_use(self, name):
        for option in self._get_items_by_type(OptionItem):
            if option.name == name:
                return option
        return None

    def __str__(self):
        # OptionItem's are deprecated, thus filtered out.
        return "\n".join([str(line) for line in self._lines
                          if not isinstance(line, OptionItem)])

    def __iter__(self):
        return self._get_items_by_type(ReviewItem)

    def __len__(self):
        return len(tuple(self.__iter__()))

    def _get_items_by_type(self, type):
        for item in self._lines:
            if isinstance(item, type):
                yield item


class ReviewConfigurationFile(ReviewConfiguration):
    def __init__(self, filepath):
        ReviewConfiguration.__init__(self)
        self._filepath = filepath

        if os.path.isfile(self._filepath):
            try:
                with open(self._filepath, 'r') as f:
                    self.load(f)
            except IOError as e:
                error("Could not read review config: %s" % e)
        else:
            self.add_text('''\
#
# For information on syntax of this file, run "review --help".
#
''')

    def save(self):
        try:
            with open(self._filepath, 'w') as f:
                f.write(str(self))
                f.write("\n")
        except IOError as e:
            error("Could not write review config: %s" % e)


STATE_DIFF_CHECKSUMS = "diff-checksums"
STATE_UNCOMMITTED = "uncommitted"
STATE_UNPUSHED = "unpushed"
STATE_VERSION = "version"
STATE_BRANCH_PARENT = "parent"


class ReviewState:
    def __init__(self):
        self.reset()

    def load(self, content):
        if content.strip() == "":
            self.reset()
            return

        try:
            state = json.loads(content)
            if state[STATE_VERSION] == 1:
                if type(state[STATE_DIFF_CHECKSUMS]) != dict \
                        or type(state[STATE_UNCOMMITTED]) != bool:
                    error("malformed state file")
            elif state[STATE_VERSION] == 2:
                if type(state[STATE_DIFF_CHECKSUMS]) != dict \
                        or type(state[STATE_UNCOMMITTED]) != bool \
                        or type(state[STATE_UNPUSHED]) != bool:
                    error("malformed state file")

                if type(state[STATE_BRANCH_PARENT]) not in [unicode, str] \
                        and state[STATE_BRANCH_PARENT] is not None:
                    error("malformed state file")
            else:
                error("unsupported state file version, please use a newer"
                      " version of devtools.")

        except (ValueError, KeyError):
            error("malformed state file")

        self._state = state

    def reset(self):
        self._state = {STATE_VERSION: 2,
                       STATE_DIFF_CHECKSUMS: {},
                       STATE_UNCOMMITTED: False,
                       STATE_UNPUSHED: False,
                       STATE_BRANCH_PARENT: None}

    def set_checksum(self, review_id, checksum):
        self._state[STATE_DIFF_CHECKSUMS][review_id] = checksum

    def get_checksum(self, review_id):
        return self._state[STATE_DIFF_CHECKSUMS].get(review_id)

    def set_branch_parent(self, parent):
        assert type(parent) in [unicode, str] or parent is None
        self._state[STATE_BRANCH_PARENT] = parent

    def get_branch_parent(self):
        return self._state[STATE_BRANCH_PARENT]

    def set_uncommitted(self, value):
        assert type(value) == bool
        self._state[STATE_UNCOMMITTED] = value

    def get_uncommitted(self):
        return self._state[STATE_UNCOMMITTED]

    def set_unpushed(self, value):
        assert type(value) == bool
        self._state[STATE_UNPUSHED] = value

    def get_unpushed(self):
        return self._state[STATE_UNPUSHED]

    def __str__(self):
        return json.dumps(self._state)


class ReviewStateFile(ReviewState):
    def __init__(self, filepath):
        ReviewState.__init__(self)
        self._filepath = filepath

        if os.path.isfile(self._filepath):
            try:
                with open(self._filepath, 'r') as f:
                    self.load(f.read())
            except IOError as e:
                error("Could not read review state: %s" % e)

    def save(self):
        try:
            with open(self._filepath, 'w') as f:
                f.write(str(self))
                f.write("\n")
        except IOError as e:
            error("Could not write review state: %s" % e)


class ReviewFileSet(object):
    def __init__(self, config_filepath):
        ReviewFileSet._check_file(config_filepath)

        state_filepath = ReviewFileSet._state_filepath(config_filepath)
        ReviewFileSet._check_file(state_filepath)

        if os.path.isfile(state_filepath) \
                and not os.path.isfile(config_filepath):
            error("state file found for a nonexistent review config: %s"
                  % state_filepath)

        self._config = ReviewConfigurationFile(config_filepath)
        self._state = ReviewStateFile(state_filepath)

    @staticmethod
    def _check_file(path):
        if os.path.isfile(path):
            return
        elif os.path.exists(path):
            error("%s is not a file" % path)

    @staticmethod
    def _state_filepath(config_path):
        return config_path + ".state"

    @property
    def review_config(self):
        return self._config

    @property
    def review_state(self):
        return self._state
