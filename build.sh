#!/bin/sh

err() { echo $@; exit 1 }

if [[ ! -f xvo ]]; then
	if ! command -v v &> /dev/null; then
		err "please install v"
	fi

	v xvo-src/ -o xvo
fi

if [[ ! -f xvo ]]; then
	err "couldnt build xvo"
fi

emerge() {
	./xvo emerge $@ -config %pwd/config
}

emerge musl busybox
