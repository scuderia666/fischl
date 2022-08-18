#!/bin/sh

is_in_archive() {
	[ -z "$1" ] && return 1
	[ -z "$2" ] && return 1
	echo "$(bsdtar -tf "$1" | sed 's|./||' | grep -w "$2")"
}

list_files() {
	[ -z "$1" ] && return 1
	echo "$(bsdtar -tf "$1" | sed 's|./||')"
}

archive_file_stdout() {
	[ -z "$1" ] && return 1
	[ -z "$2" ] && return 1
	echo "$(bsdtar -Oxf "$1" "$2")"
}

list_subtract() {
	(
		cat $1 $2 | sort | uniq -u
		cat $1
	) | sort | uniq -d
}

list_uninstall() {
	local f p
	local files=$(sort -r "$1" | sed 's:^:'"${rootdir}/"': ; s:/^[^\.]\./::g; s:/\{2,\}:/:g; s:/\./:/:g')
	if [ -z "$DRYRUN" ] ; then
		echo "$files" | tr '\n' '\0' | xargs -0 rm 2>/dev/null
		echo "$files" | tr '\n' '\0' | xargs -0 rmdir 2>/dev/null
		[ $2 ] && echo "$files" >> $2
	fi
	return 0
}
