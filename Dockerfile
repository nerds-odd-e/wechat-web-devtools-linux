FROM ubuntu:20.04

WORKDIR /workspace

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    mkdir -p /build_temp/python36 /build_temp/nodejs && \
    apt update  && \
    apt install -y binutils software-properties-common gcc g++ \
    gconf2 libxkbfile-dev p7zip-full make libssh2-1-dev libkrb5-dev wget curl \
    openssl pkg-config build-essential && \
    cd /build_temp/python36 && \
    apt-get install -y aptitude &&\
    aptitude -y install gcc make zlib1g-dev libffi-dev libssl-dev &&\
    mkdir -p test && cd test &&\
    wget http://npmmirror.com/mirrors/python/3.6.5/Python-3.6.5.tgz &&\
    tar -xvf Python-3.6.5.tgz &&\
    chmod -R +x Python-3.6.5 &&\
    cd Python-3.6.5/ &&\
    ./configure &&\
    aptitude -y install  libffi-dev libssl-dev &&\
    make && make install &&\
    cd /build_temp/nodejs &&\
    wget https://deb.nodesource.com/setup_16.x &&\
    chmod +x setup_16.x &&\
    ./setup_16.x &&\
    apt-get install -y nodejs &&\
    rm -rf /build_temp && \
    apt install -y gosu && \
    gosu nobody true && \
    useradd -s /bin/bash -m user

RUN apt remove -y p7zip p7zip-full p7zip-rar &&\
    rm -rf /opt/7z && \
    mkdir -p /opt/7z && \
    cd /opt/7z && \
    wget https://www.7-zip.org/a/7z2107-linux-x64.tar.xz && \
    tar -xJf 7z2107-linux-x64.tar.xz && \
    ln -s 7zz 7z

ENV PATH=/opt/7z:$PATH

ADD docker /workspace/docker
ADD tools /workspace/tools
ADD conf /workspace/conf
ADD bin /workspace/bin
ADD compiler /workspace/compiler

RUN apt install -yq python2

RUN ./docker/docker-entrypoint

RUN apt-get install -yq --no-install-recommends \
	libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 \
	libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 \
	libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 \
	libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcursor1 libxdamage1 libxext6 \
	libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 libnss3 \
	libgl1-mesa-glx libgbm-dev

RUN apt-get install -yq --no-install-recommends fonts-wqy-microhei

RUN ln -sf /var/lib/dbus/machine-id /etc/machine-id

ENV LIBGL_ALWAYS_INDIRECT=1

#CMD ./bin/wechat-devtools
CMD tail -f /dev/null
