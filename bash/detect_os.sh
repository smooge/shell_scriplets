#!/bin/bash
#
# Author: Stephen Smoogen
# License: BSD 2-clause
#
# The following scriplet is useful for detecting what operating system
# and distribution the script is running on.
#
# It assumes:
# * bash >= 3.2.57
# * variables it can "export" to
OS=""
DISTRIB=""
ARCH=""

NEEDED_APPS=(
    arch
)

# Functions from other places.

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
    if [[ ${BAD} -eq 1 ]]; then
	failure "Failure to find needed applications. Exiting." "Doing nothing"
    fi
}

##

# The following works well on Fedora and downstream/related operating
# systems made after Fedora ??. 
function detect_distribution_linux(){
    # Determine if we are on a Freedesktop compliant operating system.
    # https://www.freedesktop.org/software/systemd/man/latest/os-release.html
    test -e /etc/os-release && os_release='/etc/os-release' || os_release='/usr/lib/os-release'
    if [[ $? -eq 0 ]]; then
	# import the variables for usage. if this goes wrong lots of
	# stuff is already bad. 
	source ${os_release} 
	DISTRO=${ID}
	DISTRO_VERSION=${VERSION_ID}
    elif [[ -f /etc/lsb-release ]]; then
	LSB=$(type -P lsb_release )
	if [[ $? -ne 0 ]]; then
	    failure "unable to find lsb_release. manual configuration needed"
	fi
	DISTRO=$( lsb_release -i | awk '{print tolower($NF)}' )
	DISTRO_VERSION=$( lsb_release -r | awk '{print $NF}' )
    else
	DISTRO="unknown_linux"
	DISTRO_VERSION=0
    fi
}

function detect_distribution_mac(){
    # The simplest way to get the type of OS is via uname
    DISTRO=$( uname -s )
    DISTRO_VERSION=$( uname -r )
}

function detect_os(){
    # determine if OSTYPE is properly defined. It should be because we
    # are in bash, but the world is a crazy place.
    if [[ -z ${OSTYPE} ]]; then
	failure "Unable to determine bash variable OSTYPE. Exiting"
    fi

    case ${OSTYPE} in
	darwin*)
	    detect_distribution_mac
	    ;;
	linux-gnu)
	    # we are running in a linux environment
	    detect_distribution_linux
	    ;;
    	*)
	    echo "Unable to determine OS"
	    ;;
    esac

}

# This may be a short and sweet here, but you may need to choose a
# standard name 
function detect_arch(){
    ARCH=$( arch )
}

# This is meant to test the tooling 
function main(){
    detect_apps
    detect_arch
    detect_os
    echo "My Arch is ${ARCH}"
    echo "My Distribution is ${DISTRO}"
    echo "My Distro Release is ${DISTRO_VERSON}"
}

main
