#!/usr/bin/env bash

docker stop rbt-tileserver-gl
docker rm rbt-tileserver-gl

docker run -d \
	--name rbt-tileserver-gl \
	--restart=always \
	--ipc=host \
	--ulimit memlock=-1 \
	--ulimit stack=67108864 \
	--shm-size=16gb \
	-v $(pwd)/fonts:/fonts \
	-v $(pwd)/data:/data \
	-v $(pwd)/styles:/styles \
	-v $(pwd)/config:/config \
	-p 0.0.0.0:8080:8080 \
	docker.io/mjj203/rbt:tileservergl-3395-latest \
	--verbose \
	--config /config/config.json
