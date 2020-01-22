#!/bin/sh -eu

user=$1
db=$2
shift 2

# Ensure local working dir (expected by services etc)
mkdir -p /local/

# Create and start postgresql daemon
pver=$(ls /usr/lib/postgresql/ | tail -n1)
sh /etc/cont-init.d/postgresql 2>&1
s6-setuidgid postgres \
 s6-env LANG=C.UTF-8 HOME=/var/lib/postgresql/ \
 "/usr/lib/postgresql/$pver/bin/postgres" \
  -c "config_file=/etc/postgresql/$pver/main/postgresql.conf" 2>&1 \
 & pid=$!

# wait for it to start
while ! setuidgid postgres psql "--command=SELECT version();" >/dev/null 2>&1; do
    sleep 0.2
done

# Create the user and the database
setuidgid postgres createuser "$user"
setuidgid postgres createdb -O "$user" "$db"

# Initialize the database
if [ $# -gt 0 ]; then
    exec env \
        USER="$user" \
        DATABASE_USER="$user" \
        DATABASE_NAME="$db" \
        DATABASE_IS_EMPTY=true \
        setuidgid "$user" "$@"
fi

# Dump the database
setuidgid "$user" pg_dump "$db" \
    | sed '/^\s*--/d;/^$/d' \
    | grep -vE '^(CREATE|COMMENT ON) EXTENSION' \
    | gzip -c > "/srv/db-$db.sql.gz"

# Stop postgresql daemon
kill $pid
for i in `seq 50`; do
    kill -0 $pid 2>/dev/null || break
    sleep 0.2
done
kill -0 $pid 2>/dev/null && kill -9 $pid

# clean
rm -rf /var/run/* /run/* /local/
