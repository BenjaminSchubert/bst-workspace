#!/usr/bin/env bash

# /dev/fuse should be world-writable, but... not on Windows
if [ -e /dev/fuse ]; then
    chmod o+rw /dev/fuse
fi

exec "$@"
