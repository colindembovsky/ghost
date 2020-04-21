FROM nginx:1.17.9

ARG site
ARG port
ARG cdn
ARG wwwcdn
ENV CDN=${cdn}

COPY config/nginx.conf /etc/nginx/nginx.conf
RUN sed -i "s|SITE|${site}|g" /etc/nginx/nginx.conf && \
    sed -i "s|PORT|${port:-80}|g" /etc/nginx/nginx.conf && \
    sed -i "s|WWWCDN|${wwwcdn}|g" /etc/nginx/nginx.conf && \
    sed -i "s|CDN|${cdn}|g" /etc/nginx/nginx.conf && \
    cat /etc/nginx/nginx.conf