#!/bin/sh

rsa_key_size=4096
data_path="./data/certbot"
if [ -z $STAGING ] || [ $STAGING != "0" ]; then staging_arg="--staging"; fi

if [ -z $EMAIL ] || [ -z $CDN ]; then
  echo "Please set email and CDN environment variables!"
else
    echo "Registering cert"
    echo "Staging arg: $STAGING"
    certbot certonly --webroot -w /var/www/certbot \
        $staging_arg \
        --email $EMAIL \
        -d $CDN -d www.$CDN \
        --rsa-key-size $rsa_key_size \
        --agree-tos \
        --force-renewal

    # loop infinitely and check for cert renewal every 12 hours
    trap exit TERM; while :; do certbot renew; sleep 10s & wait $!; done;
fi