# -*-Dockerfile-*-

ARG DEBIAN_VERSION=bullseye

FROM debian:${DEBIAN_VERSION} AS builder

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
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

# Tune the build for Arm Cortex 72 (PI4)
ARG mtune=cortex-a72
# Pin the repo to the latest tested commit.
ARG console_client_sha=4b42e3c8a90696ca9ba0a7e162fcbcd62ad2e306

RUN git clone https://github.com/pcloudcom/console-client \
    && cd console-client \
    && git reset --hard ${console_client_sha} \
    && git fetch https://github.com/pcloudcom/console-client pull/163/head:mfa_branch \
    && git checkout mfa_branch \
    && if [[ "${TARGETARCH}" != "amd64" ]] ; then sed "s/-mtune=core2/-mtune=${mtune}/g" -i ./pCloudCC/lib/pclsync/Makefile ; fi \
    && cd pCloudCC \
    && cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr . \
    && make pclsync mbedtls install/strip

FROM debian:${DEBIAN_VERSION}-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       fuse \
       lsb-release \
       gosu \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/bin/pcloudcc /usr/bin/pcloudcc
COPY --from=builder /usr/lib/libpcloudcc_lib.so /usr/lib/libpcloudcc_lib.so

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]