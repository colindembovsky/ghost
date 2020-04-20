FROM nginx:1.17.9

ARG site
ARG port
ARG cdn
ENV CDN=${cdn}

COPY config/nginx.conf /etc/nginx/nginx.conf
RUN sed -i "s|SITE|${site}|g" /etc/nginx/nginx.conf && \
    sed -i "s|PORT|${port:-80}|g" /etc/nginx/nginx.conf && \
    sed -i "s|CDN|${cdn}|g" /etc/nginx/nginx.conf && \
    cat /etc/nginx/nginx.conf

# copy the dummy certs to allow nginx to start up
COPY config/*.pem /tmp/

COPY run.sh /usr/local/bin

# override entrypoint to reload config every 6 hours (for auto-renew of certs)
ENTRYPOINT ["/usr/local/bin/run.sh"]