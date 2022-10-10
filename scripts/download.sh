#!/bin/sh

if ! command -v curl &> /dev/null; then
    url=${1/https/http}
    wget $url -O "$2.part"
else
    curl -C - -f --retry 3 --retry-delay 3 -L -o "$2.part" $1
fi

if [[ -f "$2.part" ]]; then
	mv "$2.part" $2
fi
