#!/bin/bash

docker run \
    -d --name isso \
    -p 3002:8080 \
    --mount type=bind,source="$(pwd)"/db/import,target=/db \
    --mount type=bind,source="$(pwd)"/config/local,target=/config \
    wonderfall/isso:latest