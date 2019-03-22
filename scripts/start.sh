#!/bin/bash

# Reindex default
if [ -z "$REINDEX" ]; then
    REINDEX=48000
fi

#START METHOD FOR INDEXING OF OPENGROK
start_opengrok(){
    # wait for tomcat startup
    date +"%F %T Waiting for tomcat startup..."
    while [ "`curl --silent --write-out '%{response_code}' -o /dev/null 'http://localhost:8080/'`" == "000" ]; do
        sleep 1;
    done
    date +"%F %T Startup finished"

    # populate the webapp with bare configuration
    echo '<p><h1>Waiting on the initial reindex to finish.. Stay tuned !</h1></p>' > /data/body_include
    /scripts/index.sh --noIndex
    rm -f /data/body_include

    # initial indexing
    /scripts/index.sh

    # continue to index every $REINDEX minutes
    if [ "$REINDEX" == "0" ]; then
        date +"%F %T Automatic reindexing disabled"
        return
    else
        date +"%F %T Automatic reindexing in $REINDEX minutes..."
    fi
    while true; do
        sleep `expr 60 \* $REINDEX`
        /scripts/index.sh
    done
}

#START ALL NECESSARY SERVICES.
start_opengrok &
catalina.sh run
