ARG BASE=ghcr.io/ublue-os/ucore:stable-nvidia
FROM $BASE

RUN rpm-ostree install neovim git just fzf &&     \
    rpm-ostree cleanup -m && \
    ostree container commit


ADD scripts/* /usr/bin/

ADD static/operations.just /etc/
ADD static/just.sh /etc/profile.d/