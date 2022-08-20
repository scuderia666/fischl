#!/bin/sh

list_files() {
	[ -z "$1" ] && return 1
	echo "$(bsdtar -tf "$1" | sed 's|./||')"
}

list_files $1 | sed -e 's/.pkginfo//' -e 's/.install//' | sed '/^\s*$/d' >> $2
