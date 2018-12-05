#!/bin/sh

user=$1
db=$2
setup_script=$3

if ! setuidgid "$user" psql -U "$user" "$db" "--command=SELECT version();" >/dev/null 2>&1; then
    setuidgid postgres createuser "$user"
    setuidgid postgres createdb -O "$user" "$db"
    dbfile="/srv/db_$db.sql.gz"
    if [ -e "$dbfile" ]; then
        echo " .. Creating DB from $dbfile .."
        gunzip -c "$dbfile" | setuidgid "$user" psql -U "$user" "$db" >/dev/null
    else
        echo " .. Creating DB with migrate and setup script .."
        setuidgid "$user" python3 manage.py migrate --noinput -v0
        setuidgid "$user" python3 "$setup_script"
    fi
else
    setuidgid "$user" python3 manage.py migrate --noinput -v0
fi


