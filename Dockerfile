# Copyright 2016-TODAY LasLabs Inc.
# License MIT (https://opensource.org/licenses/MIT).

FROM alpine:3.4
MAINTAINER "LasLabs Inc." <support@laslabs.com>

ENV ODOO_VERSION="${ODOO_VERSION:-10.0}"
ENV ODOO_REPO="${ODOO_REPO:-odoo/odoo}"

ENV ODOO_CONFIG_DIR="${ODOO_CONFIG_DIR:-/etc/odoo}"
ENV ODOO_CONFIG="${ODOO_CONFIG_DIR}/${ODOO_CONFIG_FILE:-odoo.conf}"

ENV WKHTMLTOX_VERSION="${WKHTMLTOX_VERSION:-0.12}"
ENV WKHTMLTOX_RELEASE="${WKHTMLTOX_VERSION}.${WKHTMLTOX_SUBVERSION:-4}"

ENV WKHTMLTOX_URI="http://download.gna.org/wkhtmltopdf/${WKHTMLTOX_VERSION}/${WKHTMLTOX_RELEASE}/wkhtmltox-${WKHTMLTOX_RELEASE}_linux-generic-amd64.tar.xz"
ENV ODOO_URI="https://github.com/$ODOO_REPO/archive/${ODOO_BRANCH:-$ODOO_VERSION}.tar.gz"
ENV MQT_URI="https://github.com/OCA/maintainer-quality-tools/archive/master.tar.gz"

# Odoo Binary Dependencies
RUN set -x; \
    apk add --no-cache \
        alpine-sdk \
        bash \
        build-base \
        curl \
        ca-certificates \
        freetype \
        fontconfig \
        git \
        jpeg \
        jpeg-dev \
        libffi \
        libffi-dev \
        libxml2 \
        libxml2-dev \
        libxslt \
        libxslt-dev \
        linux-headers \
        nodejs \
        openldap-dev \
        openssl-dev \
        postgresql \
        postgresql-client \
        postgresql-dev \
        python \
        python-dev \
        tar \
        xvfb \
        xz \
        zlib-dev

# Install Pip
RUN curl --silent --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py | python

# Wkhtmltox Headless Using XVFB
RUN curl -sL $WKHTMLTOX_URI \
    | tar -xJ \
    && mkdir /opt \
    && cp wkhtmltox/bin/* /opt/ \
    && rm -Rf wkhtmltox* \
    && echo -e '#!/bin/bash\nxvfb-run -a --server-args="-screen 0, 1024x768x24" /opt/wkhtmltopdf -q $*' > /usr/bin/wkhtmltopdf \
    && echo -e '#!/bin/bash\nxvfb-run -a --server-args="-screen 0, 1024x768x24" /opt/wkhtmltoimage -q $*' > /usr/bin/wkhtmltoimage \
    && chmod a+x /usr/bin/wkhtmltopdf \
    && chmod a+x /usr/bin/wkhtmltoimage

# Install NPM depends
RUN npm install -g clean-css \
                   less

# Install Odoo
RUN adduser -S odoo

RUN mkdir -p /tmp/odoo \
    && mkdir -p /opt/odoo \
    && curl -sL $ODOO_URI \
    | tar xz -C /tmp/odoo --strip 1 \
    && cd /tmp/odoo \
    && pip install --no-cache-dir -r ./requirements.txt \
    && pip install --no-cache-dir . \
    && mv ./addons /opt/odoo \
    && chown -R odoo /opt/odoo

RUN mkdir -p /etc/odoo \
             /mnt/addons \
             /opt/addons \
             /opt/community \
             /var/lib/odoo \
    && chown odoo -R /etc/odoo \
                     /mnt/addons \
                     /opt/addons \
                     /opt/community \
                     /var/lib/odoo

# Copy Entrypoint & Odoo conf
COPY ./docker-entrypoint.sh /entrypoint.sh
COPY ./etc/odoo-server.conf $ODOO_CONFIG

RUN chown odoo /entrypoint.sh \
    && chmod +x /entrypoint.sh \
    && chown odoo -R $ODOO_CONFIG_DIR

# OCA Repos
RUN curl -sL $MQT_URI \
    | tar -xz -C /opt/ \
    && ln -s /opt/maintainer-quality-tools-master/travis/clone_oca_dependencies /usr/bin \
    && ln -s /opt/maintainer-quality-tools-master/travis/getaddons.py /usr/bin/get_addons \
    && chmod +x /usr/bin/get_addons

# Remove unneeded build dependencies
RUN rm -Rf /tmp/odoo \
    && cp /usr/bin/pg_dump /tmp \
    && cp /usr/bin/pg_restore /tmp \
    && apk del curl \
               linux-headers \
               postgresql \
    && mv /tmp/pg_dump /usr/bin/pg_dump \
    && mv /tmp/pg_restore /usr/bin/pg_restore

# Mount Volumes
VOLUME ["/var/lib/odoo", \
        "/mnt/addons", \
        ]

# Expose Odoo services
EXPOSE 8069 8071

# Set default user when running the container
# USER odoo

# Entrypoint & Cmd
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
