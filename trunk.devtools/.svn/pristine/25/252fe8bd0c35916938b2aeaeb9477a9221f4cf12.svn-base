# Copyright (c) 2014 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

import copy
import optparse
import sys

from os.path import dirname, realpath

sys.path.insert(0, dirname(realpath(__file__)) + '/../pycommon')

import svn_common

from common import error, ExecutionError
from common import usage_error, UsageError
from common import prompt_user

from commit import SvnPath, get_original_path
from commit import annotate_commit, diff_revision


options = None


def main(usage):
    global options

    parser, options, args = _get_options(usage)

    try:
        if len(args) == 0:
            parser.print_help()
            sys.exit(0)

        if len(args) > 1:
            usage_error("Too many arguments.")

        # validate option --line
        if options.line and not options.line.isdigit():
            usage_error("Invalid line number specified with option \"-l\"")

        # validate option --revision
        if options.revision and not options.revision.isdigit():
            usage_error("Invalid revision specified with option \"-r\"")

        # set svn authentication
        svn_common.SVN_AUTH = svn_common.SvnAuth(options.svn_username,
                                                 options.svn_password)

        # verify input path
        path_or_url = args[0]
        path_info = svn_common.SvnPathInfo(path_or_url, svn_common.SVN_AUTH)
        if options.line and path_info.node_kind != "file":
            usage_error(
                "The --line option requires the path/URL to refer to a file")

        svn_path = SvnPath(path_info.repository_root, path_info.url,
                           path_info.revision)

        # decide if remotesvn shall be used
        svn_common.REMOTESVN_ENABLED = \
            svn_common.should_enable_remotesvn_if_ping_is_slow()

        if options.line:
            _execute_line_trace(svn_path, options.revision,
                                int(options.line))
        else:
            _execute_file_trace(svn_path, options.revision)
    except ExecutionError as ex:
        print >> sys.stderr, "Error: %s" % ex
        sys.exit(1)
    except UsageError as ex:
        print >> sys.stderr, '''\

%s

Run "tracecommit --help" for usage information.''' % ex
        sys.exit(2)
    except KeyboardInterrupt:
        print
        sys.exit(3)


def _get_options(usage):
    parser = optparse.OptionParser(usage=usage)
    parser.add_option('-r', '--revision',
                      default=None,
                      help="revision to check")
    parser.add_option('-l', '--line',
                      default=None,
                      help="line number indicating which line to be traced")
    parser.add_option('-y', '--assume-yes',
                      default=False,
                      action='store_true',
                      help="answer yes to continue tracing")
    parser.add_option('--svn-username',
                      default=None,
                      help=("username for authenticating to the SVN server,"
                            " by default the current username is used"))
    parser.add_option('--svn-password',
                      default=None,
                      help=("password for authenticating to the SVN server,"
                            " by default cached password is used"))
    options, args = parser.parse_args()

    return (parser, options, args)


def _execute_line_trace(svn_path, revision, line_no):

    print "%s@%s (line %d) is" % (
        svn_path.full_url,
        revision if revision else svn_path.revision,
        line_no)
    while True:
        commit, original_svn_path = annotate_commit(svn_path,
                                                    revision,
                                                    line_no)
        svn_path.set_revision(revision)
        if original_svn_path is None:
            error("Cannot find path %s in the revision %s@%s." % (
                  svn_path.file_path, commit.branch_url,
                  commit.revision))
        # Decide the line No. in the annotated revision
        original_line_no, diff_lines = \
            diff_revision(original_svn_path, svn_path, line_no)
        if original_line_no is None:
            # Need user interaction to help decide the line sometimes
            tmp_diffs = {commit.revision: diff_lines}
            _, line_no = _select_revision_and_lineno(svn_path.revision,
                                                     tmp_diffs)
        else:
            line_no = original_line_no
        svn_path = original_svn_path
        print "  from %s (line %d)" % (svn_path, line_no)

        revision = None   # not to use it any more
        lineno_in_merged_revision = None
        diffs = {}
        if commit.is_merged():
            svn_merged_path = commit.get_merged_branch_path()
            svn_merged_path.set_file_path(svn_path.file_path)
            lineno_in_merged_revision, diffs_with_merged_revision = \
                diff_revision(svn_merged_path, svn_path, line_no)
            if lineno_in_merged_revision > 0:
                # Found same line in merged revision
                svn_path = svn_merged_path
                line_no = lineno_in_merged_revision
                print "  from %s (line %d)" % (svn_path, line_no)
                continue
            elif lineno_in_merged_revision is None:
                # cannot decide which is the original line in merged revision
                diffs[svn_merged_path.revision] = diffs_with_merged_revision

        if not commit.is_path_newly_added(svn_path.file_path):
            prev_revision = str(int(svn_path.revision) - 1)
            svn_path_prev = copy.copy(svn_path)
            svn_path_prev.set_revision(prev_revision)
            lineno_in_prev_revision, diffs_with_prev_revision = \
                diff_revision(svn_path_prev, svn_path, line_no)

            if lineno_in_prev_revision == 0:
                # The line is not in previous revision
                if not commit.is_merged() or lineno_in_merged_revision == 0:
                    # The line is not in merged revision either
                    break
            elif lineno_in_prev_revision > 0:
                # Found same line in previous revision
                svn_path = svn_path_prev
                line_no = lineno_in_prev_revision
                print "  from %s (line %d)" % (svn_path, line_no)
                continue
            else:
                # Found different content in previous revision
                diffs[prev_revision] = diffs_with_prev_revision

        if len(diffs) == 0:
            # The current revision is the final result
            break

        # Ask user to select which version/line to continue
        selected_revision, line_no = \
            _select_revision_and_lineno(svn_path.revision, diffs)
        if selected_revision is None:
            # The user wants to stop the loop
            break
        svn_path.set_revision(selected_revision)
        print "  from %s (line %d)" % (svn_path, line_no)
        continue

    print '=' * 58
    print "The revision is:"
    print commit.get_info()


def _select_revision_and_lineno(revision, diffs):
    for diff_rev, diff_content in diffs.items():
        print "=" * 18, " r%s vs. r%s " % (diff_rev, revision), "=" * 18
        print '\n'.join(diff_content)
    print "=" * 58
    if not options.assume_yes:
        answer = prompt_user("Continue [Y/n]", ('y', 'n'),
                             default_answer='y')
        if answer == 'n':
            return None, None
    if len(diffs) > 1:
        selected_revision = prompt_user(
            "Please choose which revision to continue [%s]:" %
            ('/'.join(diffs.keys())), diffs.keys())
    else:
        selected_revision = diffs.keys()[0]
    selected_line = ""
    while not selected_line.isdigit():
        selected_line = prompt_user(
            "Please choose which line in r%s to trace:" % selected_revision)
    return selected_revision, int(selected_line)


def _execute_file_trace(svn_path, revision):
    print "Path was changed (move, copy or add operation) in the following" \
          " commits:"
    path = svn_path
    original_path, rev = get_original_path(path, revision)
    if original_path is None:
        print "  %s@%s" % (path.full_url,
                           revision if revision else path.revision)
        return
    while original_path is not None:
        print "  %s/%s@%s" % (original_path.branch_url, path.file_path, rev)
        if (original_path.file_path != path.file_path
                and not options.assume_yes):
            answer = prompt_user("Continue [Y/n]", ('y', 'n'),
                                 default_answer='y')
            if answer == 'n':
                break
        path = original_path
        original_path, rev = get_original_path(path)
