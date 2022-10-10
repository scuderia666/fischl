#!/bin/sh

git clone $1 "$2.part"

if [[ -d "$2.part" ]]; then
	mv "$2.part" $2
fi
