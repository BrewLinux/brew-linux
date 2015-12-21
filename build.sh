#!/bin/bash

set -e
set -o pipefail
#some hints are borrowed from Kali build.sh see http://git.kali.org/gitweb/?p=live-build-config.git;a=summary


ARCHES="amd64"
ALLOWED_ARCHES="amd64|i386"
TARGET_NAME="brew"

TARGET_DIR="brew_result"
SCP_DO=''
NO_CACHE=''

failure() {
    echo "Something went wrong" >&2
    exit 2
    }

runcommand() {
    if [ -n "$VERBOSE" ]; then
       "$@" 2>&1 | tee -a build.log
    else
	"$@" >> build.log 2>&1
    fi
    return $?
}

image_name() {
    local arch=$1
    case "$arch" in
	i386|amd64)
	    IMAGE_TPL="live-image-ARCH.hybrid.iso"
	    ;;
    esac
    echo $IMAGE_TPL | sed -e "s/ARCH/$arch/"
}

target_name() {
    local target=$1
    local arch=$2
    local tpl="TARGET-ARCH.iso"
    local tmp=$(echo $tpl | sed -e "s/TARGET/$target/")
    echo $tmp | sed -e "s/ARCH/$arch/"
}


options=$(getopt -o "a:t:sdhn" --long "arch:,target:,scp,deploy,help,nocache" -- "$@")
eval set -- "$options"

while true; do
    case "$1" in
	-a|--arch) ARCHES="$2";shift 2; ;;
	-t|--target) TARGET_NAME="$2";shift 2; ;;
	-s|--scp) SCP_DO="1";shift; ;;
	-d|--deploy) DEPLOY_DO="1";shift; ;;
	-n|--nocache) NO_CACHE="1";shift ;;
	-h|--help) cat helpme;exit 1; ;;
	--)shift; break; ;;
	*) echo "Invalid command: $1" >&2; exit 1; ;;
    esac
    
done

if [ "$(whoami)" != "root" ]; then
    echo "You are not root" >&2
    exit 1
fi

for BREW_ARCH in $ARCHES; do
    case $BREW_ARCH in
	amd64|i386)
	;;
	*)
	    echo "unsupported architecture $BREW_ARCH"
	    exit 1
	    ;;
    esac
    
done

mkdir -p $TARGET_DIR

#iterate archs
for BREW_ARCH in $ARCHES; do
    GEN_ISO="$(image_name $BREW_ARCH)"
    TARGET_ISO="$(target_name $TARGET_NAME $BREW_ARCH)"
    set +e
    : >> build.log
    if [ -n "$NO_CACHE" ];then
	echo "Be careful you do not use a cache..."
    else
	
	runcommand lb clean --purge
	[ $? -eq 0 ] || failure
    fi
    runcommand lb config -a $BREW_ARCH "$@"
    [ $? -eq 0 ] || failure

    runcommand lb build
    if [ $? -ne 0 ] || [ ! -e $GEN_ISO ]; then
	echo "build failed" >&2
	failure
    fi
    
    set -e
    mv -f $GEN_ISO $TARGET_DIR/$TARGET_ISO
    mv -f build.log $TARGET_DIR/$TARGET_ISO-build.log
    if [ -n "$SCP_DO" ]; then
	if [ -e "scpcommand.sh" ]; then
	    source scpcommand.sh $TARGET_DIR/$TARGET_ISO
	else
	    echo "no scpcommand available.." >&2
	fi
	
    fi

#    echo $GEN_ISO
 #   echo $TARGET_ISO
done
echo "I am done"

    

#echo $ARCHES

#lb clean --purge
#lb build
