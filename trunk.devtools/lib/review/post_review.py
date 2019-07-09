# Copyright (c) 2014-2016 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

import os
import re
from common import error, run_interactive_command
from os.path import dirname, isfile, join, realpath


class SubmittedReviewError(Exception):
    pass


RBTOOLS_COMPONENT = join(dirname(realpath(__file__)),
                         '../..',
                         '3pp',
                         'rbtools',
                         'RBTools-0.7.5-prebuilt-DO_NOT_EDIT')

SIX_COMPONENT = join(dirname(realpath(__file__)),
                     '../..', '3pp', 'six')

POST_REVIEW = join(RBTOOLS_COMPONENT, 'rbtools', 'commands', 'main.py')

if not isfile(POST_REVIEW):
    error('Unable to find main.py at %s' % POST_REVIEW)

# Print informative error messages early if modules required by RBTools
# aren't available.
try:
    import pkg_resources
    pkg_resources  # Avoid pyflakes warning
except ImportError:
    error("Python module pkg_resources is missing - please install"
          " the package python-setuptools")
try:
    import argparse
    argparse  # Avoid pyflakes warning
except ImportError:
    error("Python module argparse is missing. If you're running CentOS you"
          " could try installing the package python-argparse. If not, you'll"
          " need Python 2.7.x.")


def post_review(post_review_arguments, verbose=False):
    # The -u flag is for unbuffered output. This is needed for displaying
    # available data from stdout of the process up until an input action.
    post_review_command = ["python2", "-u", POST_REVIEW, "post"]

    # Provide some defaults that suit us
    if '--disable-proxy' not in post_review_arguments:
        post_review_arguments.append('--disable-proxy')
    if verbose:
        post_review_arguments.append('--debug')
    post_review_command.extend(post_review_arguments)

    environment = os.environ
    environment['LC_ALL'] = 'POSIX'
    # Setup PYTHONPATH before calling RBTools. If RBTools was properly
    # installed, these directories would be the standard 'site-packages'
    # directory.
    new_python_path = [RBTOOLS_COMPONENT, SIX_COMPONENT]
    if 'PYTHONPATH' in environment:
        new_python_path.append(environment['PYTHONPATH'])
    environment['PYTHONPATH'] = ":".join(new_python_path)

    print
    print "**"
    print "Posting review:"
    if verbose:
        print "  Command: %s" % " ".join(post_review_command)

    print "================="
    exit_status, output = \
        run_interactive_command(post_review_command, environment)
    print "================="

    if exit_status == 0:
        return _parse_review_id(output)
    elif "marked as submitted" in output:
        raise SubmittedReviewError()
    else:
        error("Failed to post review - did you enter the correct username and"
              " password?")


def _parse_review_id(text):
    for line in text.split("\n"):
        match = re.search("https?://.*/(?P<id>\d+)/$", line)
        if match:
            return match.group("id")
    error("Could not read review id from rbtools output.")
