#!/bin/sh

pushd $1
	bsdcpio --quiet -id < $2
popd
