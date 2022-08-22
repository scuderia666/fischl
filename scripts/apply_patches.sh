#!/bin/sh

for patch in $1/*; do
	patch -p1 < $patch
done
