#!/bin/bash

# Development script used to test local modifications to uncrustify fast

# See log_levels.h for the different log levels of uncrustify
debuglevels="31,21,52"

if [ -z "$1" ]; then
    echo "Specify test" 1>&2
    exit 1
else
    testtorun="$1"
fi

make -C ../../3pp/uncrustify/uncrustify-0.60/ && cp ../../3pp/uncrustify/uncrustify-0.60/src/uncrustify ../../3pp/uncrustify/uncrustify_prebuilt && ../../3pp/uncrustify/uncrustify_prebuilt -c ../../etc/kreatv-uncrustify.conf -L${debuglevels} ${testtorun}_before.cpp && cat ${testtorun}_before.cpp.uncrustify && rm ${testtorun}_before.cpp.uncrustify
