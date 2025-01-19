ARG BASE=ghcr.io/ublue-os/ucore:stable-nvidia
FROM $BASE

RUN rpm-ostree install neovim ranger git

RUN git clone https://github.com/NvChad/starter /root/.config/nvim && nvim

ADD scripts/* /usr/bin/
