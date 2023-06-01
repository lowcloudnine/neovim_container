FROM ubuntu:22.04

# ----------------------------------------------------------------------------
# ARGS
# ----------------------------------------------------------------------------

ARG HOST_GID
ARG DEFAULT_USER
ARG HTTPS_PROXY

# >= 16,18
ARG RELEASE_NODE=18
ARG RELEASE_BIN_NPM=9.3.0

# @diff code-server::
# @repo https://github.com/sar/vs-code-container-with-ssl.git
ARG RELEASE_CODE_SERVER=4.9.1

# USER Info
ARG USERNAME="vulcan"
ARG SUDO_PASSWORD=""
ARG HOME_DIR="/home/${USERNAME}"

# Miniconda Env Python Version Info
ARG PY_VER="3.11"

# ----------------------------------------------------------------------------
# SYSTEM SETUP
# ----------------------------------------------------------------------------

COPY ./misc/timezone /etc/timezone

# Update and install various system packages
RUN \
    apt-get update && apt-get upgrade -y && \
    apt-get install -y software-properties-common build-essential && \
    apt-get install -y sudo systemd && \
    apt-get install -y gawk sed zsh && \
    apt-get install -y wget curl && \
    apt-get install -y tmux xsel xclip && \
    apt-get install -y ripgrep fzf fd-find && \
    apt-get install -y fonts-firacode fonts-ubuntu && \
    apt-get install -y htop && \
    apt-get install -y python-is-python3 python3 python3-dev python3-pip && \
    apt-get install -y git && \
    apt-get install -y jq && \
    \
    wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq

# ----------------------------------------------------------------------------
# ENVs
# ----------------------------------------------------------------------------

# Set locale
# ---- Taken from https://leimao.github.io/blog/Docker-Locale/
RUN \
    apt-get install -y locales locales-all

# ---- Has to be done after locales are installed ----
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# ----------------------------------------------------------------------------
# USER CREATION
# ----------------------------------------------------------------------------

RUN \
    useradd -m -s /bin/bash -G sudo -p $(openssl passwd -1 "${SUDO_PASSWORD}") ${USERNAME} && \
    echo "${USERNAME}} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ----------------------------------------------------------------------------
# INSTALL VARIOUS TOOLS
# ----------------------------------------------------------------------------

# Install NodeJS
RUN \
    wget https://raw.githubusercontent.com/nodesource/distributions/master/deb/setup_${RELEASE_NODE}.x \
        -O /tmp/nodejs_${RELEASE_NODE}_setup.sh && \
    chmod +x /tmp/nodejs_${RELEASE_NODE}_setup.sh && \
    /tmp/nodejs_${RELEASE_NODE}_setup.sh && \
    apt install -y nodejs && \
    node -v && npm -v \
    npm config set python python3 && \
    rm -rf /tmp/node*

# Install Go Language
RUN \
    wget https://go.dev/dl/go1.20.4.linux-amd64.tar.gz -O /tmp/go.tar.gz && \
    rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm -rf /tmp/go*

# Install NeoVim
RUN \
    wget https://github.com/neovim/neovim/releases/download/v0.9.1/nvim-linux64.tar.gz && \
    mv nvim-linux64.tar.gz /tmp && \
    cd /tmp && \
    tar -xvzf nvim-linux64.tar.gz && \
    cp -R ./nvim-linux64/* /usr/ && \
    rm -rf /tmp/nvim-linux64*

# Install Neovim plugins & Helpers
RUN \
    pip3 install pynvim flake8 && \
    npm install -g neovim

# ----------------------------------------------------------------------------
# USER SETUP
# ----------------------------------------------------------------------------

COPY ./dotfiles/bashrc /home/${USERNAME}/.bashrc
COPY ./dotfiles/shrc /home/${USERNAME}/.shrc
COPY ./dotfiles/tmux.conf /home/${USERNAME}/.tmux.conf
COPY ./dotfiles/condarc /home/${USERNAME}/.condarc
COPY ./dotfiles/liquidprompt /home/${USERNAME}/.liquidprompt
COPY ./misc/requirements.txt /home/${USERNAME}/requirements.txt

RUN \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.shrc && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.tmux.conf && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.condarc && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.liquidprompt && \
    mkdir -p /opt/tools && \
    chown -R ${USERNAME}:${USERNAME} /opt/tools && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/requirements.txt && \
    mkdir -p /home/${USERNAME}/bin && \
    ln -s $(which fdfind) /home/${USERNAME}/bin/fd && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/bin

USER ${USERNAME}
WORKDIR ${HOME_DIR}

# Install Rust via Rustup
RUN \
    curl https://sh.rustup.rs -sSf | sh -s -- -y

# Install Miniconda
RUN \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/tools/miniconda3 && \
    rm Miniconda3-latest-Linux-x86_64.sh && \
    /opt/tools/miniconda3/bin/conda create -n dev python=${PY_VER} -y && \
    /opt/tools/envs/dev/bin/pip install -r /home/${USERNAME}/requirements.txt
