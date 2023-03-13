
help:
	@echo Run 'make build' to build the docker image
	@echo Run 'make push' to push the docker image to dockerhub

build
docker buildx build --pull  --progress=plain --no-cache --platform ${{ parameters.platforms }} --build-arg VERSION --build-arg version=$VERSION \
          --build-arg build_version=$VERSION --build-arg build_base=${{ parameters.buildImageType }} \
          --build-arg build_platform=${{ parameters.buildPhpVersion }} \
          --tag ${{ parameters.repository }}:$LABEL \
          --tag ${{ parameters.repository }}:$VERSION \
          --push