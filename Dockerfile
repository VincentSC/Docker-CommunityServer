FROM ubuntu:20.04

ARG RELEASE_DATE="2016-06-21"
ARG RELEASE_DATE_SIGN=""
ARG VERSION="8.9.0.190"
ARG SOURCE_REPO_URL="deb http://static.teamlab.com.s3.amazonaws.com/repo/debian squeeze main"
ARG DEBIAN_FRONTEND=noninteractive
ARG PACKAGE_SYSNAME="onlyoffice"

ARG ELK_DIR=/usr/share/elasticsearch
ARG ELK_LIB_DIR=${ELK_DIR}/lib
ARG ELK_MODULE_DIR=${ELK_DIR}/modules

LABEL ${PACKAGE_SYSNAME}.community.release-date="${RELEASE_DATE}" \
      ${PACKAGE_SYSNAME}.community.version="${VERSION}" \
      description="Community Server is a free open-source collaborative system developed to manage documents, projects, customer relationship and emails, all in one place." \
      maintainer="Ascensio System SIA <support@${PACKAGE_SYSNAME}.com>" \
      securitytxt="https://www.${PACKAGE_SYSNAME}.com/.well-known/security.txt"

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    ELASTICSEARCH_VERSION=7.16.3

RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade && \
    addgroup --system --gid 107 ${PACKAGE_SYSNAME} && \
    adduser -uid 104 --quiet --home /var/www/${PACKAGE_SYSNAME} --system --gid 107 ${PACKAGE_SYSNAME} && \
    addgroup --system --gid 104 elasticsearch && \
    adduser -uid 103 --quiet --home /nonexistent --system --gid 104 elasticsearch && \
    apt-get -yq install systemd \
                        systemd-sysv \
                        locales \
                        software-properties-common \
                        curl \
                        wget \
                        sudo \
                        python3 \
                        git

RUN cd /lib/systemd/system/sysinit.target.wants/ && ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1 && \
    rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/* \
    /lib/systemd/system/plymouth* \
    /lib/systemd/system/systemd-update-utmp*
RUN locale-gen en_US.UTF-8
RUN    echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d
RUN    echo "${SOURCE_REPO_URL}" >> /etc/apt/sources.list
#RUN    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5
RUN sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5
#RUN    echo "deb https://download.mono-project.com/repo/ubuntu stable-jammy/snapshots/6.8.0.123 main" | tee /etc/apt/sources.list.d/mono-official.list
#RUN    echo "deb https://download.mono-project.com/repo/ubuntu stable-focal/snapshots/6.12 main" | tee /etc/apt/sources.list.d/mono-official.list
#RUN    echo "deb https://download.mono-project.com/repo/ubuntu stable-focal/snapshots/6.8.0.123 main" | tee /etc/apt/sources.list.d/mono-official.list
RUN    echo "deb https://download.mono-project.com/repo/ubuntu focal/snapshots/6.8.0.123 main" | tee /etc/apt/sources.list.d/mono-official.list
RUN    echo "deb https://d2nlctn12v279m.cloudfront.net/repo/mono/ubuntu bionic main" | tee /etc/apt/sources.list.d/mono-extra.list
RUN    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN    wget http://nginx.org/keys/nginx_signing.key
RUN    apt-key add nginx_signing.key
RUN    echo "deb http://nginx.org/packages/ubuntu/ focal nginx" >> /etc/apt/sources.list.d/nginx.list
RUN    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
RUN    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
# RUN    add-apt-repository -y ppa:certbot/certbot 
# RUN    add-apt-repository -y ppa:chris-lea/redis-server 
RUN    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN    echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/20.04/prod focal main" >> /etc/apt/sources.list.d/microsoft-prod.list
RUN    curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# RUN add-apt-repository universe
RUN sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu bionic main"
RUN sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu focal universe security"
RUN apt-get -y update

RUN    apt-get install -yq gnupg2 \
                        ca-certificates \
                        software-properties-common \
                        cron \
                        rsyslog \
                        ruby-dev \
                        ruby-god \
                        nodejs \
                        nginx \
                        gdb \
                        python3-certbot-nginx \
                        htop \
                        nano \
                        dnsutils \
                        redis-server \
                        python3-pip \
#                        multiarch-support \
                        iproute2 \
                        ffmpeg \
                        jq \
                        apt-transport-https

RUN    apt-get install -yq mono-complete \
                        elasticsearch=${ELASTICSEARCH_VERSION} \
                        mono-webserver-hyperfastcgi=0.4-7 \
                        mono-webserver-hyperfastcgi \
#                        mono-webserver-fastcgi \
                        ca-certificates-mono \
                        dotnet-sdk-6.0
RUN    apt-get install -yq ${PACKAGE_SYSNAME}-communityserver \
                        ${PACKAGE_SYSNAME}-xmppserver

RUN    apt-get clean

RUN git clone https://github.com/gdraheim/docker-systemctl-replacement /opt/systemctl-github && \
    rm -f /bin/systemctl && \
    ln -s /opt/systemctl-github/files/docker/systemctl.py /bin/systemctl

RUN    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY config /app/config/
COPY assets /app/assets/
#RUN chmod +x 
COPY run-community-server.sh /app/run-community-server.sh

RUN chmod -R 755 /app/*.sh

VOLUME ["/sys/fs/cgroup","/var/log/${PACKAGE_SYSNAME}", "/var/www/${PACKAGE_SYSNAME}/Data", "/var/lib/mysql", "/etc/letsencrypt"]

EXPOSE 80 443 5222 3306 9865 9888 9866 9871 9882 5280

CMD ["/app/run-community-server.sh"];
