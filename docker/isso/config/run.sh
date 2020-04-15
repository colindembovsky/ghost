#!/bin/sh
echo "sleeping"
sleep 60  # give ghost time to start up
echo "sleep over!"
chown -R $UID:$GID /db /config
exec su-exec $UID:$GID /sbin/tini -- isso -c /config/isso.conf run
