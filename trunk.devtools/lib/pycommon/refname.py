# Copyright (c) 2016 ARRIS Enterprises, LLC. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, LLC.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

from gitcommon import rev_parse

REF_TYPE_UNKNOWN = 0
REF_TYPE_TAG = 1
REF_TYPE_ORIGIN = 2
REF_TYPE_HEADS = 3


class RefName():
    def __init__(self, refname):
        self.refname = refname
        self.refname_type = REF_TYPE_UNKNOWN
        self._determine_ref_type()

    def __getattr__(self, name):
        return getattr(self.refname, name)

    def _determine_ref_type(self):
        depth = self.path_depth()

        if depth > 1:
            refname_parts = self.refname.split('/')
            if refname_parts[0] == "refs":
                refname_parts = refname_parts[1:]
            type_str = refname_parts[0]
            if type_str == 'origin':
                self.refname_type = REF_TYPE_ORIGIN
            elif type_str == 'heads':
                self.refname_type = REF_TYPE_HEADS
            elif type_str == 'tags':
                self.refname_type = REF_TYPE_TAG
        elif depth == 1:
            self.refname_type = REF_TYPE_HEADS
        else:
            self.refname_type = REF_TYPE_UNKNOWN

    def __str__(self):
        return str(self.refname)

    def exists(self):
        try:
            if self.refname is None:
                return False
            rev_parse(self.refname)
            return True
        except:
            return False

    def path_depth(self):
        if self.refname is None:
            return 0
        else:
            return len(self.refname.split('/'))
