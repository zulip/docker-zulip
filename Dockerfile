FROM ubuntu:xenial-20171114
LABEL maintainer="Alexander Trost <galexrt@googlemail.com>"

ENV ZULIP_GIT_URL="https://github.com/zulip/zulip.git" ZULIP_GIT_REF="master" DATA_DIR="/data" LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"

COPY custom_zulip_files/ /root/custom_zulip

RUN echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends && \
    echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends && \
    apt-get -q update && \
    apt-get -q dist-upgrade -y && \
    apt-get -q install -y git wget curl sudo ca-certificates apt-transport-https locales nginx-full && \
    locale-gen en_US.UTF-8 && \
    rm /etc/init.d/nginx && \
    ln -s /bin/true /etc/init.d/nginx && \
    apt-get -q install -y python3-pip python3-dev python3-setuptools && \
    pip3 install virtualenv virtualenvwrapper && \
    mkdir -p "$DATA_DIR" && \
    git clone $ZULIP_GIT_URL && \
    cd zulip && git checkout $ZULIP_GIT_REF && cd .. \
    rm -rf zulip/.git && \
    mv zulip /root/zulip && \
    cp -rf /root/custom_zulip/* /root/zulip && \
    rm -rf /root/custom_zulip && \
    export PUPPET_CLASSES="zulip::dockervoyager" DEPLOYMENT_TYPE="dockervoyager" \
        ADDITIONAL_PACKAGES="rabbitmq-server expect build-essential" has_nginx="0" has_appserver="0" && \
    /root/zulip/scripts/setup/install --hostname="$(hostname)" --email="docker-zulip" --no-init-db

RUN apt-get -qq autoremove --purge -y && \
    apt-get -qq clean && \
    rm -rf /root/zulip/puppet/ /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint.sh /sbin/entrypoint.sh
ADD setup_files/ /opt/files

VOLUME ["$DATA_DIR"]
EXPOSE 80 443

ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:run"]
