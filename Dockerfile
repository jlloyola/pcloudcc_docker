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
    && git fetch https://github.com/pcloudcom/console-client pull/163/head:mfa_branch \
    && git checkout mfa_branch \
    && sed 's/-mtune=core2/-mtune=cortex-a72/g' -i ./pCloudCC/lib/pclsync/Makefile \
    && cd pCloudCC \
    && cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr . \
    && make pclsync mbedtls install/strip

FROM debian:bullseye

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       fuse \
       lsb-release \
    && rm -rf /var/lib/apt/lists/*

ARG user=pcloud
ARG group=pcloud
ARG uid=1000
ARG gid=1000
ARG PCLOUD_DIR=/var/pcloud

# pcloudcc is run with user `pcloud`, uid = 1000
# Ensure you use the same uid and gid from the host
# to avoid file permission issues.
RUN mkdir -p $PCLOUD_DIR \
  && chown ${uid}:${gid} $PCLOUD_DIR \
  && groupadd -g ${gid} ${group} \
  && useradd -d "$PCLOUD_DIR" -u ${uid} -g ${gid} -l -m -s /bin/bash ${user}

COPY --from=builder /usr/bin/pcloudcc /usr/bin/pcloudcc
COPY --from=builder /usr/lib/libpcloudcc_lib.so /usr/lib/libpcloudcc_lib.so

STOPSIGNAL SIGKILL

USER ${user}

CMD [ "pcloudcc" ]
