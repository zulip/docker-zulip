FROM ubuntu:trusty

MAINTAINER Alexander Trost <galexrt@googlemail.com>

ENV ZULIP_GROUP="zulip" ZULIP_USER="zulip" ZULIP_DIR="/srv/zulip" \
    ZULIP_VERSION="1.3.5"

ADD entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh && \
    mkdir -p "$ZULIP_DIR" && \
    apt-get update -q && \
    apt-get upgrade -y && \
    apt-get install -y git wget python-dev python-six python-pbs && \
    git clone https://github.com/zulip/zulip.git "$ZULIP_DIR" && \
    cd "$ZULIP_DIR" && \
    git checkout tags/"$ZULIP_VERSION" && \
    python "$ZULIP_DIR/provision.py" || : && \
    apt-get --purge -y -q remove memcached rabbitmq-server redis-server postgresql-9.3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT /entrypoint.sh
