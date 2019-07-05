#!/usr/bin/with-contenv /bin/sh
set -eu

user=
db=
db_init=
init=
app_path=

while [ $# -gt 0 ]; do
    case "$1" in
        -u) user=$2 ; shift ;;
        -d) db=$2 ; shift ;;
        -s) db_init=$2 ; shift ;;
        -i) init=$2 ; shift ;;
        -a) app_path=$2 ; shift ;;
        --) shift ; break ;;
        -*) echo "ERROR: Invalid option '$1' for $0" >&2 ; exit 64 ;;
        *) break ;;
    esac
    shift
done

[ "$user" ] || user=${CONTAINER_TYPE:-unknown}
[ "$db" ] || db=$user
[ "$app_path" ] || app_path=/srv/$user
app_name=${app_path%/}
app_name=${app_name##*/}
[ "$db_init" ] || db_init=/srv/$app_name-setup.py
[ "$init" ] || init=/srv/$app_name-init.sh

if [ ! -e "$app_path/manage.py" ]; then
    echo "ERROR: No $app_path/manage.py present"
    echo "usage: $0 [-u user] [-d db_name] [-s db_setup_script] [-i init_sript] [-a app_path]"
    exit 1
fi

cd "$app_path"
export HOME="$app_path"


# Use python from virtualenv if present
[ -e "/local/venv_$app_name/bin/activate" ] && . /local/venv_$app_name/bin/activate

# Ensure database state
[ -e "$db_init" ] && init-django-db.sh "$user" "$db" "$db_init"

# With dev code, we need to rerun few init tasks
if [ -e requirements.txt ]; then
    python3 manage.py compilemessages -v0 || true
fi
setuidgid "$user" python3 manage.py collectstatic --noinput -v0

# Run init script if present
[ -e "$init" ] && env "USER=$user" "HOME=$app_path" "$init"

# Execute main script
if [ "${1:-}" = "manage" ]; then
    shift
    exec setuidgid "$user" python3 manage.py "$@"
elif [ "${1:-}" ]; then
    exec setuidgid "$user" "$@"
else
    echo "ERROR: no command given, printing help..."
    exec setuidgid "$user" python3 manage.py help
fi
