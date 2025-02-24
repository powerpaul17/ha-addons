#!/usr/bin/with-contenv bashio

set -e
echoerr() { printf "%s\n" "$*" >&2; }

echoerr "Starting Komodo Periphery"

exec /usr/local/bin/periphery
