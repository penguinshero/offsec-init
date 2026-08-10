#!/usr/bin/env bash

set -e

echo "[+] Updating APT packages..."
sudo apt update -y

echo "[+] Installing APT tools..."
sudo apt install -y \
    bat \
    network-manager-openvpn network-manager-openvpn-gnome \
    wl-clipboard \
    btop \
    bettercap \
    build-essential \
    cewl \
    docker-compose \
    docker.io \
    eza \
    fonts-beng fonts-beng-extra  ibus-avro \
    python3-venv \
    exploitdb \
    ffmpeg \
    fzf \
    fonts-jetbrains-mono \
    tealdeer \
    gnome-shell-extension-manager \
    golang-go \
    hashcat \
    hydra \
    joomscan \
    john \
    kitty \
    linux-headers-amd64 \
    metasploit-framework \
    neovim \
    net-tools \
    nikto \
    podman \
    podman-compose \
    seclists \
    sqlmap \
    vlc \
    wpscan \
    zoxide \
    whatweb \
    freerdp3-x11 \
    enum4linux-ng \
    smbclient \
    smbget \
    smbmap \
    freerdp3-x11 \
    smtp-user-enum \
    wafw00f \
    stow \
