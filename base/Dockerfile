FROM --platform=$TARGETPLATFORM debian:bullseye-20230612-slim

ENV LANG=C.UTF-8 \
    USER=root HOME=/root \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=10000

ARG TARGETPLATFORM
ARG S6_VERSION=v2.2.0.3

COPY rootfs /

RUN apt_install \
      apt-utils \
      ca-certificates \
      git \
      gettext \
      less \
      nano \
      # temporary:
      curl \
\
 # S6 Overlay
 && cd /tmp \
 && if [ "$TARGETPLATFORM" = "linux/amd64" ] ; then ARCH=amd64 ; elif [ "$TARGETPLATFORM" = "linux/arm64" ] ; then ARCH=aarch64 ; else exit 1 ; fi \
 # Download
 && curl -LSs https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/s6-overlay-$ARCH.tar.gz -o s6-overlay-$ARCH.tar.gz \
 # Install
 && tar -xzf s6-overlay-$ARCH.tar.gz -C / \
 # Clean
 && rm -rf /tmp/* \
 && apt_purge curl \
 && rm -rf /etc/init.d/ \
\
 && ln -s /bin/s6-setuidgid /bin/setuidgid

VOLUME /data
ENTRYPOINT ["/init"]
