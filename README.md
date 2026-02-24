# Docker OpenLDAP

This repository provides the Dockerfile and other files for building your own dockerized OpenLDAP server, making the process of setting up and deploying your own OpenLDAP server much easier.

In this configuration, the OpenLDAP server is mainly meant for keeping track of users and groups, thus by default, creating organizationalUnits of `ou=people,dc=example,dc=org` and `ou=groups,dc=example,dc=org`.

## Getting started

First you should build and tag the container. By default, the included [Containerfile](Containerfile) compiles OpenLDAP version 2.6.12.
```sh
$ docker build -t registry.example.com/openldap:2.6.12 . -f Containerfile
```

After the container building has finished, you can spin up the container using following commands:
```sh
$ docker run \
    -p 127.0.0.1:389:389 \
    -v ./_volume/openldap/config:/usr/local/etc/slapd.d \
    -v ./_volume/openldap/data:/usr/local/var/openldap-data \
    -e LDAP_DOMAIN=example.org \
    -e ADMIN_COMMON_NAME=admin \
    -e ADMIN_PASSWORD=<password> \
    -e ORGANIZATION_NAME="My awesome organization" \
    registry.example.com/openldap:2.6.12
```

List of possible environment variables is as follows:
- `LDAP_DOMAIN` specifies the domain to use, when setting up the directory. For instance, when setting it to `example.org`, the distinguished name for your organization would become `dc=example,dc=org`
- `ADMIN_COMMON_NAME` specifies the administrator (root user's) common name part (by default set to: admin)
- `ADMIN_PASSWORD` specifies the administrator user's password
- `ORGANIZATION_NAME` specifies the organization name part of the organization domain entry.

For volumes, `/usr/local/etc/slapd.d` specifies the DIT database location for OpenLDAP configuration and `/usr/local/var/openldap-data` specifies the location to MDB database.