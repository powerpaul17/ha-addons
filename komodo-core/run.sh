#!/usr/bin/with-contenv bashio

set -e
echoerr() { printf "%s\n" "$*" >&2; }

echoerr "Starting Komodo"

export KOMODO_PASSKEY=$(bashio::config 'periphery_passkey')

export KOMODO_DISABLE_CONFIRM_DIALOG=$(bashio::config 'disable_confirm_dialog')
export KOMODO_DISABLE_USER_REGISTRATION=$(bashio::config 'disable_user_registration')

export KOMODO_LOCAL_AUTH=true

exec /usr/local/bin/core
