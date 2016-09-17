#!/bin/bash

set -e

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the Odoo process if not present in the config file
: ${PSQL_HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PSQL_PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${PSQL_USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PSQL_PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=("--config=${ODOO_CONFIG}")

ADDONS=("/usr/lib/python2.7/site-packages/openerp/addons" \
        "/usr/lib/python2.7/site-packages/odoo/addons" \
        "/opt/addons" \
        "/opt/odoo/addons" \
        "/mnt/addons" \
        )

# Install requirements.txt and oca_dependencies.txt from root of mount
if [[ "${SKIP_DEPENDS}" != "1" ]] ; then
    export VERSION=$ODOO_VERSION
    clone_oca_dependencies /opt/community /mnt/addons
    if [[ -a "/mnt/addons/requirements.txt" ]]; then
        pip install -r /mnt/addons/requirements.txt
    fi
    for dir in /opt/community/*/ ; do
        ADDONS+=("$dir")
    done
    ADDONS="$(get_addons ${ADDONS[*]})"
    DB_ARGS+=("--addons-path=${ADDONS}")
fi

# Pull database from config file if present & validate
function check_config() {
    param="$1"
    value="$2"
    if ! grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_CONFIG" ; then
        DB_ARGS+=("--${param}")
        DB_ARGS+=("${value}")
   fi;
}
check_config "db_host" "$PSQL_HOST"
check_config "db_port" "$PSQL_PORT"
check_config "db_user" "$PSQL_USER"
check_config "db_password" "$PSQL_PASSWORD"

# Execute
case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec odoo "$@"
        else
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1
