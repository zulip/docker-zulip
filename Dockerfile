FROM ubuntu:trusty

MAINTAINER Alexander Trost <galexrt@googlemail.com>

ENV ZULIP_GROUP="zulip" ZULIP_USER="zulip" ZULIP_DIR="/root/zulip" \
    ZULIP_VERSION="1.3.3" ZULIP_CHECKSUM="60943383289101b0eb84f0ff638c20fcc355511b"

ADD entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh && \
    mkdir -p "$ZULIP_DIR" && \
    groupadd -g 3000 -r "$ZULIP_GROUP" && \
    useradd -u 3000 -r -g "$ZULIP_GROUP" -d "$ZULIP_DIR" "$ZULIP_USER" && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y wget python-six && \
    cd /root && \
    wget -q "https://www.zulip.com/dist/releases/zulip-server-$ZULIP_VERSION.tar.gz" && \
    tar xfz "/root/zulip-server-$ZULIP_VERSION.tar.gz" -C /tmp && \
    mv "/tmp/zulip-server-$ZULIP_VERSION" "$ZULIP_DIR" && \
    cd "$ZULIP_DIR" && \
    "$ZULIP_DIR/scripts/setup/install" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT /entrypoint.sh
