#!/bin/bash

error=0
for test in $(ls test*before*); do
    if grep DISABLED &>/dev/null $test; then
        printf "Skipping disabled test '${test/_before.cpp/}': "
        grep DISABLED $test | cut -d':' -f2
        continue
    fi
    errmsg=$(diff -U2 --label "EXPECTED" ${test/before/after} --label "ACTUAL" <(../../bin/kreatv-uncrustify $test))
    if [ -n "$errmsg" ]; then
        echo "------------------------"
        echo -e "Error in ${test/_before/}:"
        echo "------------------------"
        echo -e "$errmsg"
        error=$(( $error + 1 ))
    fi
done

if [ $error -gt 0 ]; then
    echo "Failure: $error errors" >&2
    exit 1
else
    echo "Success"
fi
