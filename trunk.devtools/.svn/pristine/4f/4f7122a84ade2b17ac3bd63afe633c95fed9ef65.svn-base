#!/bin/bash
#
# Copyright (c) 2013 ARRIS Group, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Group, Inc. (ARRIS),
# and may not be copied, reproduced, modified, disclosed to others, published
# or used, in whole or in part, without the express prior written permission
# of ARRIS.
#
# This script will:
#    * help you to create the backtrace crash report. It uses the existing
#      scripts launch-parse-backtrace.pl, create-objdump to generate 
#      the fatal error report.
#
# External dependencies:
#    * svn and other tools
#    * Installed toolchains
#

# imports
export OBJDUMP

# Variables
SCRIPTS=/extra/scripts/trunk/bin
ROOT_DIR=/extra/crash

# Functions
prepareDirs() 
{
	let "direntries=${#dirlist[@]}"
	let "direntries = direntries - 1"
	for (( index=0; index<${direntries}; index++ ));
	do
                if [ ! -d "${dirlist[$index]}" ]; then
                        mkdir ${dirlist[$index]}
                fi
	done
}

cleanDirs()
{
        if [ -d "$ROOTDISK_DIR" ]; then
        	echo "Do you want to remove the rootdisk(y/n): "
	        read removerootdisk
		if [[ $removerootdisk == "y" ]]
		then
	                sudo rm -rf $ROOTDISK_DIR
	        fi
	fi

        let "direntries=${#dirlist[@]}"
        let "direntries = direntries - 1"
        for (( index=0; index<${direntries}; index++ ));
        do
                if [ -d "${dirlist[$index]}" ]; then
                        rm -rf ${dirlist[$index]}
                fi
        done
}

selectToolChain()
{
        toolchain_dir=$(ls /usr/local/motorola/toolchain/bcm45/)
        echo "Currently installed ToolChain(s): "
        echo "$toolchain_dir"
	echo "Enter your option: "
        read toolchain
        export OBJDUMP=/usr/local/motorola/toolchain/bcm45/$toolchain/bin/mipsel-motorola-linux-uclibc-objdump
        if [ ! -d "/usr/local/motorola/toolchain/bcm45/$toolchain" ]; then
                echo "Incorrect input. Invalid ToolChain. $OBJDUMP"
                exit 0
        fi
}

createFatalErrorReport()
{
	perl launch-parse-backtrace.pl $BACKTRACE_DIR $OBJDUMP_DIR

	for objfile in $BACKTRACE_DIR/*.obj;
	do
	        echo "Obj File: $objfile"
	        $(./create-objdump $ROOTDISK_DIR $OBJDUMP_DIR $objfile)
	        perl launch-parse-backtrace.pl $BACKTRACE_DIR $OBJDUMP_DIR
	done
}

findRootDisk()
{
	if [ -d "$ROOT_DIR/rootdisk" ];
	then
		echo "found rootdisk"
	else 
        	rootdiskimg=$(ls kreatv-rootdisk*)
		if [[ $rootdiskimg != "" ]]
        	then
			echo "found rootdisk img $rootdiskimg"
			$(sudo tar -xvzf $rootdiskimg)
        	else
        		echo "Unable to find ROOTDISK image in root work space dir." 
			echo "Provide the path of the rootdisk dir: "
		        read rootdiskdir
		        ROOTDISK_DIR=$rootdiskdir
		        if [[ $rootdiskdir != "" ]]
		        then
		                if [ ! -d "$rootdiskdir" ]; then
	        	                echo "No such directory exists. Quiting..."
		                        exit 0
	                	fi
	        	else
        	        	echo "Error!!!. Incorrent input. Quiting..."
                		exit 0
	        	fi
		fi
	fi
}


# =========== Script ENTRY ===========

echo "Enter the root directory of the work space: "
read root_dir
if [[ $root_dir == "" ]]
then
	echo "Chosen default path: $ROOT_DIR"
else
	ROOT_DIR=$root_dir
fi

if [ ! -d "$ROOT_DIR" ]; then
	echo "ERROR. Root folder $ROOT_DIR doesn't exist."
	exit 0
fi

BACKTRACE_DIR=$ROOT_DIR/backtrace
ROOTDISK_DIR=$ROOT_DIR/rootdisk
OBJDUMP_DIR=$ROOT_DIR/objdump

declare -a dirlist=($BACKTRACE_DIR $OBJDUMP_DIR $ROOTDISK_DIR)

if [[ "$1" == "clean" ]]; then
	cleanDirs
	exit 0
fi

if [[ $OBJDUMP == "" ]]
then
        echo "Warning: OBJDUMP path is not set by you. Select a tool chain:"
	selectToolChain
else
	echo "Note: Verify the OBJDUMP path $OBJDUMP." 
	echo "Are you ok with the toolchain (y/n). Press n to select a toolchain: "
        read pressanykey
        if [ "$pressanykey" == "n" ]
        then
                selectToolChain
        fi

        # Check whether the file exists.
        if [ ! -f $OBJDUMP ]; then
                echo "Incorrect path. Relevant file/directory doesn't exists. $OBJDUMP"
                exit 0
        fi
fi

prepareDirs

echo "Enter the location of the Tools directory: "
read toolsdir
if [[ $toolsdir == "" ]]
then
	echo "Chosen default path: $SCRIPTS"
else
	if [ ! -d "$toolsdir" ]; then
		echo "ERROR!!!. Directory $toolsdir doesn't exists."
		exit 0
	fi
	SCRIPTS=$toolsdir
fi

cd $ROOT_DIR

BACKTRACE_FILES=$(ls backtrace.*)
if [[ $BACKTRACE_FILES == "" ]]
then
	echo "No backtrace file found. Quiting..."
else
	for backtracefile in $BACKTRACE_FILES
	do
		file_extn=$(echo $backtracefile | awk -F . '{print $NF}')
	        if [ $file_extn == 'gz' ]
		then
			echo "Found gz backtrace file. $backtracefile."
			gzipfile=$(echo $backtracefile | cut -d'.' -f1-5)
			gunzip -c $backtracefile > $gzipfile
			mv $gzipfile $BACKTRACE_DIR
		else
			echo "Found backtrace file. $backtracefile."
			cp $backtracefile $BACKTRACE_DIR
	        fi
	done
fi

findRootDisk

cd $SCRIPTS
createFatalErrorReport
