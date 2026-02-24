#!/bin/sh
LMDB_DIR=/usr/local/var/openldap-data
CONFIG_DIR=/usr/local/etc/slapd.d
CONFIG_FILE_DIR=/usr/local/etc/openldap

# Export all relevant environment variables
# that the configuration is going to use
export LETSENCRYPT_DOMAIN=${LETSENCRYPT_DOMAIN:-}
tls_comment=
if [ "${LETSENCRYPT_DOMAIN}" == '' ]; then
    export TLS_COMMENT='# '
else
    export TLS_COMMENT=
fi
export LDAP_SUFFIX=$(echo "$LDAP_DOMAIN" | sed -E 's/\.?([a-z0-9]+)\.?/dc=\1,/g' | head -c-2)
export LDAP_SUFFIX=${LDAP_SUFFIX:-dn=example,dc=org}
export LDAP_TOP_LEVEL=$(echo "$LDAP_SUFFIX" | sed -r 's/^dc\=([a-zA-Z0-9]+).*/\1/')
export LDAP_SECRET=$(slappasswd -s ${ADMIN_PASSWORD:-password})
export ORGANIZATION_NAME=${ORGANIZATION_NAME:-"Example Company"}

INITIALIZE_DOMAIN=0

# Check if configuration database is empty, and if it is
# then generate and import the configuration
if [ -z "$(ls -A $CONFIG_DIR)" ]; then
    envsubst < $CONFIG_FILE_DIR/slapd.ldif.tmpl > $CONFIG_FILE_DIR/slapd.ldif
    envsubst < $CONFIG_FILE_DIR/init.ldif.tmpl > $CONFIG_FILE_DIR/init.ldif
    slapadd -n 0 -F $CONFIG_DIR -l $CONFIG_FILE_DIR/slapd.ldif
    INITIALIZE_DOMAIN=1
fi

# Start SLAPD
echo "slapd starting..."
/usr/local/libexec/slapd -d 0 -F $CONFIG_DIR &

# If domain directory initialization is required
# perform ldapadd
if [ ! $INITIALIZE_DOMAIN == 0 ]; then
    echo "Initializing organization database..."
    sleep 2
    ldapadd -x -D "cn=admin,${LDAP_SUFFIX}" -w "${ADMIN_PASSWORD}" -f $CONFIG_FILE_DIR/init.ldif
    echo "Organization initialization done..."
fi

# Wait for slapd process to exit
wait $!