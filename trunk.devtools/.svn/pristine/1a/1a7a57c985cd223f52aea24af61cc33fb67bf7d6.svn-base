remote_workdir="/extra/remotemerge"
remote_libdir="/home/tools/lib/remotesvn"
days_to_keep=7

error() {
    echo "$(basename $0): error: $1" >&2
    exit 1
}

check_installed() {
    if ! which "$1" >/dev/null 2>&1; then
        error "Required tool \"$1\" not found in PATH; please install"
    fi
}
