# Copyright 2016-TODAY LasLabs Inc.
# License MIT (https://opensource.org/licenses/MIT).

FROM centos:7
MAINTAINER "LasLabs Inc." <support@laslabs.com>

# Enable SystemD
# @TODO: Eval whether needed, move to central setup if so
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i ==
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]

# Odoo Binary Dependencies
RUN set -x;                         \
    yum update -y                   \
    && yum install -y epel-release  \
    && yum install -y               \
        ca-certificates             \
        freetype                    \
        fontconfig                  \
        libX11                      \
        libXext                     \
        libXrender                  \
        nodejs-less                 \
        nodejs-clean-css            \
        python-inotify              \
        python-reportlab            \
        python-reportlab            \
        wget                        \
        xorg-x11-fonts-75dpi        \
        xorg-x11-fonts-Type1        \
        xorg-x11-server-Xvfb        \
        zlib

# Wkhtmltox 0.12.3 Headless Using XVFB
RUN cd /usr/local/src               \
    && wget -o wkhtmltox.tar.xz http://download.gna.org/wkhtmltopdf/0.12/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz \
    && tar xf wkhtmltox.tar.xz      \
    && cp wkhtmltox/bin/* /opt      \
    && rm -Rf wkhtmltox             \
    && echo -e '#!/bin/bash\nxvfb-run -a --server-args="-screen 0, 1024x768x24" /opt/wkhtmltopdf -q $*' > /usr/bin/wkhtmltopdf \
    && echo -e '#!/bin/bash\nxvfb-run -a --server-args="-screen 0, 1024x768x24" /opt/wkhtmltoimage -q $*' > /usr/bin/wkhtmltoimage \
    && chmod a+x /usr/bin/{wkhtmltopdf,wkhtmltoimage}

# Install Odoo
ENV ODOO_VERSION 9.0
RUN yum-config-manager --add-repo=https://nightly.odoo.com/${ODOO_VERSION}/nightly/rpm/odoo.repo \
    && yum update           \
    && yum install odoo

# Copy Entrypoint & Odoo conf
COPY ./entrypoint.sh /
COPY ./openerp-server.conf /etc/odoo/
RUN chown odoo /etc/odoo/openerp-server.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV OPENERP_SERVER /etc/odoo/openerp-server.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["openerp-server"]
