#!/bin/sh
source .

# Export all relevant environment variables
# that are going to be used by envsubst for templates
export OPENLDAP_VOL_DIR=${OPENLDAP_VOL_DIR:-}
export OPENLDAP_TLS_CERT_FILE=${OPENLDAP_TLS_CERT_FILE:-}
export OPENLDAP_TLS_CERT_KEY_FILE=${OPENLDAP_TLS_CERT_KEY_FILE:-}
if [ ! -f ${OPENLDAP_TLS_CERT_FILE} ] || [ ! -f ${OPENLDAP_TLS_CERT_KEY_FILE} ]; then
    export OPENLDAP_TLS_COMMENT='# '
else
    export OPENLDAP_TLS_COMMENT=
fi
export OPENLDAP_DOMAIN="$(echo "$OPENLDAP_DOMAIN" | sed -E 's/\.?([a-z0-9]+)\.?/dc=\1,/g' | head -c-2)"
export OPENLDAP_DOMAIN=${OPENLDAP_DOMAIN:-dc=example,dc=org}
export OPENLDAP_TOP_LEVEL="$(echo "$OPENLDAP_DOMAIN" | sed -r 's/^dc\=([a-zA-Z0-9]+).*/\1/')"
export OPENLDAP_ADMIN_CN=${OPENLDAP_ADMIN_CN:-admin}
export OPENLDAP_ADMIN_PASSWD_RAW=${OPENLDAP_ADMIN_PASSWD:-password}
export OPENLDAP_ADMIN_PASSWD="$(slappasswd -s "$OPENLDAP_ADMIN_PASSWD_RAW")"
export OPENLDAP_ORGANIZATION=${OPENLDAP_ORGANIZATION:-"Example Company"}
export OPENLDAP_CONF_DIR=/usr/local/etc/openldap

OPENLDAP_SLAPD_CONF_DIR=${OPENLDAP_VOL_DIR}/etc/slapd

# Create directories if they don't already exist
mkdir -p ${OPENLDAP_SLAPD_CONF_DIR} ${OPENLDAP_VOL_DIR}/lmdb
if [ $? -ne 0 ]; then
    echo "Failed to create required data and configuration directories"
    exit 127
fi

INITIALIZE_DOMAIN=0

# Check if configuration database is empty, and if it is
# then generate and import the configuration
if [ -z "$(ls -A ${OPENLDAP_SLAPD_CONF_DIR})" ]; then
    envsubst < ${OPENLDAP_SLAPD_CONF_TMPL_DIR}/slapd.ldif.tmpl > ${OPENLDAP_SLAPD_CONF_DIR}/slapd.ldif
    envsubst < ${OPENLDAP_SLAPD_CONF_TMPL_DIR}/init.ldif.tmpl > ${OPENLDAP_SLAPD_CONF_DIR}/init.ldif
    slapadd -n 0 -F ${OPENLDAP_SLAPD_CONF_DIR} -l ${OPENLDAP_SLAPD_CONF_DIR}/slapd.ldif
    INITIALIZE_DOMAIN=1
fi

# Start SLAPD
echo "Starting slapd..."
/usr/local/libexec/slapd -F ${OPENLDAP_SLAPD_CONF_DIR} -d0 &

# If directory initialization is required
# perform ldapadd
if [ $INITIALIZE_DOMAIN -ne 0 ]; then
    echo "Initializing organization database..."
    sleep 2
    ldapadd -x -D "cn=${OPENLDAP_ADMIN_CN},${OPENLDAP_DOMAIN}" -w "${OPENLDAP_ADMIN_PASSWD_RAW}" -f ${OPENLDAP_SLAPD_CONF_DIR}/init.ldif
    echo "Organization initialization done..."
fi

# Wait for slapd process to exit
wait $!