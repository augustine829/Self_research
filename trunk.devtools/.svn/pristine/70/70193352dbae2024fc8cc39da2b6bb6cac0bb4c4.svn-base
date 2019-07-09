# Copyright (c) 2016 ARRIS Enterprises, LLC. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, LLC.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

import re
import sys

from collections import namedtuple
from os.path import dirname, realpath

sys.path.insert(0, dirname(realpath(__file__)) + '/../../pycommon')

from common import ExecutionError, run_command


class Warning(Exception):
    pass


def is_inside_work_tree():
    cmd = ['git', 'rev-parse', '--is-inside-work-tree']
    rc, output = run_command(cmd)
    return rc == 0 and output.strip() == "true"


def rev_parse(refname):
    cmd = ['git', 'rev-parse', refname]
    rc, output = run_command(cmd)
    if rc != 0:
        err = ('Failed to run command "{0}"'.format(' '.join(cmd)))
        raise ExecutionError(err)

    return output.strip()


def get_git_client_version():
    cmd = ['git', '--version']
    rc, output = run_command(cmd)
    if rc != 0:
        raise ExecutionError(
            'Make sure that the git client has been installed')

    version = output.split(' ')
    if len(version) == 3:
        version = version[2]
    else:
        raise Warning('Unexpected git version format: {0}'.format(output))

    return version


def get_repo_branch_name():
    cmd = ['git', 'rev-parse', '--abbrev-ref', 'HEAD']
    rc, branch = run_command(cmd)
    if rc != 0:
        raise ExecutionError('Failed to determine the current branch.')

    return branch.strip()


def get_repo_name():
    repo = None
    url = None

    cmd = ['git', 'config', '--get', 'remote.origin.pushurl']
    rc, output = run_command(cmd)
    if rc == 0:
        url = output.strip()

    if url is None:
        cmd = ['git', 'config', '--get', 'remote.origin.url']
        rc, output = run_command(cmd)
        if rc == 0:
            url = output.strip()

    if url is not None:
        match = re.search(r'^(ssh://|).+@[^(/|:)]+(/|:)(?P<repo>.+)$', url)
        repo = match.group('repo')
    else:
        raise ExecutionError('Failed to determine the name of the repo.')

    return repo


def get_repo_top_level():
    cmd = ['git', 'rev-parse', '--show-toplevel']
    rc, toplevel = run_command(cmd)
    if rc != 0:
        raise ExecutionError('Failed to get top level of repo, are you'
                             ' standing in a working copy?')

    return toplevel.strip()


Branch = namedtuple('Branch', 'branch ref_type simplified_branch')


def branch_tuple(branch):
    if branch.startswith("refs/"):
        branch = branch[5:]
    ref_type, _, simplified_branch = branch.partition("/")
    if ref_type in ["heads", "tags", "origin"]:
        return Branch(branch, ref_type, simplified_branch)
    else:
        return Branch("heads/" + branch, "heads", branch)
