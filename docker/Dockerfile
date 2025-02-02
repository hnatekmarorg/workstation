ARG BASE=ghcr.io/ublue-os/ucore:stable-nvidia
FROM $BASE

RUN rpm-ostree install neovim git just fzf &&     \
    rpm-ostree cleanup -m && \
    ostree container commit

ADD scripts/* /usr/bin/

ADD static/operations.just /etc/
ADD static/just.sh /etc/profile.d/

RUN curl --retry 3 -Lo /usr/bin/kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64" && chmod +x /usr/bin/kind

ADD static/kind.sh /etc/profile.d/
