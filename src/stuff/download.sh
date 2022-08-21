#!/bin/sh

curl -C - -f --retry 3 --retry-delay 3 -L -o "$2.part" $1

if [[ -f "$2.part" ]]; then
	mv "$2.part" $2
fi
