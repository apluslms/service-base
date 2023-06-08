ARG TAGVER=
FROM --platform=$TARGETPLATFORM apluslms/service-base:python3${TAGVER}

COPY rootfs /
RUN pip_install \
    debugpy \
 && :

ENTRYPOINT [ "/init", "run-django.sh" ]
