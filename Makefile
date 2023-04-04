.PHONY: help build init act actn test
help:
	@echo Run 'make build' to build the docker image locally
	@echo Run 'env PCLOUD_USERNAME="<pcloud_user>" PCLOUD_SECRET=<secret> make test' to run a basic functionality test

PLATFORM := linux/arm64
REPOSITORY := jloyola/pcloudcc
LABEL := dev
IMAGE_NAME := $(REPOSITORY):$(LABEL)

build:
	docker buildx build -f Dockerfile \
	--progress=plain --no-cache \
	--platform $(PLATFORM) \
	--tag $(REPOSITORY):$(LABEL) \
	$(BUILD_ARGS_EXTRA) \
	.

PCLOUD_USERNAME ?= example@example.com
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
	-e "PCLOUD_USERNAME=$(PCLOUD_USERNAME)" \
	-e "PCLOUD_SAVE_PASSWORD=$(PCLOUD_SAVE_PASSWORD)" \
	-e "PCLOUD_UID=$(USER_ID)" \
	-e "PCLOUD_GID=$(USER_GROUP)" \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	$(RUN_ARGS_EXTRA) \
	$(REPOSITORY):$(LABEL)


ACT_CMD := act --secret-file .act -e test/actEvent.json --rm
act:
	$(ACT_CMD)

actn:
	$(ACT_CMD) -n

test:
	./test/testImage.sh $(IMAGE_NAME)
