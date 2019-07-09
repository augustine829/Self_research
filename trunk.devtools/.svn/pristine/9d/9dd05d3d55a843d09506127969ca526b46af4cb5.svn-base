import optparse
import os
import re
import sys

from os.path import dirname, join, realpath
from subprocess import call, Popen, PIPE

sys.path.insert(0, dirname(realpath(__file__)) + '/../pycommon')

from svn_common import SvnAuth, SvnPathInfo, insert_svn_authentication
from svn_common import verify_branch_argument, get_branch_root

REMOTESVN = realpath(join(dirname(__file__), '..', '..', 'bin', 'remotesvn'))

cmdline_options = None


# Runs command (a sequence). If command is successful, command's stdout is
# returned. If unsuccessful, the program exits (command's stderr is not
# captured, so this will hopefully give the user a clue as to what went
# wrong). Unlike subprocess.check_output, this code works with Python 2.6.
def run_command(command):
    assert not isinstance(command, basestring)
    environment = os.environ
    environment['LC_ALL'] = 'POSIX'
    process = Popen(command, stdout=PIPE, env=environment)
    stdout, _ = process.communicate()
    if process.returncode != 0:
        fail('command "%s" failed' % ' '.join(command))
    return stdout


def fail(short_message):
    sys.stderr.write('Error: %s\n' % short_message.strip())
    sys.exit(1)


def warning(short_message):
    sys.stderr.write('Warning: %s\n' % short_message.strip())


def verbose(message):
    if cmdline_options is not None and cmdline_options.verbose:
        print message
        sys.stdout.flush()


def pegged_url(url, peg_revision, keep_head=True):
    if not keep_head and peg_revision == 'HEAD':
        return url
    return '%s@%s' % (url, peg_revision)


class Branch:
    SVN_ADD_RE = r'\s+A %s \(from (?P<src_branch>[^:]+):(?P<src_rev>\d+)\)'
    SVN_DELETE_RE = r'\s+D %s'

    def __init__(self, path_or_url, base_url=None, svn_auth=None):
        self._svn_auth = svn_auth
        self._svn_info = SvnPathInfo(path_or_url, self._svn_auth)

        self.url = get_branch_root(self._svn_info.url)
        if self.url is None:
            fail('unable to find branch root for %s' % self._svn_info.url)

        if '@' in path_or_url:
            _, _, self.end_revision = path_or_url.partition('@')
        else:
            self.end_revision = 'HEAD'

        if base_url is None:
            self.ancestor = self._get_ancestor(self.url, self.end_revision)
            verbose('Branch created from: %s@%d' % self.ancestor)
        else:
            base_root_url = get_branch_root(
                SvnPathInfo(base_url, self._svn_auth).url)
            if '@' in base_url:
                _, _, ignored_revision = base_url.partition('@')
                warning('revision in base url is ignored: @%s'
                        % ignored_revision)
            self.ancestor = base_root_url, None

    def _get_ancestor(self, branch_url, ceil_revision):
        svn_log_command = ['svn', 'log',
                           '-v', '--stop-on-copy',
                           '-l', '1',
                           '-r', '1:%s' % ceil_revision,
                           '%s@%s' % (branch_url, ceil_revision)]
        insert_svn_authentication(svn_log_command, self._svn_auth, 2)
        first_branch_log_entry = run_command(svn_log_command).split('\n')

        src_branch, src_rev = None, None
        for line in first_branch_log_entry:
            root_relative_path = self._root_relative_path(branch_url)
            add_match = re.match(
                Branch.SVN_ADD_RE % re.escape(root_relative_path),
                line)
            if add_match:
                src_branch, src_rev = add_match.group('src_branch', 'src_rev')
                break

        if src_branch is None:
            fail('unable to find branch ancestor; expected "A" entry '
                 'in output from "%s" but could not find any' %
                 ' '.join(svn_log_command))

        branch_was_moved = False
        for line in first_branch_log_entry:
            delete_match = re.match(
                Branch.SVN_DELETE_RE % re.escape(src_branch),
                line)
            if delete_match:
                branch_was_moved = True
                break

        if branch_was_moved:
            return self._get_ancestor(self._complete_url(src_branch), src_rev)
        else:
            # Branch was copied
            return self._complete_url(src_branch), int(src_rev)

    def _root_relative_path(self, url):
        """E.g. http://svn.arrisi.com/dev/bsg/trunk --> /bsg/trunk"""
        if url.startswith(self._svn_info.repository_root):
            return url[len(self._svn_info.repository_root):]
        else:
            return url

    def _complete_url(self, path):
        """E.g. /bsg/trunk --> http://svn.arrisi.com/dev/bsg/trunk"""
        if path.startswith(self._svn_info.repository_root):
            return path
        else:
            return '%s/%s' % (self._svn_info.repository_root, path.lstrip('/'))

    def get_highest_merged_ancestor_revision(self):
        svn_propget_command = ['svn', 'propget', 'svn:mergeinfo',
                               pegged_url(self.url, self.end_revision)]
        insert_svn_authentication(svn_propget_command, self._svn_auth, 3)
        svn_propget_output = run_command(svn_propget_command)
        ancestor_branch = self.ancestor[0]
        return get_highest_merged_revision(
            svn_propget_output, self._root_relative_path(ancestor_branch))


def get_highest_merged_revision(svn_propget_mergeinfo_output,
                                branch_path_in_repo):
    branch_mergeinfo_pattern = (r'%s:.*?(?P<last_revision_mentioned>\d+)$' %
                                branch_path_in_repo)

    for line in svn_propget_mergeinfo_output.split('\n'):
        m = re.match(branch_mergeinfo_pattern, line)
        if m:
            # Assume last rev. in a mergeinfo line is the highest rev. merged.
            return int(m.group('last_revision_mentioned'))

    return None


def get_branch_diff_command(branch_url, base_url=None, use_remotesvn=False,
                            do_summarize=False, svn_auth=None,
                            directory=None):
    branch = Branch(branch_url, base_url, svn_auth)

    ancestor_branch, branch_off_revision = branch.ancestor
    highest_merged_ancestor_revision = \
        branch.get_highest_merged_ancestor_revision()

    if branch_off_revision is None \
       and highest_merged_ancestor_revision is None:
        url = pegged_url(branch.url, branch.end_revision, keep_head=False)
        fail("Branch %s is required to be rebased against %s."
             % (url, ancestor_branch))

    verbose('Highest merged ancestor revision: %s' %
            (highest_merged_ancestor_revision
             if (highest_merged_ancestor_revision is not None
                 and highest_merged_ancestor_revision > branch_off_revision)
             else ('<no revision higher than revision created from has been '
                   'merged>')))

    ancestor_diff_revision = (max(branch_off_revision,
                                  highest_merged_ancestor_revision)
                              if highest_merged_ancestor_revision is not None
                              else branch_off_revision)

    directory = "/%s" % directory if directory else ""
    old_url = pegged_url(ancestor_branch + directory, ancestor_diff_revision)
    new_url = pegged_url(branch.url + directory, branch.end_revision,
                         keep_head=False)

    tool = REMOTESVN if use_remotesvn else 'svn'
    command = [tool, 'diff', old_url, new_url]
    insert_svn_authentication(command, svn_auth, 2)
    if do_summarize:
        command.append('--summarize')
    return command


BRANCH_ARGUMENT_DESCRIPTION = '''\
BRANCH[@REV] can be a URL (optionally for a specific revision) or a working
copy path. The default is ".". If BRANCH refers to a subdirectory, the branch
root will be used instead. The reference point ("left side") of the diff will
be BRANCH's immediate ancestor as it looked like in the highest ancestor
revision that has been merged to BRANCH. Typically, this is the last ancestor
revision BRANCH was rebased to or, if BRANCH has not been rebased, the ancestor
revision from which BRANCH was created. The "right side" of the diff will be
BRANCH@HEAD (or BRANCH@REV if a revision was specified).'''


class MultiParagraphDescriptionFormatter(optparse.IndentedHelpFormatter):
    def __init__(self):
        optparse.IndentedHelpFormatter.__init__(self)

    def format_description(self, description):
        if description:
            paragraphs = [p.strip()
                          for p in description.strip().split('\n\n')
                          if p.strip() != '']
            formatted_paragraphs = [self._format_text(p) for p in paragraphs]
            return '\n\n'.join(formatted_paragraphs) + '\n'
        else:
            return ''


def parse_args():
    parser = optparse.OptionParser(
        usage='%prog [OPTIONS] [BRANCH[@REV]]',
        description=('''
%%prog prints a diff with the changes done on BRANCH to stdout.

%s''' % BRANCH_ARGUMENT_DESCRIPTION),
        formatter=MultiParagraphDescriptionFormatter())

    parser.add_option('-b', '--base-url',
                      default=None,
                      help='use a specific base url for diff generation')
    parser.add_option('-r', '--remotesvn',
                      default=False,
                      action='store_true',
                      help='use remotesvn instead of svn for diff generation')
    parser.add_option('-s', '--summarize',
                      default=False,
                      action='store_true',
                      help='show a summary of the results')
    parser.add_option('-n', '--dry-run',
                      action='store_true',
                      default=False,
                      help=('print the "svn diff ..." command that would be '
                            'used for diff generation and then exit'))
    parser.add_option('-u', '--username',
                      default=None,
                      help=("username for authenticating to the SVN server,"
                            " by default the current username is used."))
    parser.add_option('-p', '--password',
                      default=None,
                      help=("password for authenticating to the SVN server,"
                            " by default cached password is used."))
    parser.add_option('-v', '--verbose',
                      action='store_true',
                      default=False,
                      help='print additional information')
    parser.add_option('-d', '--directory',
                      help="directory (relative to root) to compare")

    options, positional_args = parser.parse_args()

    if len(positional_args) > 1:
        fail('expected at most one positional argument (BRANCH)')

    branch = ('.' if len(positional_args) == 0 else positional_args[0])
    verify_branch_argument(branch)
    return (branch, options)


def main():
    global cmdline_options
    branch, cmdline_options = parse_args()
    svn_auth = SvnAuth(cmdline_options.username, cmdline_options.password)
    diff_command = get_branch_diff_command(
        branch, cmdline_options.base_url, cmdline_options.remotesvn,
        cmdline_options.summarize, svn_auth, cmdline_options.directory)

    if cmdline_options.dry_run:
        print ' '.join(diff_command)
        return 0
    else:
        verbose(' '.join(diff_command))
        return call(diff_command)
