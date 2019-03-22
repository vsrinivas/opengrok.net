#!/bin/bash

LOCKFILE=/var/run/opengrok-indexer

if [ -f "$LOCKFILE" ]; then
    date +"%F %T Indexer still locked, skipping indexing"
    exit 1
fi

touch $LOCKFILE
date +"%F %T Indexing starting"
opengrok-indexer \
    -J=-Xmx8g -J=-d64 -J=-server \
    -a /opengrok/lib/opengrok.jar -- \
    -s /src -d /data -H -P -S -G --renamedHistory on \
    -m 512 \
    --progress \
    --optimize on \
    --webappCtags on \
    -W /var/opengrok/etc/configuration.xml -U http://localhost:8080 "$@"
rm -f $LOCKFILE
date +"%F %T Indexing finished"
