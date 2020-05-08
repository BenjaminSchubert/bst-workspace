FROM fedora:latest as base

ADD buildgrid /build/buildgrid

RUN dnf install -y python3-pip

RUN python3.7 -m pip install /build/buildgrid

RUN useradd buildgrid

ADD files/buildgrid.conf /home/buildgrid/buildgrid.conf
