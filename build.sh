#!/bin/sh

here=$(pwd)
out=$here/out

[[ ! -d $out ]] && ./stuff/setup.sh $out
