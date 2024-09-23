#!/usr/bin/with-contenv bashio

set -e
echoerr() { printf "%s\n" "$*" >&2; }

export SEMAPHORE_CONFIG_PATH="${SEMAPHORE_CONFIG_PATH:-/etc/semaphore}"
export SEMAPHORE_TMP_PATH="${SEMAPHORE_TMP_PATH:-/tmp/semaphore}"

export SEMAPHORE_DB_DIALECT="${SEMAPHORE_DB_DIALECT:-mysql}"
export SEMAPHORE_DB_HOST="${SEMAPHORE_DB_HOST:-0.0.0.0}"
export SEMAPHORE_DB_PATH="${SEMAPHORE_DB_PATH:-/var/lib/semaphore}"
export SEMAPHORE_DB_PORT="${SEMAPHORE_DB_PORT:-}"
export SEMAPHORE_DB="${SEMAPHORE_DB:-semaphore}"
export SEMAPHORE_DB_USER="${SEMAPHORE_DB_USER:-semaphore}"
export SEMAPHORE_DB_PASS="${SEMAPHORE_DB_PASS:-semaphore}"

export SEMAPHORE_ADMIN="${SEMAPHORE_ADMIN:-admin}"
export SEMAPHORE_ADMIN_EMAIL="${SEMAPHORE_ADMIN_EMAIL:-admin@localhost}"
export SEMAPHORE_ADMIN_NAME="${SEMAPHORE_ADMIN_NAME:-Semaphore Admin}"
export SEMAPHORE_ADMIN_PASSWORD="${SEMAPHORE_ADMIN_PASSWORD:-semaphorepassword}"

export SEMAPHORE_LDAP_ACTIVATED="${SEMAPHORE_LDAP_ACTIVATED:-no}"
export SEMAPHORE_LDAP_HOST="${SEMAPHORE_LDAP_HOST:-}"
export SEMAPHORE_LDAP_PORT="${SEMAPHORE_LDAP_PORT:-}"
export SEMAPHORE_LDAP_DN_BIND="${SEMAPHORE_LDAP_DN_BIND:-}"
export SEMAPHORE_LDAP_PASSWORD="${SEMAPHORE_LDAP_PASSWORD:-}"
export SEMAPHORE_LDAP_DN_SEARCH="${SEMAPHORE_LDAP_DN_SEARCH:-}"
export SEMAPHORE_LDAP_MAPPING_USERNAME="${SEMAPHORE_LDAP_MAPPING_USERNAME:-uid}"
export SEMAPHORE_LDAP_MAPPING_FULLNAME="${SEMAPHORE_LDAP_MAPPING_FULLNAME:-cn}"
export SEMAPHORE_LDAP_MAPPING_EMAIL="${SEMAPHORE_LDAP_MAPPING_EMAIL:-mail}"

export SEMAPHORE_ACCESS_KEY_ENCRYPTION="${SEMAPHORE_ACCESS_KEY_ENCRYPTION:-}"

[ -d "${SEMAPHORE_TMP_PATH}" ] || mkdir -p "${SEMAPHORE_TMP_PATH}" || {
    echo "Can't create Semaphore tmp path ${SEMAPHORE_TMP_PATH}."
    exit 1
}

[ -d "${SEMAPHORE_CONFIG_PATH}" ] || mkdir -p "${SEMAPHORE_CONFIG_PATH}" || {
    echo "Can't create Semaphore config path ${SEMAPHORE_CONFIG_PATH}."
    exit 1
}

[ -d "${SEMAPHORE_DB_PATH}" ] || mkdir -p "${SEMAPHORE_DB_PATH}" || {
    echo "Can't create Semaphore data path ${SEMAPHORE_DB_PATH}."
    exit 1
}

# Check if $SEMAPHORE_DB_HOST contains port number.
case "$SEMAPHORE_DB_HOST" in
  *:*)
    SEMAPHORE_DB_PORT=$(echo "$SEMAPHORE_DB_HOST" | cut -d ':' -f 2)
    SEMAPHORE_DB_HOST=$(echo "$SEMAPHORE_DB_HOST" | cut -d ':' -f 1)
    ;;
  *)
esac

# Ping database if it is not BoltDB
if [ "${SEMAPHORE_DB_DIALECT}" != 'bolt' ]; then
  echoerr "Attempting to connect to database ${SEMAPHORE_DB} on ${SEMAPHORE_DB_HOST}:${SEMAPHORE_DB_PORT} with user ${SEMAPHORE_DB_USER} ..."
  TIMEOUT=30

  while ! $(nc -z "$SEMAPHORE_DB_HOST" "$SEMAPHORE_DB_PORT") >/dev/null 2>&1; do
      TIMEOUT=$(expr "$TIMEOUT" - 1)

      if [ "$TIMEOUT" -eq 0 ]; then
          echoerr "Could not connect to database server. Exiting."
          exit 1
      fi

      echo -n "."
      sleep 1
  done
fi

if [ -n "${SEMAPHORE_DB_PORT}" ]; then
    SEMAPHORE_DB_HOST="${SEMAPHORE_DB_HOST}:${SEMAPHORE_DB_PORT}"
fi

case ${SEMAPHORE_DB_DIALECT} in
    mysql)
        SEMAPHORE_DB_DIALECT_ID=1
        ;;
    bolt)
        SEMAPHORE_DB_DIALECT_ID=2
        SEMAPHORE_DB_HOST=${SEMAPHORE_DB_PATH}/database.boltdb
        ;;
    postgres)
        SEMAPHORE_DB_DIALECT_ID=3
        ;;
    *)
        echoerr "Unknown database dialect: ${SEMAPHORE_DB_DIALECT}"
        exit 1
        ;;
esac

if [ ! -f "${SEMAPHORE_CONFIG_PATH}/config.json" ]; then
    echoerr "Generating ${SEMAPHORE_TMP_PATH}/config.stdin ..."
    cat << EOF > "${SEMAPHORE_TMP_PATH}/config.stdin"
${SEMAPHORE_DB_DIALECT_ID}
EOF

    if [ "${SEMAPHORE_DB_DIALECT}" = "bolt" ]; then
        cat << EOF >> "${SEMAPHORE_TMP_PATH}/config.stdin"
${SEMAPHORE_DB_HOST}
EOF
    else
        cat << EOF >> "${SEMAPHORE_TMP_PATH}/config.stdin"
${SEMAPHORE_DB_HOST}
${SEMAPHORE_DB_USER}
${SEMAPHORE_DB_PASS}
${SEMAPHORE_DB}
EOF
    fi

    cat << EOF >> "${SEMAPHORE_TMP_PATH}/config.stdin"
${SEMAPHORE_TMP_PATH}
${SEMAPHORE_WEB_ROOT:-}
no
no
no
no
no
${SEMAPHORE_LDAP_ACTIVATED}
EOF

    if [ "${SEMAPHORE_LDAP_ACTIVATED}" = "yes" ]; then
        cat << EOF >> "${SEMAPHORE_TMP_PATH}/config.stdin"
${SEMAPHORE_LDAP_HOST}:${SEMAPHORE_LDAP_PORT}
${SEMAPHORE_LDAP_NEEDTLS:-no}
${SEMAPHORE_LDAP_DN_BIND}
${SEMAPHORE_LDAP_PASSWORD}
${SEMAPHORE_LDAP_DN_SEARCH}
${SEMAPHORE_LDAP_SEARCH_FILTER:-(uid=%s)}
${SEMAPHORE_LDAP_MAPPING_DN:-dn}
${SEMAPHORE_LDAP_MAPPING_USERNAME}
${SEMAPHORE_LDAP_MAPPING_FULLNAME}
${SEMAPHORE_LDAP_MAPPING_EMAIL}
EOF
    fi;

    cat << EOF >> "${SEMAPHORE_TMP_PATH}/config.stdin"
${SEMAPHORE_CONFIG_PATH}
${SEMAPHORE_ADMIN}
${SEMAPHORE_ADMIN_EMAIL}
${SEMAPHORE_ADMIN_NAME}
${SEMAPHORE_ADMIN_PASSWORD}
EOF

    echoerr "Executing semaphore setup"
    if test "$#" -ne 1; then
        /usr/local/bin/semaphore setup - < "${SEMAPHORE_TMP_PATH}/config.stdin"
    else
        "$1" setup - < "${SEMAPHORE_TMP_PATH}/config.stdin"
    fi
fi

# Set environment variables according to configuration

SEMAPHORE_EMAIL_ALERT=$(bashio::config 'email_enabled')
SEMAPHORE_EMAIL_SENDER=$(bashio::config 'email_sender')
SEMAPHORE_EMAIL_HOST=$(bashio::config 'email_host')
SEMAPHORE_EMAIL_PORT=$(bashio::config 'email_port')
SEMAPHORE_EMAIL_USERNAME=$(bashio::config 'email_username')
SEMAPHORE_EMAIL_PASSWORD=$(bashio::config 'email_password')
SEMAPHORE_EMAIL_SECURE=$(bashio::config 'email_secure')

SEMAPHORE_SLACK_ALERT=$(bashio::config 'slack_enabled')
SEMAPHORE_SLACK_URL=$(bashio::config 'slack_url')

if test -f "${SEMAPHORE_CONFIG_PATH}/packages.txt"; then
    echoerr "Installing additional system dependencies"
    apk add --no-cache --upgrade \
        $(cat "${SEMAPHORE_CONFIG_PATH}/packages.txt" | xargs)
else
    echoerr "No additional system dependencies to install"
fi

if test -f "${SEMAPHORE_CONFIG_PATH}/requirements.txt"; then
    echoerr "Installing additional python dependencies"
    pip3 install --upgrade \
        -r "${SEMAPHORE_CONFIG_PATH}/requirements.txt"
else
    echoerr "No additional python dependencies to install"
fi

echoerr "Starting semaphore server"
if test "$#" -ne 1; then
    exec /usr/local/bin/semaphore server  --config "${SEMAPHORE_CONFIG_PATH}/config.json"
else
    exec "$@"
fi
