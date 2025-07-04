ARG BASE=fedora:41

FROM $BASE AS base-image

ENV CARGO_HOME=/var/cargo
ENV GOROOT=/opt/go
ENV GOPATH=/var/go

WORKDIR /dnf

RUN dnf update -y && dnf install -y python3 python3-pip direnv iputils aria2 zsh jq curl wget git-lfs git gcc make ranger opentofu openssl-devel perl-Digest-SHA perl-IPC-Cmd perl-FindBin perl-devel openssl tcpdump btop cmake tldr && dnf clean all

RUN curl -LO https://github.com/neovim/neovim/releases/download/v0.11.1/nvim-linux-x86_64.tar.gz && ls -lah && \
    tar xzf nvim-linux-x86_64.tar.gz && ls -lah && \
    cp -r nvim-linux64/* /usr/ && \
    ln -sf /usr/bin/nvim /usr/local/bin/nvim && \
    rm -rf nvim-linux64 nvim-linux-x86_64.tar.gz

ADD https://git.io/go-installer /usr/bin/go-installer

RUN chmod +x /usr/bin/go-installer && go-installer && cat /root/.bashrc && ls

ADD https://sh.rustup.rs /usr/bin/rustup-installer

RUN chmod +x /usr/bin/rustup-installer && rustup-installer -y

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
    go install github.com/mikefarah/yq/v4@v4.45.1 && \
    go install github.com/jesseduffield/lazygit@v0.48.0

FROM base-image AS rust-builder

RUN curl -L -o protoc.zip https://github.com/protocolbuffers/protobuf/releases/download/v30.1/protoc-30.1-linux-x86_64.zip && unzip protoc.zip && mv bin/protoc /usr/bin/

RUN . "$CARGO_HOME/env" && cargo install aichat zellij git-delta fd-find sd procs ripgrep bat hyperfine zoxide exa rustscan du-dust gping podlet

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

ADD https://raw.githubusercontent.com/ahmetb/kubectx/v0.9.5/kubectx /usr/bin
ADD https://github.com/ahmetb/kubectx/releases/download/v0.9.5/kubens /usr/bin

ADD https://github.com/budimanjojo/talhelper/releases/download/v3.0.17/talhelper_linux_amd64.tar.gz /usr/bin/
ADD https://github.com/siderolabs/talos/releases/download/v1.9.2/talosctl-linux-amd64 /usr/bin/

RUN mv /usr/bin/talosctl-linux-amd64 /usr/bin/talosctl

WORKDIR /usr/bin

RUN tar xf talhelper_linux_amd64.tar.gz && rm talhelper_linux_amd64.tar.gz LICENSE README.md

RUN chmod +x /usr/bin/kubectx && chmod +x /usr/bin/kubens

RUN dnf config-manager addrepo --from-repofile=https://download.opensuse.org/repositories/home:TheLocehiliosan:yadm/Fedora_41/home:TheLocehiliosan:yadm.repo && dnf update -y && dnf install -y yadm && dnf clean all

RUN . "$CARGO_HOME/env" && zoxide init zsh >> /etc/profile.d/zoxide.sh

# RUN source /root/.bashrc && echo "$(fzf --zsh)" >> /etc/profile.d/fzf.sh 

# TODO: install this some other way
RUN curl -L https://carvel.dev/install.sh | bash
ENV PATH=/root/.local/bin:$PATH
RUN /bin/bash -c 'python3 -m pip install aider-install && aider-install'

WORKDIR /rpm
ADD https://github.com/openbao/openbao/releases/download/v2.2.0/bao_2.2.0_linux_amd64.rpm .

RUN dnf install -y ./bao_2.2.0_linux_amd64.rpm

RUN curl -Lo /usr/local/bin/clusterctl "https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.5.0/clusterctl-$(uname -s | tr '[:upper:]' '[:lower:]')-amd64" && chmod +x /usr/local/bin/clusterctl

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

RUN chmod -R g+wxr,u+wxr /var/go/

RUN chmod 777 /usr/bin/kube*

WORKDIR /root
