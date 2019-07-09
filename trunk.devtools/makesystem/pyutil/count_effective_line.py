import re

non_effective_line_re = r"^\s*([{}]?\s*$|#|//)"

def count_effective_line(filename):
    text = open(filename).read()
    text = re.sub("(?s)/\*.*?\*/", "", text)
    effective_line_count = 0
    for line in text.splitlines():
        if re.match(non_effective_line_re, line):
            continue
        effective_line_count += 1
    return effective_line_count
