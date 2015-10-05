FROM ubuntu:trusty

MAINTAINER Alexander Trost <galexrt@googlemail.com>

ENV ZULIP_GROUP="zulip" ZULIP_USER="zulip" ZULIP_DIR="/home/zulip" \
    ZULIP_VERSION="1.3.6" \
    DB_HOST="localhost" DB_PORT="5432" DB_USER="zulip" DB_PASSWORD="zulip"

ADD entrypoint.sh /entrypoint.sh
ADD includes/zulip /root/zulip-puppet
# TODO: Change this to the docker build repo including all required files
# zulip.conf file is also located in includes folder
RUN chmod 755 /entrypoint.sh && \
    groupadd -r "zulip" && \
    useradd -r -g "zulip" -d "/home/zulip" "zulip" && \
    apt-get -qq update -q && \
    apt-get -qq dist-upgrade -y && \
    apt-get -qq install -y git wget python-dev python-six python-pbs supervisor && \
    wget -q -O /root/zulip-ppa.asc https://zulip.com/dist/keys/zulip-ppa.asc && \
    apt-key add /root/zulip-ppa.asc && \
    echo "deb http://ppa.launchpad.net/tabbott/zulip/ubuntu trusty main" > /etc/apt/sources.list.d/zulip.list && \
    echo "deb-src http://ppa.launchpad.net/tabbott/zulip/ubuntu trusty main" >> /etc/apt/sources.list.d/zulip.list && \
    apt-get -qq update -q && \
    apt-get -qq dist-upgrade -y && \
    mkdir -p "/root/zulip" && \
    git clone https://github.com/zulip/zulip.git "/root/zulip" && \
    cd "/root/zulip" && \
    git checkout tags/"$ZULIP_VERSION" && \
    mkdir -p /etc/zulip && \
    echo "[machine]\npuppet_classes = zulip::voyager\ndeploy_type = voyager" > /etc/zulip/zulip.conf && \
    rm -rf /root/zulip/puppet/zulip_internal /root/zulip/puppet/zulip && \
    mv -f /root/zulip-puppet /root/zulip/puppet/zulip && \
    ls -ahl /root/zulip/puppet /root/zulip/puppet/zulip /root && \
    /root/zulip/scripts/zulip-puppet-apply -f && \
    /root/zulip/scripts/setup/generate_secrets.py && \
    cp -a /root/zulip/zproject/local_settings_template.py /etc/zulip/settings.py && \
    ln -nsf /etc/zulip/settings.py /root/zulip/zproject/local_settings.py && \
    ZULIP_DEPLOY_PATH=$(/root/zulip/zulip_tools.py make_deploy_path) && \
    mv /root/zulip "$ZULIP_DEPLOY_PATH" && \
    ln -nsf /home/zulip/deployments/next /root/zulip && \
    ln -nsf "$ZULIP_DEPLOY_PATH" /home/zulip/deployments/next && \
    ln -nsf "$ZULIP_DEPLOY_PATH" /home/zulip/deployments/current && \
    ln -nsf /etc/zulip/settings.py "$ZULIP_DEPLOY_PATH"/zproject/local_settings.py && \
    cp -rT "$ZULIP_DEPLOY_PATH"/prod-static/serve /home/zulip/prod-static && \
    chown -R zulip:zulip /root/zulip /var/log/zulip /etc/zulip/settings.py && \
    apt-get -qq autoremove --purge -y && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/entrypoint.sh"]
