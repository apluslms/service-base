#!/bin/sh -eu

prog=${0##*/}
user=$1
db=$2
shift 2

echo "[$prog] Creating database $db for $user"

# Ensure local working dir (expected by services etc)
sh /etc/cont-init.d/postgresql 2>&1

# Start and wait for postgresql daemon
psvc="/run/postgresql-service/"
cp -a /etc/services.d/postgresql/ "$psvc"
chmod +x "$psvc/run"
echo "[$prog] Starting the DB server"
s6-supervise "$psvc" & pid=$!
sleep 0.3 # wait for supervise to get up
s6-svc -u -wU -T 10000 "$psvc"
if [ $? -ne 0 ]; then
    echo "[$prog] Server didn't start within a timelimit" >&2
    s6-svc -q -wD -T 2000 "$psvc"
    kill "$pid"
    exit 1
fi
echo "[$prog] Server is up. Creating the user and the db."

# Create the user and the database
setuidgid postgres createuser "$user"
setuidgid postgres createdb -O "$user" "$db"

# Initialize the database
if [ $# -gt 0 ]; then
    echo "[$prog] Populating the database with: $*"
    env USER="$user" \
        DATABASE_USER="$user" \
        DATABASE_NAME="$db" \
        DATABASE_IS_EMPTY=true \
        setuidgid "$user" "$@"
fi

# Dump the database
echo "[$prog] Export DB to /srv/db-$db.sql.gz"
setuidgid "$user" pg_dump "$db" \
    | sed '/^\s*--/d;/^$/d' \
    | grep -vE '^(CREATE|COMMENT ON) EXTENSION' \
    | gzip -c > "/srv/db-$db.sql.gz"

# Stop postgresql daemon
echo "[$prog] All done, shutting down"
if ! s6-svc -d -wD -T 10000 "$psvc"; then
    echo "[$prog] Server didn't shutdown within a timelimit" >&2
    s6-svc -q -wD -T 2000 "$psvc"
fi
kill $pid 2>/dev/null
echo "[$prog] Waiting for the supervisor to die.."
for i in `seq 50`; do kill -0 $pid 2>/dev/null || break; sleep 0.2; done
if kill -0 $pid 2>/dev/null; then
    echo "[$prog] supervisor is not dead, killing it" >&2
    kill -9 $pid;
fi

# clean
rm -rf /var/run/* /run/* /local/
