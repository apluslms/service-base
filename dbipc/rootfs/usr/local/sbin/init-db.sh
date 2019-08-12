#!/bin/sh

user=$1
db=$2
shift 2

if ! setuidgid "$user" psql -U "$user" "$db" "--command=SELECT version();" >/dev/null 2>&1; then
    setuidgid postgres createuser "$user"
    setuidgid postgres createdb -O "$user" "$db"
    dbfile="/srv/db-$db.sql.gz"
    if [ -e "$dbfile" ]; then
        echo " .. Creating a DB using a dump from $dbfile .."
        gunzip -c "$dbfile" | setuidgid "$user" psql -U "$user" "$db" >/dev/null
    elif [ $# -gt 0 ]; then
        echo " .. Creating a DB using a setup script .."
        exec env \
            USER="$user" \
            DATABASE_USER="$user" \
            DATABASE_NAME="$db" \
            DATABASE_IS_EMPTY=true \
            setuidgid "$user" "$@"
    else
        echo "Didn't find database dump from $dbfile and you didn't give initialization command, thus the script can't initialize the database" >&2
        exit 1
    fi
elif [ $# -gt 0 ]; then
    echo " .. Updating the DB using a setup script .."
    exec env \
        USER="$user" \
        DATABASE_USER="$user" \
        DATABASE_NAME="$db" \
        DATABASE_IS_EMPTY= \
        setuidgid "$user" "$@"
fi
