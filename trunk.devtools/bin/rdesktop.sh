#!/bin/bash

if [ -z "$COREID" ]
then
    echo You need to set the environment variable COREID to your motorola CoreId
    echo by adding the line export COREID=thecoreid to ~/.bash_profile
    echo -n "Enter your core id: "
    read -e COREID
fi
exec esddsp rdesktop -u $COREID -d ARRS -k sv -g workarea -D -T Windows -a 16\
     -r disk:extra=/extra -r disk:$USER=/home/$USER -r sound:local\
     zse18trm04.arrs.arrisi.com
