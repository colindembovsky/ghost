FROM certbot/certbot:v1.3.0

COPY run.sh /usr/local/bin

RUN touch /tmp/firsttime

ENTRYPOINT ["run.sh"]