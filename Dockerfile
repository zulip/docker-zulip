FROM quay.io/sameersbn/ubuntu:14.04.20151013
MAINTAINER Alexander Trost <galexrt@googlemail.com>

ENV ZULIP_VERSION="1.3.7" ZULIP_CHECKSUM="88bfa668eb14e07b0b806977db2ae2cd4d7e7ef8" DATA_DIR="/data" \
    DB_HOST="127.0.0.1" DB_PORT="5432" DB_USER="zulip" DB_PASS="zulip" DB_NAME="zulip" \
    RABBITMQ_HOST="127.0.0.1" RABBITMQ_USERNAME="zulip" RABBITMQ_PASSWORD="zulip"\
    REDIS_RATE_LIMITING="True" REDIS_HOST="127.0.0.1" REDIS_PORT="6379" \
    MEMCACHED_HOST="127.0.0.1" MEMCACHED_PORT="11211" MEMCACHED_TIMEOUT="3600" \
    ZULIP_USER_FULLNAME="Zulip Docker" ZULIP_USER_DOMAIN="" ZULIP_USER_EMAIL="" ZULIP_USER_PASS="zulip" \
    ZULIP_CUSTOM_SETTINGS="" ZULIP_AUTO_GENERATE_CERTS="True"

ADD entrypoint.sh /entrypoint.sh
ADD zulip-puppet /root/zulip-puppet
RUN apt-get -qq update -q && \
    apt-get -qq dist-upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq install -y puppet git wget python-dev python-six python-pbs openssl && \
    wget -q -O /root/zulip-ppa.asc https://zulip.com/dist/keys/zulip-ppa.asc && \
    apt-key add /root/zulip-ppa.asc && \
    echo "deb http://ppa.launchpad.net/tabbott/zulip/ubuntu trusty main" > /etc/apt/sources.list.d/zulip.list && \
    echo "deb-src http://ppa.launchpad.net/tabbott/zulip/ubuntu trusty main" >> /etc/apt/sources.list.d/zulip.list && \
    apt-get -qq update && \
    apt-get -qq dist-upgrade -y && \
    mkdir -p "/root/zulip" "/etc/zulip" "$DATA_DIR" && \
    wget -q "https://www.zulip.com/dist/releases/zulip-server-$ZULIP_VERSION.tar.gz" -P "/tmp" && \
    echo "$ZULIP_CHECKSUM /tmp/zulip-server-$ZULIP_VERSION.tar.gz" | sha1sum -c && \
    tar xfz "/tmp/zulip-server-$ZULIP_VERSION.tar.gz" -C "/root/zulip" --remove-files --strip-components=1 && \
    echo "[machine]\npuppet_classes = zulip::voyager\ndeploy_type = voyager" > /etc/zulip/zulip.conf && \
    rm -rf /root/zulip/puppet/zulip_internal /root/zulip/puppet/zulip && \
    mv -f /root/zulip-puppet /root/zulip/puppet/zulip && \
    /root/zulip/scripts/zulip-puppet-apply -f && \
    cp -a /root/zulip/zproject/local_settings_template.py /etc/zulip/settings.py && \
    ln -nsf /etc/zulip/settings.py /root/zulip/zproject/local_settings.py && \
    ZULIP_DEPLOY_PATH=$(/root/zulip/zulip_tools.py make_deploy_path) && \
    mv /root/zulip "$ZULIP_DEPLOY_PATH" && \
    ln -nsf "/home/zulip/deployments/next" /root/zulip && \
    ln -nsf "$ZULIP_DEPLOY_PATH" "/home/zulip/deployments/next" && \
    ln -nsf "$ZULIP_DEPLOY_PATH" "/home/zulip/deployments/current" && \
    ln -nsf /etc/zulip/settings.py "$ZULIP_DEPLOY_PATH/zproject/local_settings.py" && \
    cp -rfT "$ZULIP_DEPLOY_PATH/prod-static/serve" "/home/zulip/prod-static" && \
    chown -R zulip:zulip /home/zulip /var/log/zulip /etc/zulip/settings.py && \
    apt-get -qq autoremove --purge -y && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME ["$DATA_DIR"]
EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
