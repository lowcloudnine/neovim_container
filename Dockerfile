FROM ubuntu:22.04

# ----------------------------------------------------------------------------
# SYSTEM SETUP
# ----------------------------------------------------------------------------

# Update and install various system packages
RUN \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y expect gawk sed && \
    apt-get install -y software-properties-common && \
    apt-get install -y sudo zsh locales locales-all && \
    apt-get install -y build-essential && \
    apt-get install -y wget curl tmux xsel xclip ripgrep fzf && \
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

# Install the Nerd Fonts get tool
RUN \
    git clone https://github.com/ronniedroid/getnf.git && \
    cp getnf/getnf /usr/local/bin && \
    rm -rf /getnf

# ----------------------------------------------------------------------------
# USER SETUP
# ----------------------------------------------------------------------------

# Create a USER
ARG USERNAME="vulcan"
ARG PASSWORD=""
ARG HOME_DIR="/home/${USERNAME}"
ARG PY_VER="3.11"

RUN \
    useradd -m -s /bin/bash -G sudo -p $(openssl passwd -1 "${PASSWORD}") ${USERNAME} && \
    echo "${USERNAME}} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY ./dotfiles/bashrc /home/${USERNAME}/.bashrc
COPY ./dotfiles/shrc /home/${USERNAME}/.shrc
COPY ./dotfiles/tmux.conf /home/${USERNAME}/.tmux.conf
COPY ./dotfiles/condarc /home/${USERNAME}/.condarc
COPY ./dotfiles/liquidprompt /home/${USERNAME}/.liquidprompt
COPY ./scripts/install_fonts.sh /home/${USERNAME}/install_fonts.sh

RUN \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.shrc && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.tmux.conf && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.condarc && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.liquidprompt && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/install_fonts.sh && \
    mkdir -p /opt/tools && \
    chown -R ${USERNAME}:${USERNAME} /opt/tools && \
    chmod 755 /home/${USERNAME}/install_fonts.sh

USER ${USERNAME}
WORKDIR ${HOME_DIR}

# Install Rust via Rustup
RUN \
    cd ~ && \
    curl https://sh.rustup.rs -sSf | sh -s -- -y

# Install Miniconda
RUN \
    cd ~ && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/tools/miniconda3 && \
    rm Miniconda3-latest-Linux-x86_64.sh && \
    /opt/tools/miniconda3/bin/conda create -n dev python=${PY_VER} -y

# Install some Nerd Fonts
RUN \
    /home/${USERNAME}/install_fonts.sh

# Install nvim-basic-ide
RUN \
    git clone https://github.com/LunarVim/nvim-basic-ide.git ~/.config/nvim && \
    nvim --headless +LazyUpdate +qa