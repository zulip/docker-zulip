FROM quay.io/sameersbn/ubuntu:latest
MAINTAINER Alexander Trost <galexrt@googlemail.com>

ENV ZULIP_VERSION="1.3.10" DATA_DIR="/data"

ADD entrypoint.sh /sbin/entrypoint.sh

RUN apt-get -q update && \
    apt-get -q dist-upgrade -y && \
    mkdir -p "$DATA_DIR" /root/zulip && \
    wget -q "https://www.zulip.com/dist/releases/zulip-server-$ZULIP_VERSION.tar.gz" -O /tmp/zulip-server.tar.gz && \
    tar xfz /tmp/zulip-server.tar.gz -C /root/zulip --strip-components=1 && \
    rm -rf /tmp/zulip-server.tar.gz

ADD custom_zulip_files/ /root/custom_zulip
ADD includes/createZulipAdmin.sh /opt/createZulipAdmin.sh

RUN rm -rf /root/zulip/puppet && \
    cp -rf /root/custom_zulip/* /root/zulip && \
    rm -rf /root/custom_zulip && \
    VOYAGER_CLASS="dockervoyager" DEPLOYMENT_TYPE="dockervoyager" ADDITIONAL_PACKAGES="python-dev python-six python-pbs" \
    /root/zulip/scripts/setup/install && \
    chown zulip:zulip /opt/createZulipAdmin.sh && \
    apt-get -qq autoremove --purge -y && \
    apt-get -qq clean && \
    rm -rf /root/zulip/puppet/ /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD setup_files/ /opt/files
ADD includes/supervisor/conf.d/zulip_postsetup.conf /etc/supervisor/conf.d/zulip_postsetup.conf

VOLUME ["$DATA_DIR"]
EXPOSE 80 443

ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:run"]
