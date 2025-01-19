ARG BASE=ghcr.io/ublue-os/ucore:stable-nvidia
FROM $BASE

RUN rpm-ostree install neovim ranger git just fd-find fzf procs sd

# install atuin
RUN curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

RUN echo export EDITOR=nvim >> /root/.bashrc

ADD scripts/* /usr/bin/
