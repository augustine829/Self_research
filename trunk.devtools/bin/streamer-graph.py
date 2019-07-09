#!/bin/env python
"""
This script parses a log file with streamer debug lines
and draws an element graph using dot. Use like this, for example:

logclient -l all $STBIP | streamer-graph.py > streamer.dot
# Make your zap now and press ctrl-C to interrupt the log client
dot streamer.dot -Txlib
"""

import fileinput
import re

# An element selection line from the streamer looks like this:
# streamer(313) Debug: Connecting "MPEG-2/Transport Stream" pad [Framing]-->[TS
# Continuity Counter]
padline = re.compile(
    ".*streamer\(.*\) Debug: Connecting \"(.*)\" pad *\[(.*)\]-->\[(.*)\]")
linkline = re.compile(
    ".*streamer\(.*\) Debug: Connecting \"(.*)\" link *\[(.*)\] - \[(.*)\]")
terminator_count = 0

print "digraph pipeline {"
print "  rankdir=TB;"
print "  node [shape=box];"
print "  node [fontsize=10];"
print "  edge [fontsize=8];"

try:
    for line in fileinput.input(inplace=True):
        result = padline.match(line)
        if result:
            (pad, first, second) = result.groups()
            if second != "Terminator":
                print '  "%s" -> "%s" [label="%s"];' % (first, second, pad)
            else:
                print '  t%d [style=invis]' % terminator_count
                print ('  "%s" -> t%d [arrowhead=tee];'
                       % (first, terminator_count))
                terminator_count += 1
        result = linkline.match(line)
        if result:
            (pad, first, second) = result.groups()
            print ('  "%s" -> "%s" [label="%s", style=dotted, dir=none];'
                   % (first, second, pad))
except KeyboardInterrupt:
    pass

print "}"
