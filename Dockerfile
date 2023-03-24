# This is a 2-stage Docker build.  In the first stage, we build a
# Zulip development environment image and use
# tools/build-release-tarball to generate a production release tarball
# from the provided Git ref.
FROM ubuntu:20.04 as base

LABEL org.opencontainers.image.source https://github.com/zulip/docker-zulip

# Set up working locales and upgrade the base image
ENV LANG="C.UTF-8"

ARG UBUNTU_MIRROR

RUN { [ ! "$UBUNTU_MIRROR" ] || sed -i "s|http://\(\w*\.\)*archive\.ubuntu\.com/ubuntu/\? |$UBUNTU_MIRROR |" /etc/apt/sources.list; } && \
    apt-get -q update && \
    apt-get -q dist-upgrade -y && \
    DEBIAN_FRONTEND=noninteractive \
        apt-get -q install --no-install-recommends -y ca-certificates git locales lsb-release python3 sudo tzdata


FROM base as build

# Add a zulip user
RUN useradd -d /home/zulip -m zulip && \
    echo 'zulip ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers

USER zulip
WORKDIR /home/zulip

# You can specify these in docker-compose.yml or with
#   docker build --build-arg "ZULIP_GIT_REF=git_branch_name" .
ARG ZULIP_GIT_URL=https://github.com/zulip/zulip.git
ARG ZULIP_GIT_REF=6.1

RUN git clone "$ZULIP_GIT_URL" && \
    cd zulip && \
    git checkout -b current "$ZULIP_GIT_REF"

WORKDIR /home/zulip/zulip

ARG CUSTOM_CA_CERTIFICATES

# Finally, we provision the development environment and build a release
# tarball, after first bumping Yarn's network timeout to 5 minutes to account
# for occasional glitches in QEMU environments (eg. multiarch builds).
RUN echo 'network-timeout 300000' >> ~/.yarnrc
RUN SKIP_VENV_SHELL_WARNING=1 ./tools/provision --build-release-tarball-only
RUN . /srv/zulip-py3-venv/bin/activate && \
    ./tools/build-release-tarball docker && \
    mv /tmp/tmp.*/zulip-server-docker.tar.gz /tmp/zulip-server-docker.tar.gz


# In the second stage, we build the production image from the release tarball
FROM base

ENV DATA_DIR="/data"

# Then, with a second image, we install the production release tarball.
COPY --from=build /tmp/zulip-server-docker.tar.gz /root/
COPY custom_zulip_files/ /root/custom_zulip

ARG CUSTOM_CA_CERTIFICATES

RUN \
    # Make sure Nginx is started by Supervisor.
    dpkg-divert --add --rename /etc/init.d/nginx && \
    ln -s /bin/true /etc/init.d/nginx && \
    mkdir -p "$DATA_DIR" && \
    cd /root && \
    tar -xf zulip-server-docker.tar.gz && \
    rm -f zulip-server-docker.tar.gz && \
    mv zulip-server-docker zulip && \
    cp -rf /root/custom_zulip/* /root/zulip && \
    rm -rf /root/custom_zulip && \
    export PUPPET_CLASSES="zulip::profile::docker" \
           ADDITIONAL_PACKAGES="expect" && \
    /root/zulip/scripts/setup/install --hostname="$(hostname)" --email="docker-zulip" --no-init-db && \
    rm -f /etc/zulip/zulip-secrets.conf /etc/zulip/settings.py && \
    apt-get -qq autoremove --purge -y && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint.sh /sbin/entrypoint.sh
COPY certbot-deploy-hook /sbin/certbot-deploy-hook

VOLUME ["$DATA_DIR"]
EXPOSE 80 443

ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:run"]
