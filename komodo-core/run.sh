#!/usr/bin/with-contenv bashio

set -e
echoerr() { printf "%s\n" "$*" >&2; }

echoerr "Starting Komodo"

exec /usr/local/bin/core
