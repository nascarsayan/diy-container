#!/bin/bash
if (( EUID != 0 )); then
    echo "Please run as root"
    exit
fi
set -x
mkdir -p ~/ship/images/mini/{bin,lib,lib64,proc}
cp "$(which kill)" ~/ship/images/mini/bin/
cp "$(which ps)" ~/ship/images/mini/bin/
cp "$(which bash)" ~/ship/images/mini/bin/
cp "$(which ls)" ~/ship/images/mini/bin/
cp -r /lib/* ~/ship/images/mini/lib/
cp -r /lib64/* ~/ship/images/mini/lib64/
mount -t proc proc ~/ship/images/mini/proc
