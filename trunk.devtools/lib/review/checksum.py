# Copyright (c) 2014-2016 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

import hashlib
import re


def from_diff(path):
    # Return a hash which does not depend on the current HEAD revision
    file_diffs = {}
    lines = None
    with open(path, "r") as f:
        for line in f:
            m = re.search(r'^(?P<keep>(\+\+\+|---)[^\t]+).*' +
                          r'\((nonexistent|revision \d+)\)$', line)
            if m:
                new_line = m.group("keep") + "\n"
                if new_line.startswith("---"):
                    lines = []
                    file_diffs[new_line] = lines
                assert lines is not None, "unexpected filtered diff format"
                lines.append(new_line)
            else:
                assert lines is not None, "unexpected filtered diff format"
                lines.append(line)

    md5sum = hashlib.md5()
    for key in sorted(file_diffs.keys()):
        for line in file_diffs[key]:
            md5sum.update(line)
    return md5sum.hexdigest()


def from_git_diff(path):
    md5sum = hashlib.md5()
    with open(path, "r") as fd:
        for line in fd:
            md5sum.update(line)

    return md5sum.hexdigest()
