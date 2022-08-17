#!/bin/sh

bsdtar -p -o -C $2 --strip-components 1 -xf $1
