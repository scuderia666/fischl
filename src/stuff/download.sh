#!/bin/sh

curl -C - -f --retry 3 --retry-delay 3 -L -o $2 $1
