#/bin/bash

if [ -z $CDN ]; then
  echo "Please set CDN environment variable!"
else
    # copy dummy certs into the ssl volume
    cp -f /tmp/dummy_cert.pem /etc/letsencrypt/live/$CDN/fullchain.pem
    cp -f /tmp/dummy_privkey.pem /etc/letsencrypt/live/$CDN/privkey.pem

    # loop 20 times, reloading the config every 30 seconds to allow
    # certbot to create a valid cert
    x=10
    while [ $x -gt 0 ]; do sleep 30s & wait $!; nginx -s reload; x=$(( $x - 1)); done & nginx

    # loop infinitely, reloading the ngix config every 6 hours
    while :; do sleep 6h & wait $!; nginx -s reload; done & nginx
fi