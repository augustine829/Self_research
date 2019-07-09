# Copyright (c) 2014-2016 ARRIS Enterprises, Inc. All rights reserved.
# Copyright (c) 2016 ARRIS Enterprises, LLC. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, LLC.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

# Turn print into a function, works since python 2.6.0a2, required in 3.0.
from __future__ import print_function

import collections
import fnmatch
import os
import re
import shlex
import subprocess
import sys
import tempfile

from os.path import dirname, realpath, isfile

sys.path.insert(0, dirname(realpath(__file__)) + '/../../pycommon')
sys.path.insert(0, dirname(realpath(__file__)) + '/..')

from common import error, ExecutionError
from common import usage_error, UsageError
from common import prompt_user

import checksum
import devhub
import gitcommon
import refname
from configuration import ReviewFileSet
from git import cmdline
from post_review import SubmittedReviewError, post_review

options = None
args = None
cleanup_files = []
delete_temp_files = True
repo = None

Repo = collections.namedtuple(
    'Repo',
    ['name', 'branch_name', 'url', 'do_unpushed_commits_exist'])

GIT_REPO_URL = 'git@git.arrisi.com:{0}'

USAGE_ERROR_CONFIG_FOUND = '''\
Found an existing review configuration at {0}.

Do you want to create a new review using this configuration?
If so, run "review new -c {0}".

Or did you want to update an existing review using this configuration?
If so, run "review update" instead.\
'''

USAGE_ERROR_ID_FOUND_WITH_NEW = '''\
Expected no reviews with IDs listed in "{0}" when running a "new" command.

Did you mean to run an "update" command?
If yes, run "review update -c {1} ..."\
'''

USAGE_STR = '''\
{0}

Run "review --help" for usage information about program options and review
configuration file syntax.\
'''

WORKING_COPY_HAS_UNPUSHED_COMMITS = '''\
Your working copy has unpushed changes. Take one of these actions:

  * Push the changes and run the review command again.
  * Use the --pushed option if you only want to review the so far pushed
    changes and skip the local commits. The review will then contain changes
    between origin/<parent_branch> and origin/<branch>.
  * Use the --unpushed option if you only want to review the unpushed changes.
    The review will then contain changes between origin/<branch> and
    <branch>.
  * Choose the --diff option if you want to publish a custom diff.\
'''


def main(usage):
    global options
    global args
    global repo
    global delete_temp_files

    try:
        options, args = cmdline.parse_options(usage)

        _check_for_mutually_exclusive_options()

        if options.dry_run:
            options.verbose = 1 if options.verbose == 0 else options.verbose

        if options.keep_temp_files:
            delete_temp_files = False

        _show_git_client_version()
        repo_name = gitcommon.get_repo_name()

        repo = Repo(
            name=repo_name,
            branch_name=gitcommon.get_repo_branch_name(),
            url=GIT_REPO_URL.format(repo_name),
            do_unpushed_commits_exist=None)

        _verbose('Repository: {0}'.format(repo.name))
        _verbose('Branch: {0}'.format(repo.branch_name))
        _verbose('Repository URL: {0}'.format(repo.url))

        _execute()
    except ExecutionError as ex:
        print('Error:', ex, file=sys.stderr)
        sys.exit(1)
    except UsageError as ex:
        print(USAGE_STR.format(ex), file=sys.stderr)
        sys.exit(2)
    except KeyboardInterrupt:
        print
        sys.exit(3)
    finally:
        if delete_temp_files:
            for name in cleanup_files:
                os.unlink(name)
        else:
            _warning('Temp files not removed:')
            for name in cleanup_files:
                _warning(' - {0}'.format(name))


def _check_for_mutually_exclusive_options():
    if options.unpushed:
        if options.parent is not None:
            usage_error(
                'options --unpushed and --parent are mutually exclusive')
        elif options.pushed:
            usage_error(
                'options --unpushed and --pushed are mutually exclusive')

    if options.diff is not None:
        if options.parent is not None:
            usage_error('options --diff and --parent are mutually exclusive')
        elif options.unpushed:
            usage_error('options --diff and --unpushed are mutually exclusive')
        elif options.pushed:
            usage_error('options --diff and --pushed are mutually exclusive')


def _execute():
    if len(args) > 0:
        if len(args) != 1:
            error('New and update cannot be combined.')

    if 'new' in args:
        _execute_new()
    elif 'update' in args:
        _execute_update()
    else:
        _execute_with_interaction()


def _execute_new():
    config_path = _get_config_path()
    if isfile(config_path):
        if options.config is None:
            usage_error(USAGE_ERROR_CONFIG_FOUND.format(config_path))
        else:
            review_file_set = ReviewFileSet(config_path)
            if any([review.review_id is not None
                    for review in review_file_set.review_config]):
                        usage_error(USAGE_ERROR_ID_FOUND_WITH_NEW
                                    .format(options.config, config_path))
            review_file_set.review_state.reset()
    else:
        review_file_set = _init_default_review_config_file(
            config_path, None, options.unpushed, None)

    review_file_set.review_state.set_branch_parent(
        _get_branch_parent(options.unpushed))

    _post_reviews_in_config(review_file_set)


def _execute_update():
    config_path = _get_config_path()
    if isfile(config_path) and options.config is None:
        print('Using existing review configuration file {0}'
              .format(config_path))
    elif not isfile(config_path):
        error('Could not find review configuration file {0}'
              .format(config_path))

    review_file_set = ReviewFileSet(config_path)

    if options.unpushed:
        review_file_set.review_state.set_unpushed(True)
        review_file_set.review_state.set_branch_parent(
            _get_branch_parent(options.unpushed))
    elif options.parent is not None:
        review_file_set.review_state.set_unpushed(False)
        review_file_set.review_state.set_branch_parent(
            _get_branch_parent_from_option())

    _post_reviews_in_config(review_file_set)


def _execute_with_interaction():
    unexpected_options = ['config', 'diff', 'unpushed']

    if len(args) != 0 or any([getattr(options, name)
                             for name in unexpected_options]):
        usage_error('Expected a "new" or "update" command when using one of'
                    ' the following options: {0}'
                    .format(', '.join(unexpected_options)))

    review_file_set = _user_choose_review_config()
    if review_file_set is not None:
        _post_reviews_in_config(review_file_set)


def _generate_diff(diff_command):
    diff_file = tempfile.NamedTemporaryFile(delete=False)
    cleanup_files.append(diff_file.name)

    _verbose('Creating diff:')
    _verbose('  {0}'.format(' '.join(diff_command)))
    _verbose('  Output to: {0}'.format(diff_file.name))

    rc = subprocess.call(diff_command, stdout=diff_file)
    if rc != 0:
        error('Failed to create diff: {0}'.format(' '.join(diff_command)))

    return diff_file.name


def _generate_filtered_diff(diff_file, filter_args):
    _verbose('filter_args: {0}'.format(filter_args))
    _verbose('shlex.split(filter_args): {0}'
             .format(shlex.split(filter_args)), 2)

    arg_list = shlex.split(filter_args)

    if len(arg_list) % 2 != 0:
        error('Bad number of diff filter argumets in config! '
              'Check arguments: {0}'.format(filter_args))

    include_paths = []
    exclude_paths = []

    for i, path_action in enumerate(arg_list[::2]):
        if path_action == '-i':
            include_paths.append(arg_list[2 * i + 1])
        elif path_action == '-x':
            exclude_paths.append(arg_list[2 * i + 1])
        else:
            error('Bad path action "{0}" detected in config.'
                  ' Expecting "-i" or "-x"'
                  .format(path_action))

    filtered_diff_file = tempfile.NamedTemporaryFile(delete=False)
    cleanup_files.append(filtered_diff_file.name)

    _verbose('Filtering diff:')
    _verbose('  Output to: {0}'.format(filtered_diff_file.name))

    pattern = r'diff --git a/(?P<path_a>[\S]+) b/(?P<path_b>[\S]+)'

    with open(diff_file, 'r') as fp:
        should_include_segment = False

        for line in fp:
            match = re.match(pattern, line)
            if match:
                path_a = match.group('path_a')

                should_include_segment = False
                for include_path in include_paths:
                    if fnmatch.fnmatch(path_a, include_path):
                        should_include_segment = True
                        break

                for exclude_path in exclude_paths:
                    if fnmatch.fnmatch(path_a, exclude_path):
                        should_include_segment = False
                        break

                _verbose(
                    '  New file segment found in diff. Path: {0} Include: {1}'
                    .format(path_a, should_include_segment), 2)

            if should_include_segment:
                filtered_diff_file.write(line)

    return filtered_diff_file.name


def _get_bug_reference(text):
    match = re.search(r'/(?P<bug>KREATV-\d+)', text)
    return match.group('bug') if match else None


def _get_config_path():
    config_path = None

    if options.config is not None:
        config_path = options.config
    else:
        branch_root = gitcommon.get_repo_top_level()
        dir_name = branch_root.split('/')[-1]
        base_path = os.path.normpath(os.path.join(branch_root, '../'))
        config_path = '{0}/{1}.{2}.reviewconfig'.format(
            base_path, dir_name, repo.branch_name)

    _verbose('Config path: {0}'.format(config_path))
    return config_path


def _get_diff(parent, unpushed):
    if options.diff is not None:
        if not isfile(options.diff):
            error('diff file {0} does not exist.'.format(options.diff))

        return options.diff

    if (not unpushed
            and not options.pushed
            and _do_unpushed_commits_exist()):
        usage_error(WORKING_COPY_HAS_UNPUSHED_COMMITS)

    if unpushed:
        branch = ''
    else:
        branch = 'origin/{0}'.format(repo.branch_name)

    cmd = ['git',
           'diff',
           '{0}...{1}'.format(parent, branch),
           '--full-index',
           '--no-color']

    return _generate_diff(cmd)


def _get_branch_parent(unpushed, query_user=False):
    parent = None

    if options.diff:
        parent = None
    else:
        parent_source = None

        if unpushed:
            parent = 'origin/{0}'.format(repo.branch_name)
            parent_source = 'unpushed'

        if parent is None:
            parent = _get_branch_parent_from_option()
            parent_source = 'option'

        if parent is None:
            parent = _query_api_for_branch_parent()
            parent_source = 'api'

        if parent is None and query_user:
            parent = _query_user_for_branch_parent()
            parent_source = 'user'

        if parent is None:
            error('Branch parent not found, please use the --parent option.')
        else:
            print('Branch parent: {0} [{1}]'.format(parent, parent_source))

    return parent


def _get_branch_parent_from_option():
    parent = None

    if options.parent:
        parent = refname.RefName(options.parent)

        if parent.path_depth() == 1:
            parent = refname.RefName('origin/{0}'.format(parent))

        if not parent.exists():
            raise UsageError(
                'Branch parent "{0}" does not exist.'.format(parent))
        parent = str(parent)

    return parent


def _do_unpushed_commits_exist():
    global repo

    if repo.do_unpushed_commits_exist is not None:
        return repo.do_unpushed_commits_exist

    latest_committed_hash = gitcommon.rev_parse(repo.branch_name)

    _verbose('Latest committed hash: {0}'.format(
        latest_committed_hash.strip()), 2)

    origin_branch = 'origin/{0}'.format(repo.branch_name)
    try:
        latest_pushed_hash = gitcommon.rev_parse(origin_branch)
    except ExecutionError:
        raise ExecutionError('Failed to get latest pushed hash for branch {0}.'
                             ' Make sure that the branch has been pushed to'
                             ' origin.'.format(origin_branch))
    _verbose('Latest pushed hash:    {0}'.format(
        latest_pushed_hash.strip()), 2)

    do_unpushed_commits_exist = latest_pushed_hash != latest_committed_hash
    repo = repo._replace(do_unpushed_commits_exist=do_unpushed_commits_exist)

    return repo.do_unpushed_commits_exist


def _init_default_review_config_file(config_path, review_id, unpushed, parent):
    if (not unpushed
            and not options.pushed
            and options.diff is None
            and _do_unpushed_commits_exist()):
        usage_error(WORKING_COPY_HAS_UNPUSHED_COMMITS)

    review_file_set = ReviewFileSet(config_path)
    review_config = review_file_set.review_config
    review_state = review_file_set.review_state

    review_state.set_unpushed(unpushed)
    review_state.set_branch_parent(parent)
    review_config.add_review(review_id, '-i *')
    if not options.dry_run:
        print('Creating review configuration file {0}.'.format(config_path))
        review_config.save()

    return review_file_set


def _post_reviews_in_config(review_file_set):
    global delete_temp_files
    should_save_config = False

    review_config = review_file_set.review_config
    review_state = review_file_set.review_state

    if len(review_config) == 0:
        print('No reviews defined in config.')
        return

    unpushed = review_state.get_unpushed()
    if unpushed:
        print('Diff will be generated from unpushed changes.')

    diff_file = _get_diff(review_state.get_branch_parent(), unpushed)

    try:
        filtered_diff_files = {}
        for review in review_config:
            filtered_diff_files[review] = \
                _generate_filtered_diff(diff_file, review.filter_args)

        # Only post the review if the diff has changed.
        reviews_to_post = []
        for review in review_config:
            diff_checksum = checksum.from_git_diff(filtered_diff_files[review])
            prev_diff_checksum = review_state.get_checksum(review.review_id)
            _verbose('Prev diff checksum: {0}'.format(prev_diff_checksum), 2)
            _verbose('Current diff checksum: {0}'.format(diff_checksum), 2)

            if (prev_diff_checksum is None or
                    diff_checksum != prev_diff_checksum):
                reviews_to_post.append(review)

        # Print which reviews that have not changed, hence will not be updated.
        for review in review_config:
            if review.review_id is not None and review not in reviews_to_post:
                print('No new changes since the previous update of'
                      ' review {0}. The update will be skipped.'
                      .format(review.review_id))

        if options.dry_run:
            return

        for review in reviews_to_post:
            review_args = []
            review_args.extend(['--branch', repo.branch_name])

            if options.rb_server_url is not None:
                review_args.extend(['--server', options.rb_server_url])
            if options.rb_username is not None:
                review_args.extend(['--username', options.rb_username])
            if options.rb_password is not None:
                review_args.extend(['--password', options.rb_password])

            if options.verbose > 2:
                review_args.append('--debug')

            review_args.extend(['--repository-url', repo.url])

            if review.review_id is None:
                should_save_config = True
                # Set the bugs field in Review Board when creating new
                # requests, not updating since that would risk replacing the
                # information the user has put there.
                bug_reference = _get_bug_reference(repo.branch_name)
                if bug_reference:
                    review_args.extend(['--bugs-closed', bug_reference])
            else:
                review_args.extend(['-r', review.review_id])

            review_args.extend(
                ['--diff-filename', filtered_diff_files[review]])

            try:
                if options.skip_post_review:
                    review.review_id = '0'
                    _warning('--skip-post-review set,'
                             ' review will not be posted')
                else:
                    review.review_id = post_review(
                        review_args, options.verbose)
            except SubmittedReviewError:
                print('If you do not want to post this review, comment out or'
                      ' remove the corresponding line from the config.')
                continue
            except Exception as ex:
                delete_temp_files = False
                print('Error:', ex, file=sys.stderr)
                continue

            # Save the diff checksum for a posting that went without errors.
            review_state.set_checksum(
                review.review_id,
                checksum.from_git_diff(filtered_diff_files[review]))

    except Exception:
        delete_temp_files = False
        raise
    finally:
        if should_save_config and not options.dry_run:
            review_config.save()

        if not options.dry_run:
            review_state.save()


def _query_api_for_branch_parent():
    try:
        return devhub.get_branch_parent(repo.name,
                                        repo.branch_name,
                                        options.verbose >= 2)
    except ExecutionError as e:
        _warning(str(e))
        return None


def _query_user_for_branch_parent():
    print('Could not determine the parent of the branch "{0}".'
          .format(repo.branch_name))

    while True:
        response = prompt_user('Please input parent:')
        parent = refname.RefName(response)

        if parent.path_depth() == 1:
            parent = refname.RefName('origin/{0}'.format(parent))

        if parent.exists():
            break
        else:
            print('Could not find parent branch: {0}'.format(parent))

    return parent


def _show_git_client_version():
    try:
        version = gitcommon.get_git_client_version()
        _verbose('Git version: {0}'.format(version))
    except gitcommon.Warning as w:
        _warning(' {0}'.format(w))


def _user_choose_review_config():
    config_path = _get_config_path()
    if isfile(config_path):
        print('Found previous review configuration {0}'.format(config_path))
        choice_use_existing = prompt_user(
            'Use it and send review update [y/n]?', ('y', 'n'))

        if choice_use_existing == 'y':
            return ReviewFileSet(config_path)

        print('''\
(1) Load other existing review configuration?
(2) Create a NEW review request for all PUSHED changes on the branch?
(3) Create a NEW review request for all UNPUSHED changes on the branch?\
''')
        choice_of_action = prompt_user('Answer:', ('1', '2', '3'))
        config_path = prompt_user('Enter path of review configuration file:')
        if choice_of_action == '1':
            if not isfile(config_path):
                error('{0} does not exist'.format(config_path))

            review_file_set = ReviewFileSet(config_path)
            if review_file_set.review_state.get_branch_parent() is None:
                review_file_set.review_state.set_branch_parent(
                    _get_branch_parent(unpushed=False, query_user=True))

            return review_file_set
        elif choice_of_action in ['2', '3']:
            if isfile(config_path):
                choice_overwrite = prompt_user(
                    'Overwrite {0} [y/n]?'.format(config_path), ('y', 'n'))
                if choice_overwrite == 'n':
                    return None
                os.unlink(config_path)

            unpushed = choice_of_action == '3'
            parent = _get_branch_parent(unpushed, query_user=True)

            return _init_default_review_config_file(
                config_path, None, unpushed, parent)
    else:
        print('''\
Could not find a previous review configuration for this branch.
(1) Create a NEW review request for all PUSHED changes on the branch?
(2) Create a NEW review request for all UNPUSHED changes on the branch?
(3) Update an EXISTING review request with all PUSHED changes on the \
branch?
(4) Update an EXISTING review request with all UNPUSHED changes on the branch?
''')
        choice_of_action = prompt_user('Answer:', ('1', '2', '3', '4'))
        if choice_of_action in ['3', '4']:
            review_id = prompt_user('Give review ID:')
            if not review_id.isdigit():
                error('invalid review ID given')
        else:
            review_id = None

        unpushed = choice_of_action in ['2', '4']
        parent = _get_branch_parent(unpushed, query_user=True)

        return _init_default_review_config_file(
            config_path, review_id, unpushed, parent)


def _verbose(message, level=1):
    if options.verbose >= level:
        print(message)


def _warning(message):
    print('Warning: {0}'.format(message))
