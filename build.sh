#!/bin/sh

err() { echo $@; exit 1; }

if [[ ! -f xvo ]] || [[ -n $@ ]]; then
	if ! command -v v &> /dev/null; then
		err "please install v"
	fi

	v xvo-src/ -o xvo
fi

if [[ ! -f xvo ]]; then
	err "couldnt build xvo"
fi

emerge() {
	./xvo emerge $@ -root %pwd/rootfs -src %pwd/src -work %pwd/work -debug yes
}

if [[ -n $@ ]]; then
	emerge $@
else
	emerge musl busybox
fi
