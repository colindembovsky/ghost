#!/bin/sh

rsa_key_size=4096
if [ -z $STAGING ] || [ $STAGING != "0" ]; then staging_arg="--staging"; fi

if [ -z $EMAIL ] || [ -z $CDN ]; then
  echo "Please set email and CDN environment variables!"
else
    wwwArg=""
    if [ -z $WWW ] || [ $WWW != "0" ]; then
      echo "Adding www.$CDN to registration"
      wwwArg="-d www.$CDN" 
    fi

    if [ ! -f "$WORKING_PATH/live/$CDN/fullchain.pem" ]; then
      echo "Creating cert"
      echo "Staging arg: $STAGING"

      certbot certonly --standalone \
        --preferred-challenges=http \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --manual-public-ip-logging-ok \
        --domain $CDN $wwwArg
      
      # append the renew_hook to the config file
      mkdir -p "$WORKING_PATH/renawal/"
      echo "renew_hook = deploy-cert-az-webapp.sh" >> "$WORKING_PATH/renawal/$CDN.conf"

      # run the script to register the cert with web apps
      deploy-cert-az-webapp.sh
    fi

    timeout="12h"
    if [ ! -z $DEBUG ] && [ $DEBUG == "TRUE" ]; then
      timeout="30s"
    fi

    # loop infinitely and check for cert renewal every 12 hours
    # if the cert does not need renewing, certbot does nothing
    # after renewal, the deploy-cert-az-webapp.sh should fire to
    # register the renewed cert
    trap exit TERM; while :; do certbot renew; sleep $timeout & wait $!; done;
fi