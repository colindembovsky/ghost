#!/bin/sh

rsa_key_size=4096
data_path="./data/certbot"
if [ -z $STAGING ] || [ $STAGING != "0" ]; then staging_arg="--staging"; fi

if [ -z $EMAIL ] || [ -z $CDN ]; then
  echo "Please set email and CDN environment variables!"
else
    if [ -f "/tmp/firsttime" ]; then
      echo "Container first time - delete self-signed cert"
      rm -rf /etc/letsencrypt/live/CDN/*.pem
    fi

    wwwArg=""
    if [ ! -z $WWWCDN ]; then
      echo "Adding $WWWCDN to registration"
      wwwArg="-d $WWWCDN" 
    fi
    echo "Registering cert"
    echo "Staging arg: $STAGING"
    certbot certonly --webroot -w /var/www/certbot \
        $staging_arg \
        --email $EMAIL \
        -d $CDN \
        $wwwArg \
        --rsa-key-size $rsa_key_size \
        --agree-tos \
        --force-renewal

    # other containers may take a while to boot, but we need them to
    # be running to respond to challenges, so loop every 30s for 10
    # mins
    x=20
    trap exit TERM; while [ $x -gt 0 ]; do certbot renew; sleep 30s & wait $!; done;

    # loop infinitely and check for cert renewal every 12 hours
    trap exit TERM; while :; do certbot renew; sleep 12h & wait $!; done;
fi