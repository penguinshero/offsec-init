#!/usr/bin/env bash

set -e

echo "Flatpak Setup & Installer"

echo "Updating APT..."
sudo apt update

echo "Installing Flatpak..."
sudo apt install -y flatpak

echo "Adding Flathub repository..."
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "Flatpak setup completed."

declare -A APPS=(
    [1]="Telegram:org.telegram.desktop"
    [2]="Postman:com.getpostman.Postman"
    [3]="Firefox:org.mozilla.firefox"
    [4]="VLC:org.videolan.VLC"
    [5]="OBS Studio:com.obsproject.Studio"
    [6]="Discord:com.discordapp.Discord"
    [7]="Spotify:com.spotify.Client"
    [8]="Bitwarden:com.bitwarden.desktop"
)

echo "Select applications"

for key in "${!APPS[@]}"; do
    name="${APPS[$key]%%:*}"
    echo "$key) $name"
done

echo "0) Exit"

read -rp "Enter numbers (example: 1 2 5): " choices

if [[ "$choices" == "0" ]]; then
    echo "Exiting..."
    exit 0
fi

for choice in $choices; do
    if [[ -n "${APPS[$choice]}" ]]; then
        name="${APPS[$choice]%%:*}"
        id="${APPS[$choice]#*:}"

        echo "Installing $name..."
        flatpak install -y flathub "$id"
    else
        echo "Invalid option: $choice"
    fi
done

echo "Installation completed."
echo "Installed Flatpak applications:"
flatpak list
