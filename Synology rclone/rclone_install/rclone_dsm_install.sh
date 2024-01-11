#!/bin/bash

PERSISTENT_RCLONE_CONFIG="/volume1/config/rclone.conf"
DEFAULT_RCLONE_CONFIG="/root/.config/rclone/rclone.conf"

mkdir -p "$(dirname "$PERSISTENT_RCLONE_CONFIG")"

if ! command -v rclone &> /dev/null
then
    echo "rclone not found, installing..."
    curl https://rclone.org/install.sh | sudo bash
else
    echo "rclone found, checking for updates..."
    installed_version=$(rclone --version | head -1 | awk '{print $2}')
    latest_version=$(curl -s https://downloads.rclone.org/version.txt | awk '{print $2}')

    if [ "$installed_version" != "$latest_version" ]; then
        echo "An update is available. Updating rclone from $installed_version to $latest_version."
        curl https://rclone.org/install.sh | sudo bash
    else
        echo "rclone is up to date."
    fi
fi

if [ -f "$DEFAULT_RCLONE_CONFIG" ] && [ ! -L "$DEFAULT_RCLONE_CONFIG" ]; then
    echo "Moving existing rclone config to persistent location..."
    mv "$DEFAULT_RCLONE_CONFIG" "$PERSISTENT_RCLONE_CONFIG"
fi

if [ ! -f "$PERSISTENT_RCLONE_CONFIG" ]; then
    echo "No rclone config found at persistent location. Creating an empty rclone config."
    touch "$PERSISTENT_RCLONE_CONFIG"
fi

if [ ! -L "$DEFAULT_RCLONE_CONFIG" ] || [ "$(readlink -f "$DEFAULT_RCLONE_CONFIG")" != "$PERSISTENT_RCLONE_CONFIG" ]; then
    echo "Creating symlink for rclone config..."
    mkdir -p "$(dirname "$DEFAULT_RCLONE_CONFIG")"
    ln -sf "$PERSISTENT_RCLONE_CONFIG" "$DEFAULT_RCLONE_CONFIG"
else
    echo "Symlink for rclone config already exists and is correctly set."
fi