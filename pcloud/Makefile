
help:
	@echo Run 'make build' to build the docker image
	@echo Run 'make push' to push the docker image to dockerhub

PLATFORM := linux/arm64
REPOSITORY := jloyola/pcloud
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