FROM ghost:4.12.1-alpine

ARG mode

ENV devMode ${mode:-production}
ENV url ""

RUN apk add --update --no-cache gcc g++ make libc6-compat python3 && \
    apk add vips-dev fftw-dev build-base --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community --repository https://alpine.global.ssl.fastly.net/alpine/edge/main && \
    rm -rf /var/cache/apk/*

# Install Azure Storage and app Insights
RUN npm install ghost-storage-azure applicationinsights && \
    cp -vR node_modules/ghost-storage-azure current/core/server/adapters/storage/ghost-storage-azure

# backup and udpate config
RUN cp /var/lib/ghost/config.production.json /var/lib/ghost/config.production-orig.json

COPY config/index.js /var/lib/ghost/current/index.js
COPY config/redirects.json /var/lib/ghost/content/data/redirects.json
COPY config/config.${devMode}.json /var/lib/ghost/config.production.json
# remember to replace __ISSO_CDN__ in post.hbs before running docker build
COPY themes/casper-colin/ /var/lib/ghost/content/themes/casper-colin/