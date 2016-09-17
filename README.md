[![License: MIT](https://img.shields.io/badge/licence-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://travis-ci.org/LasLabs/docker-odoo.svg?branch=master)](https://travis-ci.org/LasLabs/docker-odoo)

Alpine Odoo
===========

This provides an Odoo instance for Docker using Alpine Linux.

It aims to operate in the exact same way as the official Odoo Docker image,
although there are also some additional features that are helpful for developers
intending to use OCA modules.

One of the main features added to this container is that when an addons path is
mounted as a volume, any dependencies in an `oca_dependencies.txt` file will be
downloaded and added into Odoo automagically. The same goes for Python dependencies
in a `requirements.txt`.

Another major change is that one Dockerfile supports builds for all Odoo versions.
The default version is the newest production Odoo, but can be changed by setting
the `ODOO_VERSION` environment variable to the version you would like to use.

The Docker build for this repo is hosted [on Dockerhub](https://hub.docker.com/r/laslabs/alpine-odoo/).

Configuration
=============

To configure this module, you need to:

* Have a pre-existing Docker installation

Usage
=====

Start a Postgres Server
-----------------------

You can use any Postgres server or Docker image for this. We will use
 [kiasaki/alpine-postgres](https://hub.docker.com/r/kiasaki/alpine-postgres/) here:

    docker pull kiasaki/alpine-postgres
    docker run -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo --name db kiasaki/alpine-postgres:9.6

Start an Odoo Instance
----------------------

    docker run -p 8069:8069 --name odoo --link db:db -t laslabs/alpine-odoo

The alias of the container running Postgres must be db for Odoo to be able
 to connect to the Postgres server.

Stop and Restart an Odoo Instance
---------------------------------

    docker stop odoo
    docker start -a odoo

Stop and Restart a Postgres Server
----------------------------------

When a Postgres server is restarted, the Odoo instances linked to it must
 also be restarted because the server address will have changed.

Custom Odoo Configuration
-------------------------

The Odoo configuration file of this instance is located at `/etc/odoo/odoo.conf`.

In order to change the configuration, you would use a volume when starting the container:

    docker run -v /path/to/local/directory:/etc/odoo -p 8069:8069 --name odoo --link db:db -t odoo

In the above example, you would put your configuration file at `/path/to/local/directory/odoo.conf`
 on the docker host.

You should use the [Odoo official Docker configuration template](https://github.com/odoo/docker/blob/master/10.0/odoo.conf)
 to write your configuration file, because some values are written into the container.
 
Note that the addons path is overridden in the Entrypoint in order to allow 
for automatic discovery of addons from the following directories:

 * `/usr/lib/python2.7/site-packages/openerp/addons`
 * `/usr/lib/python2.7/site-packages/odoo/addons`
 * `/opt/addons`
 * `/opt/odoo/addons`
 * `/mnt/addons`

You can also directly specify Odoo arguments inline. Those arguments must
 be given after the keyword `--` in the command-line, such as:

    docker run -p 8069:8069 --name odoo --link db:db -t odoo -- --db-filter=odoo_db_.*

Mount Custom Addons
-------------------

You can mount your own Odoo addons directory at `/mnt/addons`, such as:

    docker run -v /path/to/addons:/mnt/addons -p 8069:8069 --name odoo --link db:db -t odoo

If the mounted directory contains an `oca_dependencies.txt` file, those dependencies
 will automatically be downloaded and added into the Odoo instance upon starting a
 container.

If the mounted directory contains a `requirements.txt` file, those dependencies will
 automatically be installed into the Odoo environment's Python.

Note that the addons directory must be a directory containing modules. Odoo
 does not recursively scan directories for modules.

Environment Variables
=====================

The following environment variables are available for your configuration
pleasure:

| Name | Default | Description |
|-------------------------|-----------|------------------------------------------------------------------------------------------------------------------------------------------|
| ODOO_VERSION | 10.0 | The Odoo version that is being used. |
| ODOO_REPO | odoo/odoo | The Github repository to download Odoo from. |
| ODOO_CONFIG_DIR | /etc/odoo | The directory inside of the container where the configuration is stored. |
| ODOO_CONFIG | odoo.conf | The name of the Odoo configuration file inside of the container. |
| PSQL_HOST | db | The address of the postgres server. If you used a Postgres container, set to the name of the container. |
| PSQL_PORT | 5434 | The port that the PostgreSQL server is listening on. |
| PSQL_USER | odoo | The PostgreSQL role that Odoo will use to connect with. If you used a Postgres container, set to same value as `POSTGRES_USER` |
| PSQL_PASSWORD | odoo | The password for the PostgreSQL role that Odoo will connect with. If you used a Postgres container, set to same value as `POSTGRES_USER` |
| SKIP_DEPENDS | 0 | Set to `1` in order to skip dependency download/installation from the mounted volume's `oca_dependencie.txt` and `requirements.txt`. |
| WKHTMLTOX_VERSION | 0.12 | The WKHTMLTOX Major and Minor versions. |
| WKHTMLTOX_PATCH_VERSION | 4 | The WKHTMLTOX Patch version. |

Docker Compose Examples
=======================

The simplest `docker-compose.yml` file would look like:

    version: '2'
    services:
      web:
        image: docker pull laslabs/alpine-odoo
        depends_on:
          - db
        ports:
          - "8069:8069"
      db:
        image: kiasaki/alpine-postgres:9.6
        environment:
          - POSTGRES_PASSWORD=odoo
          - POSTGRES_USER=odoo



Known Issues / Roadmap
======================

* Create a Python base.
* Create an Python-Wkhtmltox-XVFB base.
* Add more compose examples.
* Odoo is currently running as root due to permissions issues with mounted
  addons.
* Test OCA dependencies/Python requirements installation via the addon mount.
* Automatic resolution of binary depedencies - I am sure there are some OCA
  repos that will break this.
* Audit `apk` installations once binary dependencies resolved; a lot are there
  as possible build dependencies for repos, and aren't actually used.

Bug Tracker
===========

Bugs are tracked on [GitHub Issues](https://github.com/LasLabs/docker-odoo/issues).
In case of trouble, please check there to see if your issue has already been reported.
If you spotted it first, help us to smash it by providing detailed and welcomed feedback.

Credits
=======

Contributors
------------

* Dave Lasley <dave@laslabs.com>

Maintainer
----------

[![LasLabs Inc.](https://laslabs.com/logo.png)](https://laslabs.com)

This module is maintained by [LasLabs Inc.](https://laslabs.com)

* https://github.com/LasLabs/docker-odoo
