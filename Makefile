
help:
	@echo Run 'make build' to build the docker image
	@echo Run 'make push' to push the docker image to dockerhub

PLATFORM := linux/arm64
REPOSITORY := jloyola/pcloudcc
LABEL := latest
VERSION := 0.1.0

build:
	docker buildx build -f Dockerfile \
	--progress=plain --no-cache \
	--platform $(PLATFORM) \
	--tag $(REPOSITORY):$(LABEL) \
	--tag $(REPOSITORY):$(VERSION) \
	$(BUILD_ARGS_EXTRA) \
	.

USER_NAME ?= example@example.com
USER_ID ?= $(shell id -u)
USER_GROUP ?= $(shell id -g)
SRC_CACHE := $(pwd)/pcloud_cache
DST_CACHE := /home/pcloud/.pcloud
SRC_MOUNT := $(HOME)/pcloud
DST_MOUNT := /var/pcloud

#	docker run --rm -it
init:
	docker run -it \
	-v $(SRC_CACHE):$(DST_CACHE) \
	--mount type=bind,source=$(SRC_MOUNT),target=$(DST_MOUNT),bind-propagation=shared \
	--device /dev/fuse --cap-add SYS_ADMIN \
	$(REPOSITORY):$(VERSION) \
	pcloudcc -u $(USER_NAME) -s -m $(DST_MOUNT)