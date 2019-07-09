# Copyright (c) 2014 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

import optparse


def parse_options(usage):
    parser = optparse.OptionParser(usage=usage, prog='review')
    parser.add_option('-b', '--base-url',
                      default=None,
                      help=("URL for the branch that should act as base when"
                            " generating the diff"))
    parser.add_option('-c', '--config',
                      default=None,
                      help="review configuration file")
    parser.add_option('-d', '--diff',
                      default=None,
                      help="use a separately created diff instead")
    parser.add_option('-u', '--branch-url',
                      default=None,
                      help=("URL for the branch where code changes to be"
                            " reviewed are located"))
    parser.add_option('--remotesvn',
                      default=False,
                      action='store_true',
                      help=("force use of remotesvn instead of svn for diff"
                            " generation (autodetected by default)"))
    parser.add_option('--rb-server-url',
                      default=None,
                      help=("use this URL for the Review Board server instead"
                            " of the default one (for testing purposes)"))
    parser.add_option('--rb-username',
                      default=None,
                      help=("username for authenticating to the Review Board"
                            " server, by default the cached session is used"))
    parser.add_option('--rb-password',
                      default=None,
                      help=("password for authenticating to the Review Board"
                            " server, by default the cached session is used"))
    parser.add_option('--svn-username',
                      default=None,
                      help=("username for authenticating to the SVN server,"
                            " by default the current username is used"))
    parser.add_option('--svn-password',
                      default=None,
                      help=("password for authenticating to the SVN server,"
                            " by default cached password is used"))
    parser.add_option('--uncommitted',
                      default=None,  # None is used instead of False. It marks
                                     # the option as unused when compared in
                                     # _execute_with_interaction().
                      action='store_true',
                      help=("generate a diff covering uncommitted changes"
                            " done to the working copy"))
    parser.add_option('--dry-run',
                      default=False,
                      action='store_true',
                      help=("run in dry-run mode, no reviews are created,"
                            " verbose printing is enabled"))
    parser.add_option('-v', '--verbose',
                      default=False,
                      action='store_true',
                      help="print extra process information")
    return parser.parse_args()
