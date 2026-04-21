FROM debian:trixie-20260406-slim

ENV LANG=C.UTF-8 \
    USER=root HOME=/root

ARG TARGETPLATFORM
ARG S6_VERSION=v3.2.2.0

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
      xz-utils \
\
 # S6 Overlay
 && cd /tmp \
 && if [ "$TARGETPLATFORM" = "linux/amd64" ] ; then ARCH=x86_64 ; elif [ "$TARGETPLATFORM" = "linux/arm64" ] ; then ARCH=aarch64 ; else exit 1 ; fi \
 # Download
 && curl -LSs https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/s6-overlay-noarch.tar.xz -o s6-overlay-noarch.tar.xz \
 && curl -LSs https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/s6-overlay-$ARCH.tar.xz -o s6-overlay-$ARCH.tar.xz \
 && curl -LSs https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/s6-overlay-symlinks-noarch.tar.xz -o s6-overlay-symlinks-noarch.tar.xz \
 && curl -LSs https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/s6-overlay-symlinks-arch.tar.xz -o s6-overlay-symlinks-arch.tar.xz \
 # Install
 && tar -C / -Jxpf s6-overlay-noarch.tar.xz \
 && tar -C / -Jxpf s6-overlay-$ARCH.tar.xz \
 && tar -C / -Jxpf s6-overlay-symlinks-noarch.tar.xz \
 && tar -C / -Jxpf s6-overlay-symlinks-arch.tar.xz \
 # Clean
 && rm -rf /tmp/* \
 && apt_purge curl xz-utils \
 && rm -rf /etc/init.d/ \
\
 && ln -sf /usr/bin/s6-setuidgid /usr/bin/setuidgid

VOLUME /data
ENTRYPOINT ["/init"]
