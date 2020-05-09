FROM fedora:latest as base

RUN \
    useradd buildstream && \
    dnf upgrade --assumeyes && \
    dnf install --setopt=install_weak_deps=False --assumeyes \
        # Misc
        gcc \
        gcc-c++ \
        git \
        python37 \
        python3-devel \
        python3-pip \
        # Buildbox
        cmake \
        grpc-devel \
        grpc-plugins \
        libuuid-devel \
        make \
        openssl-devel \
        protobuf-devel

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
    python3.7 -m pip install /build/buildstream && \
    rm -rf /build && \
    mkdir /home/buildstream/cache && \
    chown buildstream: /home/buildstream/cache

USER buildstream


FROM base as buildbox

RUN \
    echo "buildstream ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/buildstream && \
    mkdir /home/buildstream/.cache && \
    chown buildstream: /home/buildstream/.cache

RUN \
    dnf install --setopt=install_weak_deps=False --assumeyes \
        # Misc
        bash-completion \
        python3-tox \
        python36 \
        python38 \
        ShellCheck \
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
        moby-engine

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


FROM buildbox as builder

RUN usermod -a -G docker buildstream

ADD files/tox /usr/local/bin/tox
ADD files/builder-entrypoint.sh /usr/local/bin/entrypoint.sh
ADD files/buildstream.conf /home/buildstream/.config/buildstream.conf
RUN \
    chmod +x /usr/local/bin/tox && \
    chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]


FROM fedora:latest as buildgrid

ADD buildgrid /build/buildgrid

RUN dnf install -y python3-pip

RUN python3.7 -m pip install /build/buildgrid

RUN useradd buildgrid

ADD files/buildgrid.conf /home/buildgrid/buildgrid.conf


FROM buildbox as buildbox_worker

ADD buildbox-worker /build/buildbox-worker
RUN \
    cd /build/buildbox-worker && \
    cmake . -Bbuild && \
    make -C build -j $(nproc) && \
    make -C build install && \
    rm -rf /build

RUN \
    dnf install -y supervisor && \
    useradd buildgrid

ADD files/buildbox-worker-supervisord.conf /home/buildgrid/supervisord.conf

USER buildgrid
