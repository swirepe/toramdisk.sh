#!/bin/bash

set -o errexit

DIRECTORY_TO_COPY=''
RAMDISK_ROOT="/tmp/ramdisk"
RAMDISK_TYPE="ramfs"

# get the arguments
if [ $# -le 0 ]
then
    echo  "toramdisk - Put a directory into memory."
    echo  "Positonal arguments:"
    echo  "    directory               Put this directory into memory."
    echo  "    ramdisk_root (optional) Location to put it in memory. Default: $RAMDISK_ROOT"
    echo  "    size         (optional) The amount of ram to use."
    echo  "                            Defaults to the size of the directory to put in memory."
    echo  "                            WARNING: will fail if too small"
    echo  "    fs_type      (optional) The kind of file system you want: tmpfs or ramfs."
    echo  "                            ramfs - dynamic size, does not swap"
    echo  "                            tmpfs - static size, swaps"
    echo  "                            Default: $RAMDISK_TYPE"
    echo  "Output: the path to the directory now in memory."                                   
    exit 0    
fi

# for fstype details see http://www.thegeekstuff.com/2008/11/overview-of-ramfs-and-tmpfs-on-linux/

if [ -n "$1" ]
then
    DIRECTORY_TO_COPY="$1"
else
    echo "Error: directory not specified." > /dev/stderr
    exit 1
fi

# make sure that what we are to copy is a directory and it exists
if [ ! -d "$DIRECTORY_TO_COPY" ]
then
    echo "Error: non-directory specified.  $DIRECTORY_TO_COPY" > /dev/stderr
    exit 1
fi

# get the ramdisk root, if we need to
if [ -n "$2" ]
then
    RAMDISK_ROOT="$2"
fi

# get the size, if we need to
if [ -n "$3" ]
then
    SIZE="$3"
else
    SIZE=$(du -s -B1 $DIRECTORY_TO_COPY | cut -f 1 )
fi

# get the filesystem type, if we need it
if [ -n "$4" ]
then
    RAMDISK_TYPE="$4"
fi

# validate the ramdisk type
if [[ "$RAMDISK_TYPE" -ne "tmpfs" && "$RAMDISK_TYPE" -ne "ramfs" ]]
then
    echo "Error: Invalid ram filesystem type: $RAMDISK_TYPE" > /dev/stderr
    exit 1
fi


# make the root
if [ ! -d "$RAMDISK_ROOT" ]
then
    sudo mkdir -p "$RAMDISK_ROOT"
fi

# make the directory
NAME=$(readlink -f $DIRECTORY_TO_COPY | xargs basename)
sudo mkdir -p "$RAMDISK_ROOT/$NAME"

# mount the directory
sudo mount -t tmpfs -o size="$SIZE" "$RAMDISK_TYPE" "$RAMDISK_ROOT/$NAME"

# copy the files
cp -r "$DIRECTORY_TO_COPY" "$RAMDISK_ROOT"


echo "$RAMDISK_ROOT/$NAME"
exit 0
