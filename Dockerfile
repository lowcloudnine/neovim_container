FROM ubuntu:22.04

# ----------------------------------------------------------------------------
# SYSTEM SETUP
# ----------------------------------------------------------------------------

# Update and install various system packages
RUN \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y expect && \
    apt-get install -y software-properties-common && \
    apt-get install -y sudo zsh locales locales-all && \
    apt-get install -y build-essential && \
    apt-get install -y wget curl tmux xsel xclip && \
    apt-get install -y python-is-python3 python3 python3-dev python3-pip && \
    apt-get install -y git && \
    apt-get install -y nodejs npm && \
    apt-get install -y jq && \
    \
    wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq

# Set locale
# ---- Has to be done after locales are installed ----
# ---- Taken from https://leimao.github.io/blog/Docker-Locale/
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

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

# Install some Nerd Fonts
RUN \
    git clone https://github.com/ronniedroid/getnf.git && \
    cp getnf/getnf /usr/local/bin && \
    rm -rf /getnf

COPY ./install_fonts.sh /tmp/install_fonts.sh
RUN \
    chmod +x /tmp/install_fonts.sh && \
    /tmp/install_fonts.sh && sleep 5 && \
    rm -rf /tmp/install_fonts.sh
