FROM ubuntu:trusty

MAINTAINER Alexander Trost <galexrt@googlemail.com>

ENV ZULIP_GROUP="zulip" ZULIP_USER="zulip" ZULIP_DIR="/home/zulip" \
    ZULIP_VERSION="1.3.6" \
    DB_HOST="localhost" DB_PORT="5432" DB_USER="zulip" DB_PASSWORD="zulip"

ADD entrypoint.sh /entrypoint.sh
# TODO: Change this to the docker build repo including all the needed files
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
    mkdir -p "$ZULIP_DIR" && \
    git clone https://github.com/galexrt/zulip.git "$ZULIP_DIR" && \
    cd "$ZULIP_DIR" && \
    git checkout tags/"$ZULIP_VERSION" && \
    mkdir -p /etc/zulip && \
    echo -e "[machine]\npuppet_classes = zulip::voyager\ndeploy_type = voyager" > /etc/zulip/zulip.conf && \
    /root/zulip/scripts/zulip-puppet-apply -f -m  "/root/zulip/puppet/docker" && \
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

ENTRYPOINT /entrypoint.sh
