FROM cacregistry.azurecr.io/issomysql:latest

ARG target
COPY config/${target:-mysql-local}/isso.conf /config/isso.cfg

# customize port
EXPOSE 8088
CMD ["/isso/bin/gunicorn", "-b", "0.0.0.0:8088", "-w", "4", "--preload", "isso.run"]