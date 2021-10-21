FROM debian:buster-20210408-slim

ENV LANG=C.UTF-8 \
    USER=root HOME=/root \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=10000

ARG S6_VERSION=v1.22.1.0

COPY rootfs /

RUN apt_install \
      apt-utils \
      ca-certificates \
      git \
      gettext \
      # temporary:
      gnupg \
      curl \
\
 # S6 Overlay
 && cd /tmp \
 # Download
 && curl -LSs https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/s6-overlay-amd64.tar.gz -o s6-overlay-amd64.tar.gz \
 && curl -LSs https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/s6-overlay-amd64.tar.gz.sig -o s6-overlay-amd64.tar.gz.sig \
 # Validate signature
 && gpg --keyserver pgp.surfnet.nl --recv-keys 6101B2783B2FD161 \
 && gpg --verify s6-overlay-amd64.tar.gz.sig s6-overlay-amd64.tar.gz \
 && rm -rf /root/.gnupg \
 # Install
 && tar -xzf s6-overlay-amd64.tar.gz -C / \
 # Clean
 && rm -rf /tmp/* \
 && apt_purge gnupg curl \
 && rm -rf /etc/init.d/ \
\
 && ln -s /bin/s6-setuidgid /bin/setuidgid

VOLUME /data
ENTRYPOINT ["/init"]
