FROM nginx:1.17.9

ARG site
ARG port
ARG cdn

COPY config/nginx.conf /etc/nginx/nginx.conf
RUN sed -i "s|SITE|${site}|g" /etc/nginx/nginx.conf && \
    sed -i "s|PORT|${port:-80}|g" /etc/nginx/nginx.conf && \
    sed -i "s|CDN|${cdn}|g" /etc/nginx/nginx.conf && \
    cat /etc/nginx/nginx.conf

# override entrypoint to reload config every 6 hours (for auto-renew of certs)
CMD "/bin/sh -c 'while :; do sleep 6h & wait $${!}; nginx -s reload; done & nginx -g \"daemon off;\"'"