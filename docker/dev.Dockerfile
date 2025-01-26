ARG BASE=fedora:41

FROM $BASE AS base-image

ENV CARGO_HOME=/var/cargo
ENV GOPATH=/var/go

RUN dnf update -y && dnf install -y jq curl wget git gcc make nvim openssl && dnf clean all

ADD https://git.io/go-installer /usr/bin/go-installer

RUN chmod +x /usr/bin/go-installer && go-installer

ADD https://sh.rustup.rs /usr/bin/rustup-installer

RUN chmod +x /usr/bin/rustup-installer && rustup-installer -y

RUN echo export GOROOT=$GOPATH >> /etc/profile && \
    echo export CARGO_HOME=$CARGO_HOME >> /etc/profile && \
    echo export PATH=$PATH:$GOROOT/bin >> /etc/profile && \
    echo . "/var/cargo/env" >> /etc/profile

FROM base-image AS go-builder

# Compile packages from sources
RUN source /root/.bashrc && \
    go install github.com/muesli/duf@v0.8.1 && \
    go install github.com/natesales/q@v0.19.2 && \
    go install github.com/junegunn/fzf@v0.58.0

FROM base-image AS rust-builder


RUN . "$CARGO_HOME/env" && cargo install fd-find sd procs ripgrep bat hyperfine

FROM base-image

# kubectl
ADD https://dl.k8s.io/release/v1.32.1/bin/linux/amd64/kubectl /usr/bin
RUN chmod +x /usr/bin/kubectl

# Helm
ADD https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 /usr/bin/get-helm

RUN chmod +x /usr/bin/get-helm && get-helm

COPY --from=go-builder $GOPATH $GOPATH
COPY --from=rust-builder $CARGO_HOME $CARGO_HOME

