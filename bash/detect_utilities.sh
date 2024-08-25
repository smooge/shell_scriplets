#!/bin/bash
#
# Author: Stephen Smoogen
# License: BSD 2-clause
#
# The following scriplet is useful for detecting what applications are
# available for use. 
#
# It assumes:
# * bash >= 3.2.57

PATH=/usr/bin:/bin

NEEDED_APPS=(
    ls
    which
    bash
    tcsh
)

# This function would be used to call various other cleanup routines as needed.
# Basic function is just to return 0.
function cleanup(){
    return 0
}

# Basic failure routine which just prints ARG1 and passed ARG2 to cleanup
function failure(){
    echo $1
    cleanup $2
    exit 1
}

# This will roll through a list of applications expected to be called
# in the program and should be in the path. This should go before
# setting any path variables 
function detect_apps(){
    local BAD=0
    for A in ${NEEDED_APPS[*]}; do
	type -P ${A}
	if [[ $? -ne 0 ]]; then
	    echo "${A} not found in path. Manual correction may be needed"
	    BAD=1
	fi
    done
    failure "Failure to find needed applications. Exiting." "Doing nothing"
}

## Basic Main to put items in and allow for easier search of things.
function main(){
    detect_apps
}

main
