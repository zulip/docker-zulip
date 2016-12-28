FROM quay.io/sameersbn/ubuntu:latest
MAINTAINER Alexander Trost <galexrt@googlemail.com>

ENV ZULIP_VERSION="1.4.2" DATA_DIR="/data"

RUN apt-get -q update && \
    apt-get -q dist-upgrade -y && \
    mkdir -p "$DATA_DIR" /root/zulip && \
    wget -q "https://www.zulip.com/dist/releases/zulip-server-$ZULIP_VERSION.tar.gz" -O /tmp/zulip-server.tar.gz && \
    tar xfz /tmp/zulip-server.tar.gz -C /root/zulip --strip-components=1 && \
    rm -rf /tmp/zulip-server.tar.gz

COPY custom_zulip_files/ /root/custom_zulip

RUN cp -rf /root/custom_zulip/* /root/zulip && \
    rm -rf /root/custom_zulip && \
    PUPPET_CLASSES="zulip::dockervoyager" DEPLOYMENT_TYPE="dockervoyager" ADDITIONAL_PACKAGES="python-dev python-six python-pbs" VIRTUALENV_NEEDED="no" TRAVIS="yes" \
    /root/zulip/scripts/setup/install || cat /var/log/zulip/install.log

RUN cp -a /root/zulip/zproject/prod_settings_template.py /etc/zulip/settings.py && \
    ln -nsf /etc/zulip/settings.py /root/zulip/zproject/prod_settings.py && \
    deploy_path=$(/root/zulip/scripts/lib/zulip_tools.py make_deploy_path) && \
    mv /root/zulip "$deploy_path" && \
    ln -nsf /home/zulip/deployments/next /root/zulip && \
    ln -nsf "$deploy_path" /home/zulip/deployments/next && \
    ln -nsf "$deploy_path" /home/zulip/deployments/current && \
    ln -nsf /etc/zulip/settings.py "$deploy_path"/zproject/prod_settings.py && \
    mkdir -p "$deploy_path"/prod-static/serve && \
    cp -rT "$deploy_path"/prod-static/serve /home/zulip/prod-static && \
    chown -R zulip:zulip /home/zulip /var/log/zulip /etc/zulip/settings.py

COPY includes/createZulipAdmin.sh /opt/createZulipAdmin.sh

RUN chown zulip:zulip /opt/createZulipAdmin.sh && \
    apt-get -qq autoremove --purge -y && \
    apt-get -qq clean && \
    rm -rf /root/zulip/puppet/ /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY docker-entrypoint.sh /sbin/entrypoint.sh
COPY setup_files/ /opt/files
COPY includes/supervisor/conf.d/zulip_postsetup.conf /etc/supervisor/conf.d/zulip_postsetup.conf

VOLUME ["$DATA_DIR"]
EXPOSE 80 443

ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:run"]
