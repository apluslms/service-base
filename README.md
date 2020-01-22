# service-base

A base Docker images for all images using _single service per container_ principle.
Contains [S6 init system](https://skarnet.org/software/s6-linux-init/) via [S6 overlay](https://github.com/just-containers/s6-overlay).

Different layers are build on top of each other and they include scripts for different needs.
The goal is to provide easy base to build web application development containers.

## Special paths

* `/etc/cont-init.d` includes scripts, which are run in order at init time before main command.
  Different layers add scripts here.
  More in S6 overly documentation.
* `/etc/services.d/` contains service directories for S6 services (copied to `/run/s6/services/` by S6 overlay)
* `/data` shared data volume for application containers
* `/local` is a link to `/data/$CONTAINER_TYPE` (created by `/etc/cont-init.d/00_local_data`)
* `/src` any files here are copied to `/srv/` (by `/etc/cont-init.d/10_copy_srcs`)


## Layers and utilities

* base - just s6 init and utilities

    Utils `apt_install`, `apt_purge` and apt configs are included to help build different layers and application container.
    The `apt_install [packages...]` udpates the index, installs `packages` and removes debs and the index.
    The `apt_purge [packages...]` does it's best to ensure nothing is left after removing packages.

    The script `/usr/local/lib/prefix-logs` can be used to prefix logs with a service name before printed to stdout.
    To use it, link service `./log/run` to it.

    Shell functions in `/usr/local/lib/cont-init-functions.sh` help creating simple `cont-init.d` scripts.
    Read the file and check the example below to know more.

    Utils `run_services <service> [service...]` and `start_services <service> [service...]` can be used by the main script to run service once or start it with restart policy respectively.
    Both are just wrappers for [s6-svc](https://skarnet.org/software/s6/s6-svc.html).

    There are some other scripts, explore and read them when needed.

* dbipc (on top of base) - postgresql and rabbitmq

    `create-db.sh <user> <database_name> [<command> [args...]]`
    starts PostgreSQL, creates an user and a db, runs the command to initialise it and finally dumps the contents to `/srv/db-$dabase_mame.sql.gz`.
    The purpose is to run this in Dockerfile to prebuild complex database, so initial container start is faster.

    `init-db.sh <user> <database_name> [<command> [args...]]`
    checks if user can connect to database `database_name`.
    If it can't, it will create the database and the user, and will populate the database with `/srv/db-$database_name.sql.gz` if it exists, or with the command.
    If the connection can be made, then the command is run to update it.
    Environment variable `DATABASE_IS_EMPTY` is set to `true` for first case.

    Both commands will set following environment variables and run the command as `user`:
    `DATABASE_USER=$user`,
    `DATABASE_NAME=$database_name`,
    `DATABASE_IS_EMPTY=[true|]`,
    `USER=$user`

* python3 (on top of dbipc) - base for Python projects

    `pip_install` for Dockerfiles.
    It is just alias for `pip3 install --no-cache-dir --disable-pip-version-check`.

    `/etc/cont-init.d/90_virtualenv` creates virtual environments under `/local` for every `/srv/<app>/requirements.txt`.
    For example, if you mount a development code to `/srv/myapp`, then `/local/venv_myapp` will be created with requirements from the project.

* django (on top of python3) - utilities for Django based projects

    `django-migrate.sh [bootstrap]` is tool to be used with `create-db.sh` and `init-db.sh`.
    If there is requirements.txt, it will execute `./manage.py makemigrations` and if any are created, it will print them to stdout.
    All migrations _should be_ created by the developer, but this is here to identify missing migrations.
    Next, it will run `./manage.py migrate` to ensure database is updated.
    Lastly, if `$DATABASE_IS_EMPTY` is `true` and there exists a bootstrap script, it will be execute using `python3`.
    The bootstrap script is the first argument for `django-migrate.sh` or `/srv/db-$DATABASE_NAME-bootstrap.py`.

    `run-django.sh [-u user] [-d database_name] [-a app_path] [-s setup_script] [-i init_script]` where
    `user` defaults  to `$CONTAINER_TYPE`,
    `database_name` to `user`,
    `app_path` to `/srv/$user`,
    `setup_script` to `/srv/$app_name-setup.py` and
    `init_script` to `/srv/$app_name-init.sh`.
    The `app_name` is the directory name of `$app_path`.

    1. If `/local/venv_$app_name/bin/activate` exists, it will be sourced. Check `/etc/cont-init.d/90_virtualenv` from python3 layer.
    1. Execute `init-db.sh $user $database_name django-migrate.sh`, to ensure database state.
    1. If `requirements.txt` exists, run `./manage.py compilemessages`
    1. Run `./manage.py collectstatic`
    1. If `$setup_script` exists, run it using `python3` as `$user`
    1. If `$init_script` exists, run it as root.
    1. Finally, as `$user`:

        * If first argument is `manage`, execute `./manage.py <rest of the arguments>`
        * If any arguments, execute all the arguments
        * Else, execute `./manage.py help`

    The script will exit on first failure (`set -x`).


## Application container

For an exmaple, a Django application container could be created with a Dockerfile:

```Dockerfile
FROM apluslms/service-base:django-latest

ENV CONTAINER_TYPE="myapp" \
    DJANGO_LOCAL_SETTINGS="/srv/myapp-django-settings.py" \
    DJANGO_SECRET_KEY_FILE="/local/django/secret_key.py"

RUN adduser --system --no-create-home --disabled-password --gecos "A webapp server,,," --home /srv/myapp --ingroup nogroup myapp
RUN mkdir /srv/myapp && chown myapp.nogroup /srv/myapp

COPY myapp-cont-init.sh /etc/cont-init.d/myapp
COPY myapp-django-settings.py \
     myapp-init.sh \
     db-myapp-bootstrap.py \
     /srv/
COPY myapp /srv/myapp/

WORKDIR /srv/myapp/
RUN python3 -m compileall -q .
RUN pip_install -r requirements.txt && rm requirements.txt
RUN python3 manage.py compilemessages 2>&1
RUN create-db.sh myapp myapp django-migrate.sh

EXPOSE 8000
CMD [ "manage", "runserver", "0.0.0.0:8000" ]
```

and `myapp-django-settings.py`:

```python
STATIC_ROOT = '/local/myapp/static/'
MEDIA_ROOT = '/local/myapp/media/'
DATABASES = { 'default': {
    'ENGINE': 'django.db.backends.postgresql',
    'NAME': 'myapp' }}
CACHES = { 'default': {
    'BACKEND': 'django.core.cache.backends.filebased.FileBasedCache',
    'LOCATION': '/run/myapp/django-cache' }}
```

and `myapp-cont-init.sh`:

```shell
#!/bin/sh
. /usr/local/lib/cont-init-functions.sh
ENSURE_DIR_MODE=2755
ENSURE_DIR_USER=myapp
ENSURE_DIR_GROUP=nogroup

ensure_dir /run/myapp
ensure_dir /local/myapp
ensure_dir /local/myapp/static
ensure_dir /local/myapp/media
```

The example Django app uses local settings and secret key functions from a Django [essentials package](https://pypi.org/project/raphendyr-django-essentials/):

```python
update_settings_with_file(__name__,
                          environ.get('DJANGO_LOCAL_SETTINGS', 'local_settings'),
                          quiet='DJANGO_LOCAL_SETTINGS' in environ)
update_secret_from_file(__name__, environ.get('DJANGO_SECRET_KEY_FILE', 'secret_key'))
```
