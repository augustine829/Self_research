#!/bin/bash

MAKEFILES=$(find . -name Makefile | xargs grep -L "COMPONENT_IS_3PP" | xargs grep -l "^SRCS")

count=0

tested=0
notTested=0
notSuitable=0

for makefile in $MAKEFILES
do
    count=$((count + 1))
    if grep "^NOT_SUITABLE_FOR_UNIT_TESTS" >& /dev/null $makefile
    then
        notSuitable=$((notSuitable + 1))
    else
        if grep "^TEST_TARGETS" $makefile >& /dev/null
        then
            if grep "^TEST_TARGETS" $makefile | grep "(empty)" >& /dev/null
            then
                echo "Empty TEST_TARGETS:" $makefile
                notTested=$((notTested + 1))
            else
                tested=$((tested + 1))
            fi
        else
            echo "*** Makefile without unit test info : "$makefile
        fi
    fi
done
echo "---------------------------------"
echo "Tested:" $tested
echo "Empty TEST_TARGETS: " $notTested
echo "Not suitable:" $notSuitable
echo "---------------------------------"
echo "Total:" $count
