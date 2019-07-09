import re

from glob import glob
from operator import itemgetter
from os.path import isdir, join
from sys import stderr, stdin

from common import error, prompt_user, usage_error
from serverapi import ResourceConflict, ResourceNotFound


def arity(min_num, max_num=None):
    """
    Decorator that verifies number of arguments and makes optional arguments
    default to None. On an unexpected arity, a UsageError exception is raised.

    Parameters:
      min_num -- Lower bound.
      max_num -- Upper bound. If None, same as min_num.
    """

    def decorator(func):
        def inner(self, *args):
            lower = min_num
            upper = lower if max_num is None else max_num
            if not (lower <= len(args) <= upper):
                message = "subcommand expects "
                if upper == lower:
                    message += "{0} argument{1}".format(
                        lower,
                        "" if lower == 1 else "s")
                else:
                    message += "between {0} and {1} arguments".format(
                        lower, upper)
                usage_error(message)
            # Set missing arguments to None
            args = list(args) + [None] * (upper - len(args))
            return func(self, *args)
        return inner
    return decorator


def create_id_to_item_map(item):
    return dict((x["id"], x) for x in item)


def create_mapping_regexps(mappings):
    result = []
    for mapping in mappings:
        regexp = create_regexp_from_pattern(mapping["pattern"])
        result.append((mapping, regexp))
    return result


def create_pattern_from_url(url):
    m = re.match("^.*?://[^/]+/(?P<repo>[^/]+)/(?P<tail>.*)$", url)
    assert m
    return ":".join(m.group("repo", "tail"))


def create_regexp_from_pattern(pattern):
    regexp = "^" + re.escape(pattern) + "$"
    regexp = regexp.replace(r"\*", ".*")
    regexp = regexp.replace("ANYBRANCH", "(trunk|branches/[^/]+)")
    return re.compile(regexp)


def is_affirmative(answer):
    return answer.lower().startswith("y")


def sanitize_base_path(base_path):
    if base_path is None:
        base_path = "."
    return base_path.rstrip("/")


class CommandExecutor:
    def __init__(self, server, svn, output_fp):
        self._server = server
        self._svn = svn
        self._output_fp = output_fp

    #
    # Commands
    #

    @arity(3)
    def cmd_add(self, pattern, group_name, triggers_katt2):
        triggers_katt2 = triggers_katt2.strip().lower()
        if triggers_katt2 not in ["true", "false"]:
            usage_error("TRIGGERS_KATT2 argument should be true or false.")
        pattern = self._guess_and_verify_pattern(pattern)
        group = self._get_group_by_name(group_name)
        self._add_mapping(pattern, group, triggers_katt2)

    @arity(1)
    def cmd_clone(self, mapping_id):
        old_mapping, old_group, new_mapping, new_group = \
            self._ask_for_mapping_details(mapping_id)
        self._add_mapping(new_mapping["pattern"],
                          new_group,
                          new_mapping["triggers_katt2"])

    @arity(1)
    def cmd_delete(self, mapping_id):
        mapping = self._get_mapping_by_id(mapping_id)
        group = self._server.get_group_by_id(mapping["group_id"])
        self._output("Mapping to delete:\n")
        self._output("Pattern: {0}".format(mapping["pattern"]))
        self._output("Group: {0}".format(group["name"]))
        self._output("Triggers KATT2: {0}\n".format(mapping["triggers_katt2"]))
        answer = prompt_user(
            "Are you sure you want to remove this mapping [y/n]?")
        do_delete = is_affirmative(answer)
        if do_delete:
            self._server.delete_mapping(mapping_id)
        self._output("Mapping {0}{1} deleted.".format(
            mapping_id,
            "" if do_delete else " not"))

    @arity(1)
    def cmd_edit(self, mapping_id):
        old_mapping, old_group, new_mapping, new_group = \
            self._ask_for_mapping_details(mapping_id)
        if new_mapping == old_mapping and new_group == old_group:
            self._output("No changes were saved.")
        else:
            try:
                self._server.update_mapping(new_mapping)
            except ResourceConflict:
                error("Mapping {0} -> {1} already exists".format(
                    new_mapping["pattern"], new_group["name"]))
            self._output("Changes to mapping {0} saved.".format(mapping_id))
            self._print_hint_about_testing_pattern(mapping_id)

    @arity(0, 1)
    def cmd_find_orphans(self, base_path):
        base_path = sanitize_base_path(base_path)
        mappings = self._server.get_mappings()
        mappings_and_regexps = create_mapping_regexps(mappings)
        paths = self._svn.get_wc_files_under_path(base_path)
        patternish_paths = self._get_patternish_paths(base_path, paths)
        unmatched_paths = set(paths)
        for i, (patternish_path, path) in enumerate(
                patternish_paths.iteritems(), 1):
            if (i - 1) % 11 == 0 or i == len(patternish_paths):
                # Don't print progress too often since the time it takes isn't
                # negligible.
                self._tty_output(
                    "\rChecking file {0}/{1}...".format(i, len(paths)),
                    False)
                self._tty_flush()
            for mapping, regexp in mappings_and_regexps:
                if regexp.match(patternish_path):
                    unmatched_paths.remove(path)
                    break
        self._tty_output("")
        if unmatched_paths:
            self._tty_output("Unmatched files:")
            for path in sorted(unmatched_paths):
                self._output(path)
        else:
            self._tty_output("No unmatched files.")

    @arity(1)
    def cmd_group_add(self, name):
        try:
            self._server.add_group(name)
            self._output("Group {0} added. Make sure that the group exists in"
                         " Review Board too.".format(name))
        except ResourceConflict:
            error("Group {0} already exists".format(name))

    @arity(1)
    def cmd_group_delete(self, name):
        group = self._get_group_by_name(name)
        try:
            self._server.delete_group(group["id"])
            self._output("Group {0} deleted.".format(name))
        except ResourceConflict:
            error('Cannot delete group {0} since it is still referenced by at'
                  ' least one mapping (see "codemapper list {0}"). Maybe you'
                  ' want to rename or merge the group instead? You can also'
                  ' remove the mapping(s) or edit them to use another group.'
                  .format(name))

    @arity(0)
    def cmd_group_list(self):
        groups = self._server.get_groups()
        groups.sort(key=itemgetter("name"))
        for group in groups:
            self._output(group["name"])

    @arity(2)
    def cmd_group_merge(self, name1, name2):
        self._output("This will:\n")
        self._output("* Transfer {0}'s mappings to {1}.".format(name1, name2))
        self._output("* Delete {0}.\n".format(name1))
        answer = prompt_user(
            "Are you sure you want to merge {0} into {1} [y/n]?".format(
                name1, name2))
        if is_affirmative(answer):
            self._merge_groups(name1, name2)
            self._output("Group {0} merged into {1}.".format(name1, name2))
        else:
            self._output("No changes were made.")

    @arity(2)
    def cmd_group_rename(self, name, new_name):
        try:
            group = self._get_group_by_name(name)
            group["name"] = new_name
            self._server.update_group(group)
            self._output(
                "Group {0} renamed to {1}. Make sure that the group is renamed"
                " in Review Board too.".format(name, new_name))
        except ResourceConflict:
            error("Group {0} already exists".format(new_name))

    @arity(1)
    def cmd_ignore(self, pattern):
        self.cmd_add(pattern, "Ignored", "false")

    @arity(1)
    def cmd_info(self, mapping_id):
        mapping = self._get_mapping_by_id(mapping_id)
        group = self._server.get_group_by_id(mapping["group_id"])
        self._print_mapping(mapping, group["name"],
                            mapping["triggers_katt2"] == "true")

    @arity(0, 1)
    def cmd_list(self, group_name):
        if group_name is None:
            mappings = self._server.get_mappings()
        else:
            group = self._get_group_by_name(group_name)
            mappings = self._server.get_mappings_by_group(group["id"])
        self._print_mappings(mappings, self._server.get_groups())

    @arity(0, 1)
    def cmd_map(self, base_path):
        base_path = sanitize_base_path(base_path)
        paths = self._svn.get_wc_files_under_path(base_path)
        patternish_paths = self._get_patternish_paths(base_path, paths)
        self._map_paths(patternish_paths)

    @arity(0, 1)
    def cmd_map_diff(self, path):
        if path is None:
            if stdin.isatty():
                usage_error("please pipe a diff into \"codemapper map-diff\","
                            " or provide a path to a .diff/.patch file")
            diff_fp = stdin
        else:
            diff_fp = open(path)
        patternish_paths = self._get_patternish_paths_from_diff(diff_fp)
        self._map_paths(patternish_paths)

    @arity(1, 2)
    def cmd_test(self, mapping_id, base_path):
        base_path = sanitize_base_path(base_path)
        mapping = self._get_mapping_by_id(mapping_id)
        paths = self._svn.get_wc_files_under_path(base_path)
        patternish_paths = self._get_patternish_paths(base_path, paths)
        matching_paths = []
        regexp = create_regexp_from_pattern(mapping["pattern"])
        for patternish_path, path in patternish_paths.iteritems():
            if regexp.match(patternish_path):
                matching_paths.append(path)
        matching_paths.sort()
        for path in matching_paths:
            self._output(path)

    #
    # Command aliases
    #

    cmd_del = cmd_delete
    cmd_fo = cmd_find_orphans
    cmd_ga = cmd_group_add
    cmd_gd = cmd_group_delete
    cmd_gl = cmd_group_list
    cmd_gm = cmd_group_merge
    cmd_gr = cmd_group_rename
    cmd_ls = cmd_list
    cmd_md = cmd_map_diff

    #
    # Internals
    #

    def _add_mapping(self, pattern, group, triggers_katt2):
        try:
            mapping = self._server.add_mapping(pattern, group["id"],
                                               triggers_katt2)
        except ResourceConflict:
            error("Mapping {0} -> {1} already exists".format(pattern,
                                                             group["name"]))
        if group["name"] == "Ignored":
            self._output("Ignoring {0} (ID: {1}).".format(
                pattern, mapping["id"]))
        else:
            self._output(
                "Mapped pattern {0} to group {1} (ID: {2}).".format(
                    pattern, group["name"], mapping["id"]))
        self._print_hint_about_testing_pattern(mapping["id"])

    def _ask_for_mapping_details(self, mapping_id):
        old_mapping = self._get_mapping_by_id(mapping_id)
        old_group = self._server.get_group_by_id(old_mapping["group_id"])
        new_pattern = prompt_user("Pattern:", old_mapping["pattern"])
        new_pattern = self._guess_and_verify_pattern(new_pattern)
        new_group_name = prompt_user("Group:", old_group["name"])
        new_group = self._get_group_by_name(new_group_name)
        while True:
            new_triggers_katt2 = prompt_user(
                "Triggers KATT2:",
                old_mapping["triggers_katt2"]).strip().lower()
            if new_triggers_katt2 in ["true", "false"]:
                break
            print "Invalid value. Expected true or false."
        new_mapping = old_mapping.copy()
        new_mapping["pattern"] = new_pattern
        new_mapping["group_id"] = new_group["id"]
        new_mapping["triggers_katt2"] = new_triggers_katt2
        return old_mapping, old_group, new_mapping, new_group

    def _get_group_by_name(self, name):
        try:
            return self._server.get_group_by_name(name)
        except ResourceNotFound:
            error("Group {0} does not exist".format(name))

    def _get_mapping_by_id(self, id):
        try:
            return self._server.get_mapping_by_id(id)
        except ResourceNotFound:
            error("Mapping {0} does not exist".format(id))

    def _get_path_info(self, path):
        path_info = self._svn.get_wc_path_info(path)
        if not path_info:
            error("file or directory not known to SVN: {0}".format(path))
        return path_info

    def _get_patternish_paths(self, base_path, paths):
        # "patternish path" here means a path rewritten to a form that can be
        # matched to a mapping's pattern, for instance
        # "dev:project/branches/DEV_branch/foo/bar".
        patternish_paths = {}
        base_path_info = self._get_path_info(base_path)
        patternish_base_path = create_pattern_from_url(base_path_info.url)
        for path in paths:
            adjusted_path = path
            if base_path != ".":
                adjusted_path = path[len(base_path) + 1:]
            if adjusted_path:
                patternish_path = join(patternish_base_path, adjusted_path)
            else:
                patternish_path = patternish_base_path
            patternish_paths[patternish_path] = path
        return patternish_paths

    def _get_patternish_paths_from_diff(self, diff_fp):
        patternish_paths = set()
        for line in diff_fp:
            m = re.match(r"[AMD] {7}(?P<path_or_url>\S+)", line)
            if m:
                path_or_url = m.group("path_or_url")
                if path_or_url.startswith("http://"):
                    patternish_paths.add(create_pattern_from_url(path_or_url))
                    continue
                else:
                    path = path_or_url
            else:
                m = re.match(
                    r"\+\+\+ (?P<path>\S+)(\s*\((?P<context>[^)]+)\))?",
                    line)
                if not m:
                    continue
                path, context = m.group("path", "context")
                if context and "working copy" not in context:
                    error("cannot recognize the origin of the diff, please"
                          " pass the --summarize option to svn and try again")
            path_info = self._svn.get_wc_path_info(path)
            if path_info is None:
                error(
                    "the diff/patch modifies the file \"{0}\", which does not"
                    " exist relative to the current working directory (make"
                    " sure you are located in the directory in which the diff"
                    " was created)".format(path))
            patternish_paths.add(
                self._get_patternish_paths(".", [path]).keys()[0])
        return patternish_paths

    def _guess_and_verify_pattern(self, pattern):
        pattern = self._guess_pattern(pattern)
        self._verify_pattern(pattern)
        return pattern

    def _guess_pattern(self, pattern, ask_for_confirmation=True):
        pattern = pattern.rstrip("/")

        svn_base_url = self._svn.get_base_url()
        m = re.match(
            "{0}/(?P<repo>[^/]+)/(?P<path>.*)".format(re.escape(svn_base_url)),
            pattern)
        if m:
            # The pattern is in URL form.
            return ":".join(m.group("repo", "path"))

        if ":" in pattern:
            # The pattern is fully specified already.
            return pattern

        local_matches = glob(pattern)
        if not local_matches:
            self._output(
                "The pattern does not match a local file or directory -"
                " assuming that it refers to a project in the repository.\n")
            return "dev:" + pattern

        # It's a local pattern.
        if isdir(pattern):
            pattern += "/*"
        wc_info = self._svn.get_wc_path_info(".")
        if not wc_info:
            error("Could not deduce SVN URL from working copy info")

        guessed_pattern = "{0}:{1}/ANYBRANCH/{2}/{3}".format(
            wc_info.repository,
            wc_info.project,
            wc_info.path_in_wc,
            pattern)
        guessed_pattern = re.sub(r"/+", "/", guessed_pattern)
        guessed_pattern = re.sub(r"/(\./)+", "/", guessed_pattern)
        guessed_pattern = re.sub(r"(/\*)+", "/*", guessed_pattern)

        self._output(
            "The pattern matches local files and/or directories - assuming"
            " that it refers to a local path.")
        self._output("\nGuessed full pattern: {0}\n".format(guessed_pattern))
        if ask_for_confirmation:
            answer = prompt_user(
                "OK to use {0} as the pattern [y/n]?".format(
                    guessed_pattern))
            if not is_affirmative(answer):
                error("Creation of mapping cancelled")
        return guessed_pattern

    def _map_paths(self, patternish_paths):
        mappings = self._server.get_mappings()
        mappings_and_regexps = create_mapping_regexps(mappings)
        matching_mapping_ids = set()
        for i, (mapping, regexp) in enumerate(mappings_and_regexps, 1):
            self._tty_output(
                "\rMapping pattern {0}/{1}...".format(i, len(mappings)),
                False)
            self._tty_flush()
            for patternish_path in patternish_paths:
                if regexp.match(patternish_path):
                    matching_mapping_ids.add(mapping["id"])
                    break
        self._tty_output("")
        mappings = [x for x in mappings if x["id"] in matching_mapping_ids]
        if mappings:
            self._tty_output("Matching mappings:")
            groups = self._server.get_groups()
            self._print_mappings(mappings, groups)
        else:
            self._tty_output("No mappings matched.")

    def _merge_groups(self, name1, name2):
        group1 = self._get_group_by_name(name1)
        group2 = self._get_group_by_name(name2)
        group1_mappings = self._server.get_mappings_by_group(group1["id"])
        for mapping in group1_mappings:
            mapping["group_id"] = group2["id"]
            self._server.update_mapping(mapping)
        self._server.delete_group(group1["id"])

    def _output(self, message, print_newline=True):
        if print_newline:
            message += "\n"
        self._output_fp.write(message)

    def _print_hint_about_testing_pattern(self, mapping_id):
        self._output(
            "Consider testing the mapping by running the following command in"
            " a working copy:\n\n    codemapper test {0}".format(mapping_id))

    def _print_mapping(self, mapping, group_name, show_triggers_katt2_width,
                       id_width=1, pattern_width=1):
        if show_triggers_katt2_width:
            tk2_text = (", triggers KATT2"
                        if mapping["triggers_katt2"] == "true" else "")
            tk2_width = "16"
        else:
            tk2_text, tk2_width = "", "0"

        self._output("[id: {0:>{1}}{2:>{3}}] {4:{5}} -> {6}".format(
            mapping["id"], id_width,
            tk2_text, tk2_width,
            mapping["pattern"], pattern_width,
            group_name))

    def _print_mappings(self, mappings, groups):
        if not mappings:
            return
        group_map = create_id_to_item_map(groups)
        mappings.sort(key=itemgetter("pattern"))
        id_width = max(len(x["id"]) for x in mappings)
        pattern_width = max(len(x["pattern"]) for x in mappings)
        show_tk2_width = any(
            mapping["triggers_katt2"] == "true" for mapping in mappings)
        for mapping in mappings:
            group_name = group_map[mapping["group_id"]]["name"]
            self._print_mapping(mapping, group_name, show_tk2_width, id_width,
                                pattern_width)

    def _tty_flush(self):
        if stderr.isatty():
            stderr.flush()

    def _tty_output(self, message, print_newline=True):
        if stderr.isatty():
            if print_newline:
                message += "\n"
            stderr.write(message)

    def _verify_pattern(self, pattern):
        if not pattern:
            error("Empty pattern not allowed")
        repo, _, path = pattern.partition(":")
        if not path:
            error("Empty path in pattern not allowed")
        if "/" in repo:
            error("Slash not allowed in repository part of pattern")
        static_part_of_path = path.partition("*")[0].partition("ANYBRANCH")[0]
        url_to_check = self._svn.get_url(repo, static_part_of_path)
        if not self._svn.path_exists_in_repo(url_to_check):
            error("The path \"{0}\" does not exist in the {1} repository (URL:"
                  " {2})".format(static_part_of_path, repo, url_to_check))
