FROM debian:bullseye as builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       cmake \
       zlib1g-dev \
       libboost-system-dev \
       libboost-program-options-dev \
       libpthread-stubs0-dev \
       libfuse-dev \
       libudev-dev \
       libsqlite3-dev \
       fuse \
       build-essential \
       git \
       make \
       ca-certificates \
    && cd /usr/src \
    && git clone https://github.com/pcloudcom/console-client \
    && cd console-client \
    && COMMIT=$(git rev-parse HEAD) \
    && sed 's/-mtune=core2//g' -i ./pCloudCC/lib/pclsync/Makefile \
    && cd pCloudCC \
    && cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr . \
    && make pclsync mbedtls install/strip

FROM debian:bullseye

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       fuse \
       lsb-release \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/bin/pcloudcc /usr/bin/pcloudcc
COPY --from=builder /usr/lib/libpcloudcc_lib.so /usr/lib/libpcloudcc_lib.so

STOPSIGNAL SIGKILL

LABEL git-commit=$COMMIT

CMD [ "pcloudcc" ]
