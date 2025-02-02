ARG BASE=fedora:41

FROM $BASE AS base-image

ENV CARGO_HOME=/var/cargo
ENV GOROOT=/opt/go
ENV GOPATH=/var/go

WORKDIR /dnf

RUN dnf update -y && dnf install -y jq curl wget git gcc make nvim openssl-devel perl-IPC-Cmd perl-FindBin perl-devel openssl tcpdump btop cmake && dnf clean all

ADD https://git.io/go-installer /usr/bin/go-installer

RUN chmod +x /usr/bin/go-installer && go-installer && cat /root/.bashrc && ls

ADD https://sh.rustup.rs /usr/bin/rustup-installer

RUN chmod +x /usr/bin/rustup-installer && rustup-installer -y

RUN cat /root/.bashrc  >> /etc/profile.d/99-default-bashrc.sh && echo alias vim=nvim >> /etc/profile.d/98-override-vim.sh

ADD static/distrobox_aliases.sh /etc/profile.d/
ADD static/common.sh /etc/profile.d/

FROM base-image AS go-builder

# K9S requires special steps
WORKDIR /k9s
ADD https://github.com/derailed/k9s.git#v0.32.7 /k9s
RUN source /root/.bashrc && make build

# Compile packages from sources
RUN source /root/.bashrc && \
    go install github.com/muesli/duf@v0.8.1 && \
    go install github.com/natesales/q@v0.19.2 && \
    go install github.com/junegunn/fzf@v0.58.0 && \
    go install github.com/mikefarah/yq/v4@v4.45.1

FROM base-image AS rust-builder

RUN . "$CARGO_HOME/env" && cargo install zellij git-delta fd-find sd procs ripgrep bat hyperfine atuin zoxide exa rustscan starship

FROM base-image

# kubectl
ADD https://dl.k8s.io/release/v1.32.1/bin/linux/amd64/kubectl /usr/bin
RUN chmod +x /usr/bin/kubectl

# Helm
ADD https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 /usr/bin/get-helm

RUN chmod +x /usr/bin/get-helm && get-helm

COPY --from=go-builder $GOPATH $GOPATH
COPY --from=rust-builder $CARGO_HOME $CARGO_HOME
COPY --from=go-builder /k9s/execs/ /usr/bin/

# Setup atuin
RUN . "$CARGO_HOME/env" && atuin gen-completions --shell bash >> /etc/profile.d/atuin.sh
RUN . "$CARGO_HOME/env" && echo eval "$(atuin init bash --disable-up-arrow)" >> /etc/profile.d/atuin.sh

ADD https://raw.githubusercontent.com/ahmetb/kubectx/v0.9.5/kubectx /usr/bin
ADD https://github.com/ahmetb/kubectx/releases/download/v0.9.5/kubens /usr/bin

RUN chmod +x /usr/bin/kubectx && chmod +x /usr/bin/kubens

RUN dnf config-manager addrepo --from-repofile=https://download.opensuse.org/repositories/home:TheLocehiliosan:yadm/Fedora_41/home:TheLocehiliosan:yadm.repo && dnf update -y && dnf install -y yadm && dnf clean all

RUN . "$CARGO_HOME/env" && zoxide init bash >> /etc/profile.d/zoxide.sh
