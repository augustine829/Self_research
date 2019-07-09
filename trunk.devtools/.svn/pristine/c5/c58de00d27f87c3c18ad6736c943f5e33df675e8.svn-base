# Copyright (c) 2014-2015 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

from os.path import exists, getmtime
from time import time
from urllib2 import urlopen
import os
import sys
if sys.version_info < (2, 7):
    # In python 2.6 simplejson is ~4x faster than json when parsing
    # SVNUSERS_FILE. In python 2.7 there is no speed difference
    # between the two modules.
    try:
        import simplejson as json
    except ImportError:
        import json
else:
    import json

BUILDUSERS_URL = "http://svn.arrisi.com/builduser_remote.php?action=get_users"
SVNUSERS_FILE = os.path.expanduser("~/.svnusers.json")
CACHE_REFRESH_INTERVAL = 24 * 60 * 60  # Seconds

cached_svnusers = None

def update_cache(force=False):
    if (not force
            and exists(SVNUSERS_FILE)
            and time() - getmtime(SVNUSERS_FILE) < CACHE_REFRESH_INTERVAL):
        return
    users = {}
    raw_data = json.loads(urlopen(BUILDUSERS_URL).read().decode())
    for entry in raw_data:
        users[entry["coreid"]] = entry

    json.dump(users, open(SVNUSERS_FILE, "w"), indent=4,
              sort_keys=True, separators=(',', ': '))


def get_svn_users():
    global cached_svnusers
    if not cached_svnusers:
        update_cache()
        cached_svnusers = json.load(open(SVNUSERS_FILE))
    return cached_svnusers
