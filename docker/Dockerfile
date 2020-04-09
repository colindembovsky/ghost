FROM ghost:3.12.1-alpine

RUN apk add --update --no-cache gcc g++ make libc6-compat python python3 && \
    apk add vips-dev fftw-dev build-base --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community --repository https://alpine.global.ssl.fastly.net/alpine/edge/main

# Install Azure Storage
RUN npm install ghost-storage-azure && \
    cp -vR node_modules/ghost-storage-azure current/core/server/adapters/storage/ghost-storage-azure

# backup and udpate config
RUN cp /var/lib/ghost/config.production.json /var/lib/ghost/config.production-orig.json

COPY config/redirects.json /var/lib/ghost/content/data/redirects.json
COPY config/config.production.json /var/lib/ghost/config.production.json
