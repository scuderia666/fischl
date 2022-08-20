#!/bin/sh

echo 'fischl linux'

if [[ ! -f xvo ]]; then
	if ! command -v v &> /dev/null; then
		echo "please install v"
		exit 1
	fi

	v xvo-src/ -o xvo
fi

if [[ ! -f xvo ]]; then
	echo "couldnt build xvo"
	exit 1
fi

./xvo emerge musl
