import sys

from errno import EPIPE
from optparse import OptionParser
from os import mkdir
from os.path import dirname, expanduser, isdir
from urllib import urlencode
from urllib2 import urlopen

from commandexecutor import CommandExecutor
from common import error, ExecutionError, prompt_user, usage_error, UsageError
from serverapi import ServerApi
from svnapi import SvnApi

CONFIG_FILE = expanduser("~/.config/codemapper.conf")

BUILDUSER_API_URL = "http://svn.arrisi.com/builduser_remote.php"
CODEMAPPING_API_URL = "http://svn.arrisi.com/codemapping_remote.php/api/v1/"
SVN_BASE_URL = "http://svn.arrisi.com"


def read_config():
    config = {}
    try:
        execfile(CONFIG_FILE, {}, config)
    except IOError:
        pass
    return config


def write_config(config):
    if not isdir(dirname(CONFIG_FILE)):
        mkdir(dirname(CONFIG_FILE))
    with open(CONFIG_FILE, "w") as fp:
        for key, value in config.items():
            fp.write("{0} = {1!r}\n".format(key, value))


class UsernameProvider:
    def __init__(self, explicit_username):
        self._explicit_username = explicit_username

    def get_username(self):
        if self._explicit_username:
            return self._explicit_username

        config = read_config()
        if "username" in config:
            return config["username"]

        username = prompt_user(
            "Please provide your {0} username:".format(SVN_BASE_URL))
        parameters = urlencode({"action": "get_user", "coreid": username})
        response = urlopen(BUILDUSER_API_URL + "?" + parameters)
        if response.getcode() != 200 or response.read() == "null":
            error("No such username: {0}".format(username))
        config["username"] = username
        write_config(config)
        print "Username saved in {0}".format(CONFIG_FILE)
        return username


def main(usage):
    if getattr(sys.stdout, "encoding", None) != "UTF-8":
        usage = usage.replace(u"\xaf", u"-")
    parser = OptionParser(usage=usage)
    parser.add_option(
        "--username",
        help="specify SVN username to use when modifying groups or mappings")
    options, args = parser.parse_args()
    if not args or args[0] == "help":
        parser.print_help()
        return 0
    command = args[0]
    command_args = args[1:]

    username_provider = UsernameProvider(options.username)
    server = ServerApi(CODEMAPPING_API_URL, username_provider)
    svn = SvnApi(SVN_BASE_URL)
    command_executor = CommandExecutor(server, svn, sys.stdout)
    command_handler = getattr(command_executor,
                              "cmd_" + command.replace("-", "_"),
                              None)
    try:
        if command_handler is None:
            usage_error("unknown subcommand: {0}".format(command))
        command_handler(*command_args)
        return 0
    except (ExecutionError, UsageError, IOError) as e:
        if isinstance(e, IOError) and e.errno == EPIPE:
            return 1
        if isinstance(e, UsageError):
            parser.print_help()
            sys.stderr.write("\n")
        sys.stderr.write("codemapper: error: {0}\n".format(e))
        return 1
