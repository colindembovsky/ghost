#!/bin/bash

docker run \
    -d --name isso \
    -p 3002:8080 \
    --mount type=bind,source="$(pwd)"/database,target=/isso/db \
    --mount type=bind,source="$(pwd)"/config,target=/isso/config \
    wonderfall/isso:latest