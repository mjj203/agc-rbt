#!/usr/bin/env bash

docker stop rbt-tileserver-gl
docker rm rbt-tileserver-gl

docker run -d \
	--name rbt-tileserver-gl \
	--restart=always \
	--ulimit memlock=-1 \
	--ulimit stack=67108864 \
	--shm-size=16gb \
	-v ./tileserver/fonts:/fonts \
	-v ./tileserver/data:/data \
	-v ./tileserver/styles:/styles \
	-v ./tileserver/config:/config \
	-p 0.0.0.0:8080:8080 \
	docker.io/mjj203/tileservergl:4.10.3 \
	--verbose \
	--config /config/config.json
