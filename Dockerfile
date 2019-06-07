# This is a 2-stage Docker build.  In the first stage, we build a
# Zulip development environment image and use
# tools/build-release-tarball to generate a production release tarball
# from the provided Git ref.
FROM ubuntu:xenial-20171114
LABEL maintainer="Alexander Trost <galexrt@googlemail.com>"

# You can specify these in docker-compose.yml or with
#   docker build --build-args "ZULIP_GIT_REF=git_branch_name" .
ARG ZULIP_GIT_URL=https://github.com/zulip/zulip.git
ARG ZULIP_GIT_REF=2.0.4
ARG CUSTOM_CA_CERTIFICATES=

SHELL ["/bin/bash", "-xuo", "pipefail", "-c"]

# First, we setup working locales
RUN echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends && \
    echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends && \
    apt-get -q update && \
    apt-get -q install locales && \
    locale-gen en_US.UTF-8

ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8"

# Next, we upgrade the base image and add a zulip user
RUN apt-get -q update && \
    apt-get -q dist-upgrade -y && \
    apt-get -q install -y git sudo ca-certificates apt-transport-https python3 crudini && \
    useradd -d /home/zulip -m zulip && \
    echo 'zulip ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN git clone "$ZULIP_GIT_URL" && \
    (cd zulip && git checkout "$ZULIP_GIT_REF") && \
    chown -R zulip:zulip zulip && \
    mv zulip /home/zulip/zulip

USER zulip
WORKDIR /home/zulip/zulip

# Finally, we provision the development environment and build a release tarball
RUN ./tools/provision --production-travis
RUN /bin/bash -c "source /srv/zulip-py3-venv/bin/activate && ./tools/build-release-tarball docker" && \
    mv /tmp/tmp.*/zulip-server-docker.tar.gz /tmp/zulip-server-docker.tar.gz


# In the second stage, we build the production image from the release tarball
FROM ubuntu:xenial-20171114
LABEL maintainer="Alexander Trost <galexrt@googlemail.com>"

ARG CUSTOM_CA_CERTIFICATES=

SHELL ["/bin/bash", "-xuo", "pipefail", "-c"]

ENV DATA_DIR="/data" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8"

# Then, with a second image, we install the production release tarball.

RUN echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends && \
    echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends && \
    apt-get -q update && \
    apt-get -q install locales && \
    locale-gen en_US.UTF-8

ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8"

COPY --from=0 /tmp/zulip-server-docker.tar.gz /root/
COPY custom_zulip_files/ /root/custom_zulip

RUN apt-get -q update && \
    apt-get -q dist-upgrade -y && \
    apt-get -q install -y sudo ca-certificates apt-transport-https nginx-full && \
    # Make sure Nginx is started by Supervisor.
    rm /etc/init.d/nginx && \
    ln -s /bin/true /etc/init.d/nginx && \
    mkdir -p "$DATA_DIR" && \
    cd /root && \
    tar -xf zulip-server-docker.tar.gz && \
    rm -f zulip-server-docker.tar.gz && \
    mv zulip-server-docker zulip && \
    cp -rf /root/custom_zulip/* /root/zulip && \
    rm -rf /root/custom_zulip && \
    export PUPPET_CLASSES="zulip::dockervoyager" \
           DEPLOYMENT_TYPE="dockervoyager" \
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
