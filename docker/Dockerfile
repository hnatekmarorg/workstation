ARG BASE=ghcr.io/ublue-os/ucore:stable-nvidia
FROM $BASE

RUN rpm-ostree install neovim ranger git just fd-find fzf procs sd

ADD scripts/* /usr/bin/
