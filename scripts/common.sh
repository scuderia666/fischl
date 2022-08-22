#!/bin/sh

umask 0022
unalias -a
#set -e

pushd() { command pushd $1 > /dev/null; }
popd() { command popd $1 > /dev/null; }

apply_patch() {
    echo "applying patch $(basename $1)"
    patch -p1 < $1
}

apply_patches() {
	for patch in $1/*; do
		apply_patch $patch
	done
}
