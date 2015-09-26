FROM ubuntu:trusty

MAINTAINER Alexander Trost <galexrt@googlemail.com>

ENV ZULIP_GROUP="zulip" ZULIP_USER="zulip" ZULIP_DIR="/opt/zulip" \
    ZULIP_VERSION="1.3.3" ZULIP_CHECKSUM="60943383289101b0eb84f0ff638c20fcc355511b"

ADD entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh && \
    mkdir -p "$ZULIP_DIR" && \
    groupadd -g 3000 -r "$ZULIP_GROUP" && \
    useradd -u 3000 -r -g "$ZULIP_GROUP" -d "$ZULIP_DIR" "$ZULIP_USER" && \
    cd /tmp && \
    wget "https://www.zulip.com/dist/releases/zulip-server-$ZULIP_VERSION.tar.gz" && \
    if [ "$(sha1sum -c {file}.sha1)" != "$ZULIP_CHECKSUM" ]; then exit 1; fi && \
    tar xfz "zulip-server-$ZULIP_VERSION.tar.gz" -C /opt && \
    mv "/opt/zulip-server-$ZULIP_VERSION" "$ZULIP_DIR" && \
    cd "ZULIP_DIR" && \
    ./scripts/setup/install && \
ENTRYPOINT /entrypoint.sh
