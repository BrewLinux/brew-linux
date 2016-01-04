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
PRESEEDFILE=''
MIRROR=''
CACHE=''
LIVEMIRROR=''

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


options=$(getopt -o "a:t:sdhnp:m:c:l:" --long "arch:,target:,scp,deploy,help,nocache,preseed,mirror,cache,livemirror" -- "$@")
eval set -- "$options"

while true; do
    case "$1" in
	-a|--arch) ARCHES="$2";shift 2; ;;
	-t|--target) TARGET_NAME="$2";shift 2; ;;
	-s|--scp) SCP_DO="1";shift; ;;
	-d|--deploy) DEPLOY_DO="1";shift; ;;
	-n|--nocache) NO_CACHE="1";shift ;;
	-h|--help) cat helpme;exit 1; ;;
	-p|--preseed) PRESEEDFILE="$2";shift 2; ;;
	-m|--mirror) MIRROR="$2";shift 2; ;;
	-c|--cache) CACHE="$2";shift 2; ;;
	-l|--livemirror) LIVEMIRROR="$2";shift 2; ;;
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

if [ -n "$PRESEEDFILE" ]; then
    if [ ! -e $PRESEEDFILE ]; then
	echo "You wanted to preseed...but file does not exist..."
	failure
    fi
    if [ -e "config/includes.installer/preseed.cfg" ]; then
	echo "You wanted to preseed..but there is already a preseed file..."
	failure
    fi
    cat $PRESEEDFILE > config/includes.installer/preseed.cfg
fi

CACHE_OPT=''
if [ -n "$CACHE" ];then
    CACHE_OPT="-w $CACHE"
else
    echo "You have no cache...." >&2
    failure
fi


MIRROR_OPT=''
if [ -n "$MIRROR" ];then
    MIRROR_OPT="-u $MIRROR"
else
    echo "You have no mirror...." >&2
    failure
fi

LMIRROR_OPT=''
if [ -n "$LIVEMIRROR" ];then
    LMIRROR_OPT="-v $LIVEMIRROR"
else
    echo "You have no live mirror...." >&2
    failure
fi

mkdir -p $TARGET_DIR

#iterate archs
for BREW_ARCH in $ARCHES; do
    GEN_ISO="$(image_name $BREW_ARCH)"
    TARGET_ISO="$(target_name $TARGET_NAME $BREW_ARCH)"
    set +e
    : >> build.log
    if [ -n "$NO_CACHE" ];then
	echo "Be careful you do not use clean --purge..."
    else
	
	runcommand lb clean --purge
	[ $? -eq 0 ] || failure
    fi
    runcommand lb config -t $BREW_ARCH $CACHE_OPT $MIRROR_OPT $LMIRROR_OPT"$@"
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


if [ -n "$PRESEEDFILE" ]; then
    #delete the preseed but only when we wrote it
    rm config/includes.installer/preseed.cfg
fi

echo "I am done"

    

#echo $ARCHES

#lb clean --purge
#lb build
