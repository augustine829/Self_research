# Copyright (c) 2014-2015 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

import copy
import os.path
import re
import xml.etree.ElementTree as ElementTree

from common import error, ExecutionError
from svn_common import get_branch_root
from svn_common import run_svn_command


def debug(message):
    # print '[' + message + ']'
    pass


class colors:
    BLUE = '\033[94m'
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    ENDC = '\033[0m'


class SvnPath:
    def __init__(self, repository_root, path_or_url, revision=None):
        self.repository_root = repository_root
        self.set(path_or_url, revision)

    def set(self, path_or_url, revision=None):
        if '@' in path_or_url:
            path_or_url, _, self.revision = path_or_url.partition('@')
        else:
            self.revision = 'HEAD'
        if revision:
            self.revision = revision
        # full_url:   http://svn.arrisi.com/bsg/trunk/foo/bar
        self.full_url = self._complete_url(path_or_url)
        # branch_url: http://svn.arrisi.com/bsg/trunk
        self.branch_url = get_branch_root(self.full_url)
        # file_path:  foo/bar
        self.file_path = self.full_url[len(self.branch_url):].lstrip('/')

    def _complete_url(self, path_or_url):
        if path_or_url.startswith(self.repository_root):
            return path_or_url
        else:
            return '%s/%s' % (self.repository_root, path_or_url.lstrip('/'))

    def set_branch(self, branch_path_or_url):
        self.branch_url = self._complete_url(branch_path_or_url)
        self.full_url = self.branch_url + '/' + self.file_path

    def set_file_path(self, file_path):
        self.file_path = file_path
        self.full_url = self.branch_url + '/' + self.file_path

    def set_revision(self, revision):
        if revision:
            self.revision = revision

    def root_relative_path(self):
        # http://svn.arrisi.com/dev/bsg/trunk/foo --> /bsg/trunk/foo
        return self.full_url[len(self.repository_root):]

    def root_relative_branch_path(self):
        # http://svn.arrisi.com/dev/bsg/trunk/foo --> /bsg/trunk
        return self.branch_url[len(self.repository_root):]

    def __str__(self):
        if self.revision == 'HEAD':
            return self.full_url
        else:
            return self.full_url + '@' + self.revision


class Commit:
    SVN_PROMPT_MERGEINFO_RE = r'^\S+: svn:mergeinfo$'
    SVN_MERGEINFO_RE = r'^   \S+ (?P<branch>\S+):.*(-|,|r)' \
                       r'(?P<latest_revision>\w{3,6})$'

    def __init__(self, svn_path, revision=None):
        self._repository_root = svn_path.repository_root
        self._has_checked_mergeinfo = False
        self._merged_branch_path = None
        self._changed_paths = None
        self.author = None
        self.datetime = None
        self.branch_url = None
        self.revision = None

        self._get_log(svn_path, revision)
        debug("Commit is at branch %s@%s" % (self.branch_url,
                                             self.revision))

    def is_merged(self):
        self._check_mergeinfo()
        return self._merged_branch_path is not None

    def get_merged_branch_path(self):
        self._check_mergeinfo()
        return self._merged_branch_path

    def is_path_added_or_updated(self, relative_file_path):
        for path in self._changed_paths.findall('path'):
            if (path.text.endswith(relative_file_path)
               and path.attrib['action'] in ['M', 'A']):
                return True
        return False

    def is_path_newly_added(self, relative_file_path):
        for path in self._changed_paths.findall('path'):
            if (path.text.endswith(relative_file_path)
               and path.attrib['action'] == 'A'
               and 'copyfrom-path' not in path.attrib):
                return True
        return False

    def get_info(self):
        return "r%s | %s | %s " % (self.revision, self.author, self.datetime)

    def _get_log(self, svn_path, revision):
        svn_log_command = ['svn', 'log',
                           '--xml',
                           '-v',
                           '-l', '1',
                           str(svn_path)]
        if revision:
            svn_log_command += ['-r', '%s' % revision]

        result_in_xml = run_svn_command(svn_log_command)
        log_entry_node = ElementTree.fromstring(result_in_xml).find('logentry')
        self.revision = log_entry_node.attrib['revision']
        self.author = log_entry_node.find('author').text
        self.datetime = log_entry_node.find('date').text

        self._changed_paths = log_entry_node.find('paths')
        if self._changed_paths is not None:
            self.branch_url = SvnPath(self._repository_root,
                                      self._changed_paths[0].text).branch_url
        else:
            error("Could not find any changed paths for this commit")

    def _check_mergeinfo(self):
        if self._has_checked_mergeinfo:
            return
        self._has_checked_mergeinfo = True

        svn_diff_command = ['svn', 'diff',
                            '-c', self.revision,
                            '--depth', 'empty',
                            '%s@%s' % (self.branch_url, self.revision)]
        diff_entries = run_svn_command(svn_diff_command).split('\n')

        merged_branch_path = None
        merged_revision = None
        i = 0
        while i < len(diff_entries):
            if re.match(Commit.SVN_PROMPT_MERGEINFO_RE, diff_entries[i]):
                i += 1
                break
            i += 1
        while (i < len(diff_entries) and diff_entries[i] and
               not diff_entries[i].startswith("Modified")):
            merge_match = re.match(Commit.SVN_MERGEINFO_RE, diff_entries[i])
            if merge_match:
                rev = merge_match.group('latest_revision')
                if merged_revision < rev:
                    merged_branch_path = merge_match.group('branch')
                    merged_revision = rev
            else:
                error("Cannot find matching mergeinfo in line "
                      + diff_entries[i])
            i += 1

        if merged_branch_path:
            self._merged_branch_path = SvnPath(self._repository_root,
                                               merged_branch_path,
                                               merged_revision)
            debug("Commit %s is a merge from %s" % (self.revision,
                                                    self._merged_branch_path))
        else:
            debug("Commit %s is not a merge." % self.revision)

    def get_path(self, curr_path):
        '''
        Return the changed path which was named to curr_path some time
        later. Return None if no related changed path is found in the commit.
        '''
        changed_path = copy.deepcopy(curr_path)
        if not self.is_path_added_or_updated(curr_path.file_path):
            debug("The file %s was not changed at revision %s@%s." %
                  (curr_path.file_path.lstrip('/'),
                   self.branch_url,
                   self.revision))
            debug("The file might have been renamed somewhere.")
            while True:
                changed_path, _ = get_original_path(changed_path)
                if changed_path is None:
                    return None
                elif self.is_path_added_or_updated(changed_path.file_path):
                    break
        changed_path.set_branch(self.branch_url)
        changed_path.set_revision(self.revision)
        return changed_path


def get_annotated_revision(svn_path, revision, line_no):
    'Return the annotated revision for the specific line.'
    svn_ann_command = ['svn', 'ann', '--xml', str(svn_path)]
    if revision:
        svn_ann_command += ['-r', revision]

    result_in_xml = run_svn_command(svn_ann_command)

    for item in ElementTree.fromstring(result_in_xml).getiterator('entry'):
        if item.attrib['line-number'] == str(line_no):
            debug("annotated revision is %s" %
                  item.find('commit').get('revision'))
            return item.find('commit').get('revision')

    error("Could not find line %d in %s" % (line_no, svn_path))


def diff_revision(left_svn_path, right_svn_path, right_lineno):
    ''' Find out line no of specific line in the left revision.
        Return: 0  - no such line in left revision
                >0  - the line no in left revision
                None - cannot decide if the line exists in left revision
    '''
    svn_diff_command = ['svn', 'diff',
                        str(left_svn_path), str(right_svn_path)]
    diff_lines = run_svn_command(svn_diff_command).split('\n')

    if len(diff_lines) == 0:
        # same files
        return right_lineno, None

    right_lineno_start = 0
    left_lineno_start = 0
    right_lineno_end = 0
    left_lineno_end = 0

    i = 0
    while i < len(diff_lines):
        index_match = re.match(r'^@@ -(?P<left_start_lineno>\d+),'
                               r'(?P<left_line_num>\d+) '
                               r'\+(?P<right_start_lineno>\d+),'
                               r'(?P<right_line_num>\d+)',
                               diff_lines[i])
        if index_match:
            left_lineno_start = int(index_match.group('left_start_lineno'))
            left_lineno_end = left_lineno_start - 1 + \
                int(index_match.group('left_line_num'))
            right_lineno_start = int(index_match.group('right_start_lineno'))
            right_lineno_end = right_lineno_start - 1 + \
                int(index_match.group('right_line_num'))
            if right_lineno_start > right_lineno or \
               right_lineno_start <= right_lineno <= right_lineno_end:
                break
        i += 1

    if i == len(diff_lines):
        debug("diff_revision: found line unchanged in left %d" %
              (right_lineno - right_lineno_end + left_lineno_end))
        return right_lineno - right_lineno_end + left_lineno_end, None
    elif right_lineno_start > right_lineno:
        debug("diff_revision: found line unchanged in left %d" %
              (left_lineno_start - (right_lineno_start - right_lineno)))
        return left_lineno_start - (right_lineno_start - right_lineno), None
    else:
        # the line is in a diff part
        left_line_count_in_changes = 0
        saved_diff_line_index = i
        left_lineno_curr = left_lineno_start
        right_lineno_curr = right_lineno_start
        i += 1
        debug("Searching in diff (left %d, %d) and (right %d, %d)" %
              (left_lineno_start, left_lineno_end,
               right_lineno_start, right_lineno_end))
        while i < len(diff_lines) and right_lineno_curr <= right_lineno_end:
            if re.match(r'^-', diff_lines[i]):
                # The changes of left file
                diff_lines[i] = diff_lines[i].ljust(80) + \
                    " <== Line %d" % left_lineno_curr
                left_lineno_curr += 1
                left_line_count_in_changes += 1
            elif re.match(r'^\+', diff_lines[i]):
                # The changes of right file
                if right_lineno_curr == right_lineno:
                    diff_lines[i] = colors.BLUE + diff_lines[i] + colors.ENDC
                right_lineno_curr += 1
            else:
                # The common lines to both files
                if right_lineno_curr == right_lineno:
                    debug("diff_revision: found line unchanged in left %d" %
                          left_lineno_curr)
                    return left_lineno_curr, None
                left_lineno_curr += 1
                right_lineno_curr += 1
            i += 1
        if left_line_count_in_changes == 0:
            debug("diff_revision: it is newly added line that is not in left.")
            return 0, diff_lines[saved_diff_line_index:i]  # purely new line(s)
        else:
            debug("diff_revision: the line shall be different in left.")
            return None, diff_lines[saved_diff_line_index:i]


def annotate_commit(svn_path, revision, line_no):
    ann_revision = get_annotated_revision(svn_path, revision, line_no)
    debug("The line was updated in r%s." % ann_revision)
    # Look for the path in annotated revision
    # Sometimes the annotated revision is not visible along
    # the peggy path.
    old_svn_path = copy.deepcopy(svn_path)
    old_svn_path.set_revision(revision)
    try:
        commit = Commit(old_svn_path, ann_revision)
    except ExecutionError:
        debug("Could not find revision %s along path %s. "
              "Trying to find a proper path." %
              (ann_revision, svn_path))
        while True:
            old_svn_path, _ = get_original_path(old_svn_path)
            if old_svn_path is None:
                error("Failed to find the path in revision %s" %
                      ann_revision)
            try:
                commit = Commit(old_svn_path, ann_revision)
                break
            except ExecutionError:
                pass
    return commit, commit.get_path(old_svn_path)


def get_original_path(svn_path, revision=None):
    '''
    Find out the original path that svn_path comes from.
    Return None when the input path has not been renamed yet.
    '''
    if revision is None:
        revision = svn_path.revision
    svn_log_command = ['svn', 'log',
                       '-v',
                       '--xml',
                       '--stop-on-copy',
                       '-l', '1',
                       '-r', '1:%s' % revision,
                       '?']
    root_relative_path = svn_path.root_relative_path()
    branch_relative_path = svn_path.root_relative_branch_path()

    # In old subversion, file path is not in the change list when its
    # parent directory is renamed.
    # Loop to search the parent directories till the branch level.
    while root_relative_path != branch_relative_path:
        svn_log_command[-1] = '%s%s@%s' % (svn_path.repository_root,
                                           root_relative_path,
                                           svn_path.revision)
        result_in_xml = run_svn_command(svn_log_command)
        root_node = ElementTree.fromstring(result_in_xml)

        rev = root_node.find('logentry').attrib['revision']
        for changed_path in root_node.getiterator('path'):
            if changed_path.attrib['action'] not in ['A', 'R']:
                continue

            if changed_path.text == root_relative_path:
                if 'copyfrom-path' not in changed_path.attrib:
                    if root_relative_path == svn_path.root_relative_path():
                        return (SvnPath(svn_path.repository_root,
                                        root_relative_path,
                                        rev),
                                rev) if rev != revision else (None, None)
                    else:
                        error("Only found \"add\" history of parent %s "
                              "but not of path %s."
                              % (svn_path.repository_root +
                                 root_relative_path,
                                 svn_path))
                else:
                    from_path_string = \
                        svn_path.root_relative_path().replace(
                            root_relative_path,
                            changed_path.attrib['copyfrom-path'])
                    debug("Found original path %s@%s" % (
                          from_path_string,
                          changed_path.attrib['copyfrom-rev']))
                    from_path = SvnPath(svn_path.repository_root,
                                        from_path_string,
                                        changed_path.attrib['copyfrom-rev'])
                    if (from_path.file_path == svn_path.file_path
                       and from_path.branch_url != svn_path.branch_url):
                        # Continue to search the merged path
                        return get_original_path(from_path)
                    else:
                        return from_path, rev

            if branch_relative_path.startswith(changed_path.text):
                branch_relative_path =  \
                    svn_path.root_relative_branch_path().replace(
                        changed_path.text,
                        changed_path.attrib['copyfrom-path'])
                # the commit is for branch creation
                path_in_parent_branch = SvnPath(
                    svn_path.repository_root,
                    branch_relative_path + '/' + svn_path.file_path,
                    changed_path.attrib['copyfrom-rev'])
                debug("Check parent branch %s" % path_in_parent_branch)
                return get_original_path(path_in_parent_branch)

        root_relative_path = os.path.dirname(root_relative_path)
        debug("Check upper directory %s" % root_relative_path)

    error('unable to find branch ancestor; expected "A" or "R" entry '
          'in output from "%s" but could not find any.'
          % ' '.join(svn_log_command))
