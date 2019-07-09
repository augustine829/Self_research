#!/bin/bash

# might have called gnome-terminal directly to run stuff,
# but if you give it the -x or -e option, it quits after
# running the command -- so, we'll call this script with
# the -x option so we can have a "pause" to see the results
# of running the script

echo "\$PWD = $PWD"
echo -e "\$@ = $@\n"
$@
read -p "press enter key to exit"
