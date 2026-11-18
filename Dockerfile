# syntax=docker/dockerfile:1

ARG NODE_VERSION=26
ARG GO_VERSION=1.27
ARG RUST_VERSION=1
ARG BUN_VERSION=1
ARG UV_VERSION=latest
ARG PYTHON_VERSION=3.14

# Multi-stage official toolchain sources
FROM node:${NODE_VERSION}-trixie-slim AS node-src
FROM golang:${GO_VERSION}-trixie AS go-src
FROM rust:${RUST_VERSION}-slim-trixie AS rust-src
FROM oven/bun:${BUN_VERSION}-slim AS bun-src
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv-src

# Final development image
FROM debian:trixie-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# Base OS utilities, compilers, and build dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        gnupg \
        less \
        libssl-dev \
        locales \
        openssh-client \
        pkg-config \
        procps \
        sudo \
        unzip \
        xz-utils \
        zip \
    && sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

# Create non-root developer user with passwordless sudo
RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" --shell /bin/bash --create-home "${USERNAME}" \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}"

# Node.js + npm/npx
COPY --from=node-src /usr/local/bin/node /usr/local/bin/node
COPY --from=node-src /usr/local/include/node /usr/local/include/node
COPY --from=node-src /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Bun
COPY --from=bun-src /usr/local/bin/bun /usr/local/bin/bun
RUN ln -sf /usr/local/bin/bun /usr/local/bin/bunx

# Go
COPY --from=go-src /usr/local/go /usr/local/go

# Rust + Cargo (writable by the non-root user for cargo install / rustup updates)
COPY --from=rust-src --chown=${USER_UID}:${USER_GID} /usr/local/rustup /usr/local/rustup
COPY --from=rust-src --chown=${USER_UID}:${USER_GID} /usr/local/cargo /usr/local/cargo

# uv + uvx
COPY --from=uv-src /uv /uvx /usr/local/bin/

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    GOPATH=/home/${USERNAME}/go \
    BUN_INSTALL=/home/${USERNAME}/.bun \
    NPM_CONFIG_PREFIX=/home/${USERNAME}/.npm-global \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

ENV PATH="/home/${USERNAME}/.local/bin:/home/${USERNAME}/.bun/bin:/home/${USERNAME}/.npm-global/bin:${GOPATH}/bin:/usr/local/go/bin:${CARGO_HOME}/bin:${PATH}"

# Prepare writable toolchain directories and workspace
RUN mkdir -p \
        "/home/${USERNAME}/.local/bin" \
        "/home/${USERNAME}/.bun/bin" \
        "/home/${USERNAME}/.npm-global/bin" \
        "${GOPATH}/bin" "${GOPATH}/pkg" "${GOPATH}/src" \
        /workspace \
    && chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}" /workspace

USER ${USERNAME}
WORKDIR /workspace

# Install managed Python via uv and expose python / python3 on PATH
RUN uv python install --default "${PYTHON_VERSION}"

# Smoke-test all toolchains during build
RUN node --version \
    && npm --version \
    && bun --version \
    && uv --version \
    && python --version \
    && rustc --version \
    && cargo --version \
    && go version

CMD ["/bin/bash"]
