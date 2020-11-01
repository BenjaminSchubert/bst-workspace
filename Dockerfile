FROM fedora:latest as base

RUN \
    useradd buildstream && \
    dnf upgrade --assumeyes && \
    dnf install --setopt=install_weak_deps=False --assumeyes \
        # Misc
        gcc \
        gcc-c++ \
        git \
        python38 \
        python3-devel \
        python3-pip \
        # Buildbox
        cmake \
        grpc-devel \
        grpc-plugins \
        libuuid-devel \
        make \
        openssl-devel \
        protobuf-devel \
    && \
    python3.8 -m ensurepip

ADD buildbox-common /build/buildbox-common
RUN \
    cd /build/buildbox-common && \
    cmake . -Bbuild && \
    make -C build -j $(nproc) && \
    make -C build install && \
    rm -rf /build

ADD buildbox-casd /build/buildbox-casd
RUN \
    cd /build/buildbox-casd && \
    cmake . -Bbuild && \
    make -C build -j $(nproc) && \
    make -C build install && \
    rm -rf /build


FROM base as artifact_server

ADD buildstream /build/buildstream
RUN \
    python3.8 -m pip install /build/buildstream && \
    rm -rf /build && \
    mkdir /home/buildstream/cache && \
    chown buildstream: /home/buildstream/cache

USER buildstream


FROM base as builder

RUN \
    echo "buildstream ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/buildstream && \
    mkdir /home/buildstream/.cache && \
    chown buildstream: /home/buildstream/.cache

RUN \
    dnf install --setopt=install_weak_deps=False --assumeyes --enablerepo=fedora-debuginfo --enablerepo=updates-debuginfo \
        # Misc
        bash-completion \
        gdb \
        python3-tox \
        python36 \
        python37 \
        python39 \
        ShellCheck \
        time \
        htop \
        ncdu \
        vim \
        vim-syntastic-cpp \
        vim-syntastic-python \
        vim-syntastic-sh \
        vim-syntastic-yaml \
        # Buildbox
        fuse3 \
        fuse3-devel \
        # BuildStream
        bubblewrap \
        # BuildStream plugins
        bzr \
        lzip \
        patch \
        # bst-plugins-experimental plugins
        cairo-gobject-devel \
        git-lfs \
        gobject-introspection-devel \
        ostree \
        quilt \
        # bst-plugins-container plugins
        moby-engine \
        # DebugInfos for various packages to be able to debug BuildStream with gdb
        python3.8-debuginfo

ADD buildbox-run-bubblewrap /build/buildbox-run-bubblewrap
RUN \
    cd /build/buildbox-run-bubblewrap && \
    cmake . -Bbuild && \
    make -C build -j $(nproc) && \
    make -C build install && \
    rm -rf /build && \
    ln -s /usr/local/bin/buildbox-run-bubblewrap /usr/local/bin/buildbox-run

ADD buildbox-fuse /build/buildbox-fuse
RUN \
    cd /build/buildbox-fuse && \
    cmake . -Bbuild && \
    make -C build -j $(nproc) && \
    make -C build install && \
    rm -rf /build

RUN usermod -a -G docker buildstream

ADD files/tox /usr/local/bin/tox
ADD files/builder-entrypoint.sh /usr/local/bin/entrypoint.sh
ADD files/buildstream.conf /home/buildstream/.config/buildstream.conf
RUN \
    chown -R buildstream: /home/buildstream/.config && \
    chmod +x /usr/local/bin/tox && \
    chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
