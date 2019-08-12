#!/bin/sh -eu

bootstrap=${1:-/srv/db-${DATABASE_NAME:-unknown}-bootstrap.py}

if [ -e requirements.txt ]; then
    # Create missing migrations.. This is mostly to notify developer, that there is missing migrations
    python3 manage.py makemigrations --no-input --no-color | tee /tmp/new-migrations.log
    for migration in $(grep -E '/migrations/.*\.py$' /tmp/new-migrations.log | sed 's/^\s*//'); do
        echo "=== created migration $migration"
        cat "$migration"
        echo " -------------------- "
    done
fi

python3 manage.py migrate --noinput -v0

if [ "$DATABASE_IS_EMPTY" = "true" ] && [ -e "$bootstrap" ]; then
    python3 "$bootstrap"
fi
