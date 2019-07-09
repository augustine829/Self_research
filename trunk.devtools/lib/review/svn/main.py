# Copyright (c) 2014-2016 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

import os
import re
import shlex
import subprocess
import sys
import tempfile

from os.path import dirname, realpath, relpath, isfile, commonprefix, isdir
from os.path import normpath

sys.path.insert(0, dirname(realpath(__file__)) + '/../../pycommon')
sys.path.insert(0, dirname(realpath(__file__)) + '/../../diff_branch')
sys.path.insert(0, dirname(realpath(__file__)) + '/..')

import diff_branch
import svn_common
from common import error, ExecutionError
from common import usage_error, UsageError
from common import prompt_user
from common import run_command
from common import get_working_copy_root_path

import checksum
import cmdline
from configuration import ReviewFileSet, OPTION_UNCOMMITTED
from post_review import post_review, SubmittedReviewError


options = None
args = None
cleanup_files = []
delete_temp_files = True


def main(usage):
    global options
    global args

    os.environ["LANG"] = "en_US"

    try:
        options, args = cmdline.parse_options(usage)
        url = "." if options.branch_url is None else options.branch_url
        diff_branch.verify_branch_argument(url)

        if options.dry_run:
            options.verbose = True

        if not _exists_on_path("filterdiff"):
            error("filterdiff not found in PATH. Please install patchutils:"
                  " su -c 'yum install patchutils'.")

        _execute()

    except ExecutionError as ex:
        print >> sys.stderr, "Error: %s" % ex
        sys.exit(1)
    except UsageError as ex:
        print >> sys.stderr, '''\
%s

Run "review --help" for usage information about program options and review \
configuration file syntax.''' % ex
        sys.exit(2)
    except KeyboardInterrupt:
        print
        sys.exit(3)
    finally:
        if delete_temp_files:
            for name in cleanup_files:
                os.unlink(name)


def _verbose(message):
    if options.verbose:
        print message


def _get_svn_auth():
    return svn_common.SvnAuth(options.svn_username, options.svn_password)


def _exists_on_path(bin_name):
    for path in os.environ["PATH"].split(":"):
        if os.path.exists(path + "/" + bin_name):
            return True
    return False


def _execute():
    if not options.remotesvn:
        options.remotesvn = \
            svn_common.should_enable_remotesvn_if_ping_is_slow()

    if len(args) > 0:
        if len(args) != 1:
            error("New and update cannot be combined.")
        elif "new" not in args and options.uncommitted:
            error("Option uncommitted is valid to use only in"
                  " combination with 'new'.")

    if "new" in args:
        _execute_new()
    elif "update" in args:
        _execute_update()
    else:
        _execute_with_interaction()


def _execute_new():
    config_path = _get_config_path()
    if isfile(config_path):
        if options.config is None:
            usage_error('''\
Found an existing review configuration at %(config_path)s.

Do you want to create a new review using this configuration?
If so, run "review new -c %(config_path)s".

Or did you want to update an existing review using this configuration?
If so, run "review update" instead.\
''' % {"config_path": config_path})
        else:
            review_file_set = ReviewFileSet(config_path)
            if any([review.review_id is not None
                    for review in review_file_set.review_config]):
                usage_error('''\
Expected no reviews with IDs listed in "%s" when running a "new" command.

Did you mean to run an "update" command?
If yes, run "review update -c %s ...".\
''' % (options.config, config_path))

            review_file_set.review_state.reset()
    else:
        review_file_set = \
            _init_default_review_config_file(config_path, None, False)

    if options.uncommitted:
        review_file_set.review_state.set_uncommitted(options.uncommitted)

    _post_reviews_in_config(review_file_set)


def _execute_update():
    config_path = _get_config_path()
    if isfile(config_path) and options.config is None:
        print "Using existing review configuration file %s." % config_path
    elif not isfile(config_path):
        error("Could not find review configuration file %s." % config_path)
    _post_reviews_in_config(ReviewFileSet(config_path))


def _execute_with_interaction():
    unexpected_options = ['config', 'base_url', 'branch_url', 'diff',
                          'uncommitted']
    if len(args) != 0 or any([getattr(options, name) is not None
                              for name in unexpected_options]):
        usage_error('Expected a "new" or "update" command when using one of'
                    ' the following options: %s'
                    % ", ".join(unexpected_options))

    review_file_set = _user_choose_review_config()
    if review_file_set is not None:
        _post_reviews_in_config(review_file_set)


def _user_choose_review_config():
    config_path = _get_config_path()
    if isfile(config_path):
        print "Found previous review configuration %s." % config_path
        choice_use_existing = prompt_user(
            "Use it and send review update [y/n]?", ('y', 'n'))

        if choice_use_existing == 'y':
            return ReviewFileSet(config_path)

        print '''\
(1) Load other existing review configuration?
(2) Create a NEW review request for all COMMITTED changes on the branch?
(3) Create a NEW review request for all UNCOMMITTED changes on the branch?\
'''
        choice_of_action = prompt_user("Answer:", ('1', '2', '3'))
        config_path = prompt_user("Enter path of review configuration file:")
        if choice_of_action == '1':
            if not isfile(config_path):
                error("%s does not exist" % config_path)
            return ReviewFileSet(config_path)
        elif choice_of_action in ['2', '3']:
            if isfile(config_path):
                choice_overwrite = prompt_user(
                    "Overwrite %s [y/n]?" % config_path, ('y', 'n'))
                if choice_overwrite == 'n':
                    return None
                os.unlink(config_path)
            uncommitted = (choice_of_action == '3')
            return _init_default_review_config_file(config_path, None,
                                                    uncommitted)
    else:
        print '''\
Could not find a previous review configuration for this branch.
(1) Create a NEW review request for all COMMITTED changes on the branch?
(2) Create a NEW review request for all UNCOMMITTED changes on the branch?
(3) Update an EXISTING review request with all COMMITTED changes on the \
branch?
(4) Update an EXISTING review request with all UNCOMMITTED changes on the \
branch?\
'''
        choice_of_action = prompt_user("Answer:", ('1', '2', '3', '4'))
        if choice_of_action in ['3', '4']:
            review_id = prompt_user("Give review ID:")
            if not review_id.isdigit():
                error("invalid review ID given")
        else:
            review_id = None
        uncommitted = choice_of_action in ['2', '4']
        return _init_default_review_config_file(config_path, review_id,
                                                uncommitted)


def _init_default_review_config_file(config_path, review_id, uncommitted):
    review_file_set = ReviewFileSet(config_path)
    review_config = review_file_set.review_config
    review_state = review_file_set.review_state

    review_state.set_uncommitted(uncommitted)
    review_config.add_review(review_id, "-i *")
    if not options.dry_run:
        print "Creating review configuration file %s." % config_path
        review_config.save()

    return review_file_set


def _get_config_path():
    branch_url = "." if options.branch_url is None else options.branch_url
    if branch_url == "." and options.config is None:
        return _get_default_config_path()
    elif options.config is not None:
        return options.config
    else:
        usage_error('Please specify a review configuration file'
                    ' with "-c REVIEWCONFIG".')


def _get_default_config_path():
    svn_info = svn_common.SvnPathInfo(".", _get_svn_auth())
    branch_root = svn_common.get_branch_root(svn_info.url)
    branch_name = normpath(get_working_copy_root_path(".")).split("/")[-1]
    config_path = "%s/%s.reviewconfig" % (
        relpath(dirname(branch_root), svn_info.url), branch_name)
    return config_path


def _post_reviews_in_config(review_file_set):
    global delete_temp_files
    should_save_config = False

    review_config = review_file_set.review_config
    review_state = review_file_set.review_state

    if len(review_config) == 0:
        print "No reviews defined in config."
        return

    # For backward compatibility, transfer value of config option 'uncommitted'
    # to the state file. When review config is saved again, the option is
    # removed.
    if review_config.get_option(OPTION_UNCOMMITTED) == "true":
        should_save_config = True
        review_state.set_uncommitted(True)

    uncommitted = review_state.get_uncommitted()
    if uncommitted:
        _verbose("Diff will be generated from uncommitted changes")
    diff_file, repository_root, branch, diff_base_path, reorg_needed = \
        _get_diff(uncommitted)

    try:
        filtered_diff_files = {}
        for review in review_config:
            filtered_diff_files[review] = \
                _generate_filtered_diff(diff_file, review.filter_args)
            if reorg_needed:
                _rewrite_diff_headers(filtered_diff_files[review])

        # Only post the review if the diff has changed.
        reviews_to_post = []
        for review in review_config:
            diff_checksum = checksum.from_diff(filtered_diff_files[review])
            prev_diff_checksum = review_state.get_checksum(review.review_id)
            if (prev_diff_checksum is None
                    or diff_checksum != prev_diff_checksum):
                reviews_to_post.append(review)

        # Print which reviews that have not changed, hence will not be updated.
        for review in review_config:
            if review.review_id is not None and review not in reviews_to_post:
                _verbose("Note: No new changes since the previous update of"
                         " review %s. The update will be skipped."
                         % review.review_id)

        if options.dry_run:
            return

        for review in reviews_to_post:
            review_args = []
            review_args.extend(['--repository-url', repository_root])
            review_args.extend(['--branch', branch])
            review_args.extend(['--basedir', diff_base_path])

            if options.rb_server_url is not None:
                review_args.extend(['--server', options.rb_server_url])
            if options.rb_username is not None:
                review_args.extend(['--username', options.rb_username])
            if options.rb_password is not None:
                review_args.extend(['--password', options.rb_password])

            if options.svn_username is not None:
                review_args.extend(['--svn-username', options.svn_username])
            if options.svn_password is not None:
                review_args.extend(['--svn-password', options.svn_password])

            if review.review_id is None:
                should_save_config = True
                # Set the bugs field in Review Board when creating new
                # requests, not updating since that would risk replacing the
                # information the user has put there.
                bug_reference = _get_bug_reference(branch)
                if bug_reference:
                    review_args.extend(['--bugs-closed', bug_reference])
            else:
                review_args.extend(['-r', review.review_id])

            review_args.extend(
                ['--diff-filename', filtered_diff_files[review]])

            try:
                review.review_id = post_review(review_args, options.verbose)
            except SubmittedReviewError:
                print ("If you do not want to post this review, comment out or"
                       " remove the corresponding line from the config.")
                continue
            except Exception as ex:
                delete_temp_files = False
                print >> sys.stderr, "Error: %s" % ex
                continue

            # Save the diff checksum for a posting that went without errors.
            review_state.set_checksum(
                review.review_id,
                checksum.from_diff(filtered_diff_files[review]))

    except Exception:
        delete_temp_files = False
        raise
    finally:
        if should_save_config and not options.dry_run:
            review_config.save()

        if not options.dry_run:
            review_state.save()


def _get_diff(uncommitted):
    if uncommitted and options.diff is not None:
        print ("Warning: option --diff is ignored when running in uncommitted"
               " diff mode")

    if uncommitted:
        if options.base_url is not None:
            print ("Warning: option --base-url is ignored when the generated"
                   " diff covers uncommitted changes on working copy")

        path = "." if options.branch_url is None else options.branch_url
        if not isdir(path):
            error("--branch-url does not point to a working copy directory")

        diff_command = ["svn", "diff", path]
        diff_file = _generate_diff(diff_command)

        count = _count_path_components(path)
        if count > 0:
            stripped_diff = _generate_path_stripped_diff(diff_file, count)
            diff_file = stripped_diff

        svn_info = svn_common.SvnPathInfo(path, _get_svn_auth())
        repository_root = svn_info.repository_root
        diff_base_path = svn_info.url
        branch_url = svn_common.get_branch_root(svn_info.url)
        if branch_url is None:
            branch_url = svn_info.url
        branch = branch_url[len(repository_root):]

        return diff_file, repository_root, branch, diff_base_path, False

    elif options.diff is not None:
        if not isfile(options.diff):
            error("diff file %s does not exist." % options.diff)

        if options.base_url is not None:
            print "Warning: option --base-url is ignored"

        diff_file = options.diff

        path = "." if options.branch_url is None else options.branch_url
        svn_info = svn_common.SvnPathInfo(path, _get_svn_auth())
        repository_root = svn_info.repository_root
        diff_base_path = svn_info.url
        branch_url = svn_common.get_branch_root(svn_info.url)
        if branch_url is None:
            branch_url = svn_info.url
        branch = branch_url[len(repository_root):]

        return diff_file, repository_root, branch, diff_base_path, False

    else:
        diff_command = diff_branch.get_branch_diff_command(
            "." if options.branch_url is None else options.branch_url,
            options.base_url, options.remotesvn, False, _get_svn_auth())

        diff_file = _generate_diff(diff_command)
        base_url, branch_url = diff_command[-2:]

        svn_info = svn_common.SvnPathInfo(branch_url, _get_svn_auth())
        repository_root = svn_info.repository_root
        branch = branch_url[len(repository_root):]
        diff_base_path = _get_base_path(branch_url, base_url)

        return diff_file, repository_root, branch, diff_base_path, True


def _get_base_path(branch_url, base_url=None):
    if base_url is None:
        branch = diff_branch.Branch(branch_url, base_url, _get_svn_auth())
        base_url, _ = branch.ancestor
    diff_base_path = commonprefix([base_url, branch_url])
    if diff_base_path.endswith("/"):
        return diff_base_path.rstrip('/')
    else:
        return dirname(diff_base_path)


def _generate_diff(diff_command):
    diff_file = tempfile.NamedTemporaryFile(delete=False)
    cleanup_files.append(diff_file.name)

    _verbose("Creating diff:")
    _verbose("  %s" % " ".join(diff_command))
    _verbose("  Output to: %s" % diff_file.name)

    exit_status = subprocess.call(diff_command, stdout=diff_file)
    if exit_status != 0:
        error("Failed to create diff: %s" % " ".join(diff_command))
    return diff_file.name


def _count_path_components(path):
    normalized_path = normpath(path.strip())
    return len(normalized_path.split(os.sep)) if normalized_path != '.' else 0


def _generate_path_stripped_diff(diff_file, strip_count):
    new_diff_file = tempfile.NamedTemporaryFile(delete=False)
    cleanup_files.append(new_diff_file.name)

    command = ["filterdiff", "--strip", str(strip_count), diff_file]

    _verbose("Stripping path names in diff:")
    _verbose("  %s" % " ".join(command))
    _verbose("  Output to: %s" % new_diff_file.name)

    exit_status = subprocess.call(command, stdout=new_diff_file)
    if exit_status != 0:
        error("Failed to strip diff: %s" % " ".join(command))
    return new_diff_file.name


def _generate_filtered_diff(diff_file, filter_args):
    filter_command = ['filterdiff', '--clean']
    filter_command.extend(shlex.split(filter_args))
    filter_command.append(diff_file)

    filtered_diff_file = tempfile.NamedTemporaryFile(delete=False)
    cleanup_files.append(filtered_diff_file.name)

    _verbose("Filtering diff:")
    _verbose("  filterdiff %s %s" % (filter_args, diff_file))
    _verbose("  Output to: %s" % filtered_diff_file.name)

    exit_status = subprocess.call(filter_command, stdout=filtered_diff_file)
    if exit_status != 0:
        error("Failed to filter diff: filterdiff %s %s" % (filter_args,
                                                           diff_file))

    if options.verbose:
        if _exists_on_path("diffstat"):
            exit_code, output = \
                run_command(["diffstat", filtered_diff_file.name])
            if exit_code == 0:
                _verbose("")
                _verbose(output)
        else:
            _verbose("")
            _verbose("Note! To see a list of files which are part of the diff,"
                     " you'll need to install the diffstat tool:"
                     " su -c 'yum install diffstat'")

    return filtered_diff_file.name


def _mangle_path_lines(lhs_line, rhs_line):
    """Returns original or rewritten versions of svn diff header path lines.

    This function mangles a pair of lines so that
      --- path/to/file    (.../trunk)    (revision 123)
      +++ path/to/file    (.../KREATV-some_item)    (revision 456)
    becomes
      --- trunk/path/to/file    (revision 123)
      +++ trunk/path/to/file    (working copy)

    There are three transformations taking place above:
    1) The branch name is moved so that it prepends the path. This is necessary
       to avoid RB's diff viewer from rendering SVN URLs without the branch
       name component.
    2) The LHS branch is used in the RHS path. This is necessary to prevent
       simple file changes to a path within a file from appearing as file
       copy/move operations (causing "...\n(was ...)"-style rendering in the
       in the diff viewer's file listing).
    3) The RHS's revision is replaced with 'working copy', to prevent
       postreview from trying to run
       'svn cat <LHS branch>/<RHS subpath>@<RHS revision>' and fail miserably
       (this URL would be invalid if, for example, the file has been added).
    """
    INPUT_PATTERN = '\s+'.join((r'(---|\+\+\+)',
                                r'(?P<path>\S+)',
                                r'\(.../(?P<branch>[^)]+)\)',
                                r'\((?P<revision>nonexistent|revision \d+)\)'))

    lhs_match = re.match(INPUT_PATTERN, lhs_line)
    if lhs_match is not None:
        rhs_match = re.match(INPUT_PATTERN, rhs_line)
        if rhs_match is not None:
            match_group = lhs_match.groupdict()
            # rbtools is unable to parse the revision header syntax containing
            # 'nonexistent'. It is introduced with subversion 1.9.
            if match_group["revision"] == "nonexistent":
                match_group["revision"] = "revision 0"
            return ('--- %(branch)s/%(path)s\t(%(revision)s)\n' %
                    match_group,
                    '+++ %(branch)s/%(path)s\t(working copy)\n' %
                    {'branch': lhs_match.group('branch'),
                     'path': rhs_match.group('path')})

    return (lhs_line, rhs_line)


def _rewrite_diff_headers(diff_path):
    # Slurp the existing diff
    with open(diff_path) as original_diff:
        lines = iter(original_diff.readlines())

    # Write the new diff
    with open(diff_path, 'w') as new_diff:
        for line in lines:
            if line.startswith('---'):
                # Output a pair of (possibly mangled) '---' and '+++' lines
                new_diff.write(''.join(_mangle_path_lines(line, next(lines))))
            else:
                # Output a single, unprocessed line
                new_diff.write(line)


def _get_bug_reference(text):
    match = re.search(r'/(?P<bug>KREATV-\d+)', text)
    return match.group('bug') if match else None
