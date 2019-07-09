import re

from collections import namedtuple
from os.path import isdir
from subprocess import Popen, PIPE

SvnWcInfo = namedtuple("SvnWcInfo", "url repository project path_in_wc")

SVN_CLIENT = "/usr/bin/svn"
SVN_URL_RE = """(?x)
    (?P<repo>[^/]+)
    /
    (?P<project>.+?)
    /
    (?P<branch>trunk|(branches|deadwood|tags)/[^/]+)
    /?
    (?P<path>.*)
"""


def run_svn(*args):
    p = Popen([SVN_CLIENT] + list(args), stdout=PIPE, stderr=PIPE)
    stdout, _ = p.communicate()
    return p.returncode, stdout


def get_url_from_svn_info(url_or_path):
    returncode, output = run_svn("info", url_or_path)
    if returncode != 0:
        return None
    m = re.search("(?m)^URL: (?P<value>.*?)$", output)
    assert m
    return m.group("value")


class SvnApi:
    def __init__(self, base_url):
        self._base_url = base_url

    def get_base_url(self):
        return self._base_url

    def get_url(self, repo, path):
        return "/".join([self._base_url, repo, path])

    def get_wc_path_info(self, path):
        url = get_url_from_svn_info(path)
        if url is None:
            return None
        base_url_suffix = url[len(self._base_url) + 1:]
        m = re.match(SVN_URL_RE, base_url_suffix)
        if m:
            return SvnWcInfo(url, *m.group("repo", "project", "path"))
        else:
            return None

    def get_wc_files_under_path(self, path):
        result = []
        _, output = run_svn("status", "-v", "--ignore-externals", path)
        for line in output.splitlines():
            m = re.match(r" *\d+ *\d+ *\S+ *(?P<path>\S+)", line)
            if m:
                path = m.group("path")
                if not isdir(path):
                    result.append(path)
        return result

    def path_exists_in_repo(self, url):
        return get_url_from_svn_info(url) is not None
