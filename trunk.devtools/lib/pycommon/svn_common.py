import os
from os.path import dirname, join, realpath
from common import error, run_command, ping_in_millisec

REMOTESVN = realpath(join(dirname(__file__), '..', '..', 'bin', 'remotesvn'))

REMOTESVN_ENABLED = False
SVN_AUTH = None

PING_HOST = "svn.arrisi.com"
PING_THRESHOLD_MILLISEC = 40


def run_svn_command(svn_command, svn_auth=None):
    global REMOTESVN_ENABLED
    global SVN_AUTH
    if REMOTESVN_ENABLED and svn_command[1] == 'diff':
        svn_command[0] = REMOTESVN
    if svn_auth is None:
        insert_svn_authentication(svn_command, SVN_AUTH, 2)
    else:
        insert_svn_authentication(svn_command, svn_auth, 2)
    error_code, output = run_command(svn_command)
    if error_code != 0:
        error('command "%s" failed' % ' '.join(svn_command))
    else:
        return output


class SvnAuth(object):
    def __init__(self, username=None, password=None):
        self._username = username
        self._password = password

    @property
    def username(self):
        return self._username

    @property
    def password(self):
        return self._password


class SvnPathInfo:
    """Represents the information provided by an 'svn info ...' command"""

    # Public properties are derived from these keys (e.g. Repository Root -->
    # self.repository_root). NOTE: some keys may be absent for some paths/URLs.
    KEYS = ['Repository Root', 'Revision', 'URL', 'Node Kind']
    KEY_VALUE_SEPARATOR = ': '

    def __init__(self, path_or_url, svn_auth=None):
        self._svn_auth = svn_auth
        self._set_defaults()
        self._update_info(path_or_url)

    def _set_defaults(self):
        for key in SvnPathInfo.KEYS:
            setattr(self, self._key_to_variable_name(key), None)

    def _key_to_variable_name(self, key):
        return key.lower().replace(' ', '_')

    def _update_info(self, path_or_url):
        svn_command = ['svn', 'info', path_or_url]
        svn_info_output = run_svn_command(svn_command, self._svn_auth)
        for line in svn_info_output.split('\n'):
            for key in SvnPathInfo.KEYS:
                if line.startswith('%s%s' % (key,
                                             SvnPathInfo.KEY_VALUE_SEPARATOR)):
                    value = line.partition(SvnPathInfo.KEY_VALUE_SEPARATOR)[2]
                    setattr(self, self._key_to_variable_name(key), value)

    def __str__(self):
        return '\n'.join(
            ['%s: %s' % (key, getattr(self, self._key_to_variable_name(key)))
             for key in SvnPathInfo.KEYS])


def looks_like_branch_url(url):
    if '://' not in url:
        return False

    url_components = url.rstrip('/').split('/')
    if len(url_components) >= 1 and url_components[-1] == 'trunk':
        return True
    elif (len(url_components) >= 2
          and url_components[-2] in ['branches', 'deadwood', 'tags']):
        return True
    else:
        return False


def get_branch_root(url):
    while True:
        if looks_like_branch_url(url):
            return url
        url = dirname(url)
        if url in ['', '/']:
            return None


def insert_svn_authentication(svn_command, svn_auth, position):
    if svn_auth is None:
        return
    if svn_auth.username is not None:
        svn_command[position:position] = ['--username', svn_auth.username]
    if svn_auth.password is not None:
        svn_command[position:position] = ['--password', svn_auth.password]


def verify_branch_argument(branch):
    if ('://' not in branch
            and os.system('svn info %s >/dev/null 2>&1' % branch) != 0):
        error('branch "%s" does not look like a valid URL or working copy.' %
              branch)


def should_enable_remotesvn_if_ping_is_slow():
    ping_ms = ping_in_millisec(PING_HOST)
    if ping_ms is not None and ping_ms > PING_THRESHOLD_MILLISEC:
        print '''\
Pinging %s is slow, risk is that running svn commands will take a long time. \
Enabling remotesvn...
''' % PING_HOST
        return True
    else:
        return False
