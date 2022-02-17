ARG TAGVER=
FROM apluslms/service-base:base${TAGVER}

RUN mkdir -p /usr/share/man/man1/ /usr/share/man/man7/ \
 && apt_install \
    postgresql \
    postgresql-client \
    rabbitmq-server \
 && rm -r /etc/init.d/ \
          /var/lib/rabbitmq/* \
          /var/lib/postgresql/* \
 && rm -r /usr/share/postgresql/*/man /usr/share/man/ \
 && strip_config /etc/postgresql/*/*/environment \
                 /etc/postgresql/*/*/pg_hba.conf \
                 /etc/postgresql/*/*/pg_ident.conf \
                 /etc/postgresql/*/*/postgresql.conf \
                 /etc/postgresql/*/*/start.conf \
 && rm /etc/postgresql/*/*/pg_ctl.conf \
 && for d in /etc/postgresql/*/*/; do \
        sed -i 's,/var/lib/postgresql/,/local/postgresql/,g' "${d}postgresql.conf"; \
        echo "listen_addresses = ''" >> "${d}/postgresql.conf"; \
    done

COPY rootfs /
