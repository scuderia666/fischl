#!/bin/sh

list_uninstall() {
	local f p
	local files=$(sort -r $1 | sed 's:^:'"$2/"': ; s:/^[^\.]\./::g; s:/\{2,\}:/:g; s:/\./:/:g')
	echo "$files" | tr '\n' '\0' | xargs -0 rm 2>/dev/null
	echo "$files" | tr '\n' '\0' | xargs -0 rmdir 2>/dev/null
	return 0
}

list_uninstall $1 $2
