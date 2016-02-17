FROM quay.io/sameersbn/ubuntu:latest
MAINTAINER Alexander Trost <galexrt@googlemail.com>

ENV ZULIP_VERSION="master" DATA_DIR="/data"

ADD entrypoint.sh /sbin/entrypoint.sh

RUN mkdir -p "$DATA_DIR" /root/zulip && \
    git clone https://github.com/zulip/zulip.git /root/zulip && \
    cd /root/zulip && \
    git checkout "$ZULIP_VERSION" && \
    VOYAGER_CLASS="dockervoyager" DEPLOYMENT_TYPE="dockervoyager" ADDITIONAL_PACKAGES="python-dev python-six python-pbs" \
    /root/zulip/scripts/setup/install && \
    wget -q https://www.zulip.com/dist/releases/zulip-server-latest.tar.gz -O /tmp/zulip-server.tar.gz && \
    tar xfz /tmp/zulip-server.tar.gz -C "/home/zulip/prod-static" --strip-components=3 --wildcards */prod-static/serve && \
    rm -rf /tmp/zulip-server.tar.gz && \
    ln -nsf /home/zulip/deployments/current/prod-static/serve /home/zulip/prod-static && \
    apt-get -qq autoremove --purge -y && \
    apt-get -qq clean && \
    rm -rf /root/zulip/puppet/ /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD files/supervisor/conf.d/zulip_postsetup.conf /etc/supervisor/conf.d/zulip_postsetup.conf
ADD files/createZulipAdmin.sh /opt/createZulipAdmin.sh

VOLUME ["$DATA_DIR"]
EXPOSE 80 443

ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:run"]
