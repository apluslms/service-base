ensure_dir() {
    [ "$1" ] || return 1
    _path=$1
    _mode=${2:-${ENSURE_DIR_MODE:-}}
    _user=${3:-${ENSURE_DIR_USER:-${ENSURE_USER:-}}}
    _group=${4:-${ENSURE_DIR_GROUP:-${ENSURE_GROUP:-$_user}}}
    if [ -d "$_path" ]; then
        [ "$_user" ] && chown "$_user:$_group" "$_path"
        [ "$_mode" ] && chmod "$_mode" "$_path"
    else
        set --
        [ "$_mode" ] && set -- "$@" -m "$_mode"
        [ "$_user" ] && set -- "$@" -o "$_user"
        [ "$_group" ] && set -- "$@" -g "$_group"
        install -d "$@" "$_path"
    fi
    unset _path _mode _user _group
}

ensure_file() {
    [ "$1" ] || return 1
    _path=$1
    _mode=${2:-${ENSURE_FILE_MODE:-}}
    _user=${3:-${ENSURE_FILE_USER:-${ENSURE_USER:-}}}
    _group=${4:-${ENSURE_FILE_GROUP:-${ENSURE_GROUP:-$_user}}}
    if ! [ -f "$_path" ]; then
        touch "$_path"
    fi
    [ "$_user" ] && chown "$_user:$_group" "$_path"
    [ "$_mode" ] && chmod "$_mode" "$_path"
    unset _path _mode _user _group
}

get_simple_conf() {
    [ "$1" ] || return 1
    _path=${2:-${SIMPLE_CONF_PATH:-}}
    [ "$_path" -a -e "$_path" ] || return 2
    grep -E '^\s*'"$1"'\s*=' $_path | cut '-d=' '-f2-'
    unset _path
}

strip_quotes() {
    sed 's/^\s*["'"'"']//;s/["'"'"']\s*$//'
}
