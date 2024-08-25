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

NEEDED_RPMS=(
    coreutils
    kernel
    dnf
    yum
)

NEEDED_APPS=(
    rpm
    arch
    uname
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
	type -P ${A} &> /dev/null
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
    if [[ -f /etc/os-release ]]; then
	# import the variables for usage. if this goes wrong lots of
	# stuff is already bad. 
	source /etc/os-release
	DISTRO="${ID}"
	DISTRO_VERSION="${VERSION_ID}"
    elif [[ -f /usr/lib/os-release ]]; then
	# import the variables for usage. if this goes wrong lots of
	# stuff is already bad.
	source /usr/lib/lsb-release
	DISTRO="${ID}"
	DISTRO_VERSION="${VERSION_ID}"
    elif [[ -f /etc/lsb-release  ]]; then
	LSB=$(type -P lsb_release )
	if [[ $? -ne 0 ]]; then
	    DISTRO="unknown_linux"
	    DISTRO_VERSION="0"
	fi
	DISTRO="$( ${LSB} -i | awk '{print tolower($NF)}' )"
	DISTRO_VERSION="$( ${LSB} -r | awk '{print $NF}' )"
    else
	DISTRO="unknown_linux"
	DISTRO_VERSION="0"
    fi
}

function detect_distribution_mac(){
    # The simplest way to get the type of OS is via uname
    DISTRO=$( uname -s )
    DISTRO_VERSION=$( uname -r )
}

# This may be a short and sweet here, but you may need to choose a
# standard name 
function detect_arch(){
    ARCH=$( arch )
}

# This goes through the OS lists and set that.
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
	    DISTRO="unknown"
	    DISTRO_VERSION="0"
	    ;;
    esac

}


function detect_rpms(){
    BAD=0
    RPM=$( type -P rpm )
    for R in ${NEEDED_RPMS}; do
	${RPM} -q ${R} &> /dev/null
	if [[ $? -ne 0 ]]; then
            echo "${R} not installed. Please check README on needed repositories."
            BAD=1
	fi
    done
    if [[ ${BAD} -ne 0 ]]; then
	failure "Missing packages. Exiting"
    fi    
}

# This is meant to test the tooling 
function main(){
    detect_apps
    detect_arch
    detect_os
    if [[ ${DISTRO} == "redhat" || ${DISTRO} == "centos" || ${DISTRO} == "fedora" || ${DISTRO} == "autosd" ]]; then
        detect_rpms
    fi
    echo "My Arch is ${ARCH}"
    echo "My Distribution is ${DISTRO}"
    echo "My Distro Release is ${DISTRO_VERSION}"
    echo "My RPMS are ${NEEDED_RPMS[*]}"
}

main
