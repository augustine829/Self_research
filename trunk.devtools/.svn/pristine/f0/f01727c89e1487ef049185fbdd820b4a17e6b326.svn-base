# Copyright (c) 2014 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

import os
import re
import sys
from subprocess import Popen, PIPE, STDOUT


class ExecutionError(Exception):
    """
    Instances of this class will be caught and printed to the user as an error
    message.
    """


class UsageError(Exception):
    """
    Instances of this class will be caught and printed to the user as a
    message + reference to usage text.
    """


def error(message):
    raise ExecutionError(message)


def usage_error(message):
    raise UsageError(message)


def prompt_user(prompt, valid_answers=None, strip=True,
                ignore_case=True, default_answer=None):
    if default_answer and valid_answers:
        assert default_answer in valid_answers
    while True:
        answer = raw_input(prompt + " ")
        if strip:
            answer = answer.strip()

        if not answer:
            answer = default_answer

        if not answer:
            print "Empty value not allowed."
            continue
        elif valid_answers is None:
            return answer

        for ans in valid_answers:
            if (ignore_case and answer.lower() == ans.lower()) or \
               answer == ans:
                return ans
        else:
            print "Invalid answer"


def run_command(command, environment=None):
    process = Popen(command, stdout=PIPE, stderr=open(os.devnull, 'w'),
                    env=environment)
    output, _ = process.communicate()
    return process.returncode, output


def run_interactive_command(command, environment=None):
    process = Popen(command, stdout=PIPE, stderr=STDOUT, env=environment)

    output = ""
    while True:
        data = process.stdout.read(1)
        if not data:
            break
        output += data
        sys.stdout.write(data)
        sys.stdout.flush()

    process.wait()
    return process.returncode, output


def ping_in_millisec(host):
    command = ["ping", "-c", "1", host]
    exit_status, output = run_command(command)
    if exit_status != 0:
        return None
    for line in output.split("\n"):
        match = re.search(r"bytes from.*time=(?P<millisec>[\d.]+) ms$", line)
        if match:
            return float(match.group("millisec"))
    return None


def get_working_copy_root_path(working_path):
    path = os.path.realpath(working_path)
    if os.system("svn info %s >/dev/null 2>&1" % path) == 0:
        candidate, parent = path, os.path.join(path, '..')
        while os.system('svn info %s >/dev/null 2>&1' % parent) == 0:
            candidate, parent = parent, os.path.join(parent, '..')
        return candidate
    command = ["git", "rev-parse", "--show-toplevel"]
    exit_status, output = run_command(command)
    if exit_status == 0:
        return output.strip()
    error("path is not a working copy: %s" % working_path)
