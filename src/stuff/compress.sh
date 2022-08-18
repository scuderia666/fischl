#!/bin/sh

find . | bsdcpio --quiet --zstd -H cpio -o -F $1
