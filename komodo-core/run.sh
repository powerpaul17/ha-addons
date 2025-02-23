#!/usr/bin/with-contenv bashio

set -e
echoerr() { printf "%s\n" "$*" >&2; }

echoerr "Starting Komodo"

export KOMODO_LOCAL_AUTH=true

exec /usr/local/bin/core
