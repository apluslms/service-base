ARG TAGVER=
FROM --platform=$TARGETPLATFORM apluslms/service-base:dbipc${TAGVER}

COPY rootfs /

RUN apt_install \
    build-essential \
    python3-dev \
    python3 \
    python3-certifi \
    python3-gunicorn \
    python3-pip \
    python3-psycopg2 \
    python3-setuptools \
    python3-venv \
    python3-wheel \
 && :
