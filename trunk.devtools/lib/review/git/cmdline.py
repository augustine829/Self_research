# Copyright (c) 2014-2016 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

import optparse


def parse_options(usage):
    parser = optparse.OptionParser(usage=usage, prog='review')
    parser.add_option('-c', '--config',
                      default=None,
                      help='review configuration file')
    parser.add_option('-d', '--diff',
                      default=None,
                      help='use a separately created diff instead')
    parser.add_option('-p', '--parent',
                      default=None,
                      help=('parent branch that should act as base when'
                            ' generating the diff'))
    parser.add_option('--pushed',
                      default=False,
                      action='store_true',
                      help=('review changes between origin/<parent_branch> and'
                            ' origin/<branch> (which is default behavior)'
                            ' - use this when you have local commits that you'
                            ' want to ignore'))
    parser.add_option('--rb-server-url',
                      default='review.arrisi.com',
                      help=('use this URL for the Review Board server instead'
                            ' of the default one (for testing purposes)'))
    parser.add_option('--rb-username',
                      default=None,
                      help=('username for authenticating to the Review Board'
                            ' server, by default the cached session is used'))
    parser.add_option('--rb-password',
                      default=None,
                      help=('password for authenticating to the Review Board'
                            ' server, by default the cached session is used'))
    parser.add_option('--dry-run',
                      default=False,
                      action='store_true',
                      help=('run in dry-run mode, no reviews are created,'
                            ' no configuration files will be stored,'
                            ' verbose printing is enabled'))
    parser.add_option('-u', '--unpushed',
                      default=False,
                      action='store_true',
                      help=('review changes between origin/<branch> and'
                            ' <branch>'))
    parser.add_option('-v', '--verbose',
                      default=0,
                      action='count',
                      help=('print extra process information. For more'
                            ' verbose output, supply -vv or -vvv'))

    debug_opts = optparse.OptionGroup(parser,
                                      'Debug Options',
                                      'Warning: use with care.')
    debug_opts.add_option('--keep-temp-files',
                          default=False,
                          action='store_true',
                          help=('do not remove temporary files'))
    debug_opts.add_option('--skip-post-review',
                          default=False,
                          action='store_true',
                          help=('stops the tool from sending the review to '
                                'Review Board.'))
    parser.add_option_group(debug_opts)

    return parser.parse_args()
