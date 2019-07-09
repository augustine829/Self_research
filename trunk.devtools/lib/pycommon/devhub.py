# Copyright (c) 2016 ARRIS Enterprises, LLC. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, LLC.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

import json
import urllib
import urllib2

from common import ExecutionError


API_PARENT_URL = \
    ('https://devhub.arrisi.com/api/devtools/v1/parent_label_name?'
     'repo={repo_name}&label=heads%2F{label_name}')


def get_branch_parent(repo_name, branch_name, verbose=False):
    # Expected responses from API
    #  - "heads/<branch>"
    #  - "tags/<tag>"
    #  - null    <-- if a parent branch does not exist

    url = API_PARENT_URL.format(
        repo_name=urllib.quote_plus(repo_name),
        label_name=urllib.quote_plus(branch_name))

    if verbose:
        print 'Requesting data from url: {0}'.format(url)

    try:
        request = urllib2.Request(url, None)
        response = json.loads(urllib2.urlopen(request).read())
        if verbose:
            print 'HTTP Response (json decoded): {0}'.format(response)

        if response is None:
            return None

        if response.startswith("heads/"):
            return response[6:]
        else:
            return response
    except urllib2.HTTPError as e:
        if e.code == 404:
            raise ExecutionError(
                "Cannot find parent branch for a repository/branch "
                "combination that does not exist on devhub.")
        else:
            raise ExecutionError(
                "Unable to query devhub for information: {0}".format(url))
    except:
        raise ExecutionError('Failed to query parent from {0}.'.format(url))
