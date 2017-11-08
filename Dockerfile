FROM ubuntu:xenial-20171006
MAINTAINER Alexander Trost <galexrt@googlemail.com>

ENV ZULIP_VERSION="1.7.0" DATA_DIR="/data" LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"

COPY custom_zulip_files/ /root/custom_zulip

RUN echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends && \
    echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends && \
    apt-get -q update && \
    apt-get -q dist-upgrade -y && \
    apt-get -q install -y wget curl sudo ca-certificates apt-transport-https locales nginx-full && \
    locale-gen en_US.UTF-8 && \
    rm /etc/init.d/nginx && \
    ln -s /bin/true /etc/init.d/nginx && \
    apt-get -q install -y python3-pip python3-dev python3-setuptools && \
    pip3 install --upgrade pip && \
    pip3 install virtualenv virtualenvwrapper && \
    mkdir -p "$DATA_DIR" /root/zulip && \
    wget -q "https://www.zulip.org/dist/releases/zulip-server-$ZULIP_VERSION.tar.gz" -O /tmp/zulip-server.tar.gz && \
    tar xfz /tmp/zulip-server.tar.gz -C /root/zulip --strip-components=1 && \
    rm -rf /tmp/zulip-server.tar.gz && \
    cp -rf /root/custom_zulip/* /root/zulip && \
    rm -rf /root/custom_zulip && \
    export PUPPET_CLASSES="zulip::dockervoyager" DEPLOYMENT_TYPE="dockervoyager" \
        ADDITIONAL_PACKAGES="rabbitmq-server expect build-essential" has_nginx="0" has_appserver="0" && \
    /root/zulip/scripts/setup/install && \
    cp -a /root/zulip/zproject/prod_settings_template.py /etc/zulip/settings.py && \
    ln -nsf /etc/zulip/settings.py /root/zulip/zproject/prod_settings.py && \
    deploy_path=$(/root/zulip/scripts/lib/zulip_tools.py make_deploy_path) && \
    mv /root/zulip "$deploy_path" && \
    ln -nsf /home/zulip/deployments/next /root/zulip && \
    ln -nsf "$deploy_path" /home/zulip/deployments/next && \
    ln -nsf "$deploy_path" /home/zulip/deployments/current && \
    ln -nsf /etc/zulip/settings.py "$deploy_path"/zproject/prod_settings.py && \
    mkdir -p "$deploy_path"/prod-static/serve && \
    cp -rT "$deploy_path"/prod-static/serve /home/zulip/prod-static && \
    chown -R zulip:zulip /home/zulip /var/log/zulip /etc/zulip/settings.py && \
    apt-get -qq autoremove --purge -y && \
    apt-get -qq clean && \
    rm -rf /root/zulip/puppet/ /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY includes/supervisor/conf.d/zulip_postsetup.conf /etc/supervisor/conf.d/zulip_postsetup.conf
COPY includes/createZulipRealm.sh /opt/createZulipRealm.sh
COPY entrypoint.sh /sbin/entrypoint.sh

RUN chown zulip:zulip /opt/createZulipRealm.sh

VOLUME ["$DATA_DIR"]
EXPOSE 80 443

ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:run"]
