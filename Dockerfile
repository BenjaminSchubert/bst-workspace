FROM fedora:latest

RUN \
    useradd buildstream && \
    echo "buildstream ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/buildstream

RUN \
    dnf upgrade --assumeyes && \
    dnf install --setopt=install_weak_deps=False --assumeyes \
        # Misc
        bash-completion \
        gcc \
        gcc-c++ \
        git \
        python3-tox \
        python3-devel \
        python36 \
        python37 \
        python38 \
        ShellCheck \
        vim \
        vim-syntastic-cpp \
        vim-syntastic-python \
        vim-syntastic-sh \
        vim-syntastic-yaml \
        # Buildbox
        cmake \
        fuse3 \
        fuse3-devel \
        grpc-devel \
        grpc-plugins \
        libuuid-devel \
        make \
        openssl-devel \
        protobuf-devel \
        make \
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
RUN \
    chmod +x /usr/local/bin/tox && \
    chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
