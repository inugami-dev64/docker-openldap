# Docker OpenLDAP

This repository provides the Dockerfile and other files for building your own dockerized OpenLDAP server, making the process of setting up and deploying your own OpenLDAP server much easier.

In this configuration, the OpenLDAP server is mainly meant for keeping track of users and groups, thus by default, creating organizationalUnits of `ou=people,dc=example,dc=org` and `ou=groups,dc=example,dc=org`.

## Getting started

First you should build and tag the container. By default, the included [Containerfile](Containerfile) compiles OpenLDAP version 2.6.13.
```sh
$ docker build -t registry.example.com/openldap:2.6.13 . -f Dockerfile
```

After the container building has finished, you can spin up the container using following commands:
```sh
$ docker run \
    -p 127.0.0.1:389:389 \
    -v ./_volume/openldap:/var/lib/openldap \
    -e OPENLDAP_LDAP_DOMAIN=example.org \
    -e OPENLDAP_ADMIN_CN=admin \
    -e OPENLDAP_ADMIN_PASSWD=<password> \
    -e OPENLDAP_ORGANIZATION="My awesome organization" \
    registry.example.com/openldap:2.6.13
```

Alternatively for running in TLS mode:
```sh
$ docker run \
    -p 127.0.0.1:389:389 \
    -v ./_volume/openldap:/var/lib/openldap \
    -v ./_volume/certs:/etc/certs/ldap:ro \
    -e OPENLDAP_TLS_CERT_FILE=/etc/certs/ldap/fullchain.pem \
    -e OPENLDAP_TLS_CERT_KEY_FILE=/etc/certs/ldap/privkey.pem \
    -e OPENLDAP_LDAP_DOMAIN=example.org \
    -e OPENLDAP_ADMIN_CN=admin \
    -e OPENLDAP_ADMIN_PASSWD=<password> \
    -e OPENLDAP_ORGANIZATION="My awesome organization" \
    registry.example.com/openldap:2.6.13
```

List of possible environment variables is as follows:
- `OPENLDAP_DOMAIN` specifies the domain name to use, in hostname notation (by default: `example.org`);
- `OPENLDAP_ADMIN_CN` common name for the root user (by default: `admin`);
- `OPENLDAP_ADMIN_PASSWD` password for the root user (by default: `password`);
- `OPENLDAP_ORGANIZATION` name of the organization in its domain entry (by default: `Example Organization`).
- `OPENLDAP_TLS_CERT_FILE` path to the TLS certificate file
- `OPENLDAP_TLS_CERT_KEY_FILE` path to the TLS certificate key file.

Container runs `slapd` with uid/gid of 101, so make sure that volumes have appropriate permissions.