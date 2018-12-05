ARG TAGVER=
FROM apluslms/service-base:python3${TAGVER}

COPY rootfs /
ENTRYPOINT [ "/init", "run-django.sh" ]
