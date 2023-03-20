
help:
	@echo Run 'make build' to build the docker image
	@echo Run 'make push' to push the docker image to dockerhub

PLATFORM := linux/arm64
REPOSITORY := jloyola/pcloudcc
LABEL := dev

build:
	docker buildx build -f Dockerfile \
	--progress=plain --no-cache \
	--platform $(PLATFORM) \
	--tag $(REPOSITORY):$(LABEL) \
	$(BUILD_ARGS_EXTRA) \
	.

USER_NAME ?= example@example.com
PCLOUD_SAVE_PASSWORD ?= 1
USER_ID ?= $(shell id -u)
USER_GROUP ?= $(shell id -g)
SRC_CACHE := pcloud_cache
DST_CACHE := /home/pcloud/.pcloud
SRC_MOUNT := $(HOME)/pCloudDrive
DST_MOUNT := /pCloudDrive

init:
	test -d $(SRC_MOUNT) || mkdir -p $(SRC_MOUNT)
	docker run -it \
	-v "$(SRC_CACHE):$(DST_CACHE)" \
	--mount type=bind,source=$(SRC_MOUNT),target=$(DST_MOUNT),bind-propagation=shared \
	-e "PCLOUD_USERNAME=$(USER_NAME)" \
	-e "PCLOUD_SAVE_PASSWORD=$(PCLOUD_SAVE_PASSWORD)" \
	-e "PCLOUD_UID=$(USER_ID)" \
	-e "PCLOUD_GID=$(USER_GROUP)" \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	$(RUN_ARGS_EXTRA) \
	$(REPOSITORY):$(LABEL)