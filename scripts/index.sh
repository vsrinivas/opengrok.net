#!/bin/bash

LOCKFILE=/var/run/opengrok-indexer

if [ -f "$LOCKFILE" ]; then
    date +"%F %T Indexer still locked, skipping indexing"
    exit 1
fi

touch $LOCKFILE
date +"%F %T Indexing starting"
opengrok-indexer \
    -J=-d64 -J=-server -J=-Xmx8g \
    -a /opengrok/lib/opengrok.jar -- \
    -s /src -d /data -H -S -P --renamedHistory on \
    -m 256 \
    --progress \
    --webappCtags on \
    -R /var/opengrok/etc/read_only.xml \
    -W /var/opengrok/etc/configuration.xml -U http://localhost:8080 "$@"
rm -f $LOCKFILE
date +"%F %T Indexing finished"
