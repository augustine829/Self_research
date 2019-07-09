#!/bin/bash
TESTDIRS=$(find . -type d -name "test_*")

for test_dir in $TESTDIRS
do
    echo "---------------------------------"
    echo "Run tests in package: "$test_dir
    echo "---------------------------------"
    (cd $test_dir && ./run.sh)
    if [ $? -ne 0 ]
    then
        echo "Test Result: FAILURE"
        exit 1
    fi
    echo ""
done

echo "Test Result: All pyutil test cases passed."
