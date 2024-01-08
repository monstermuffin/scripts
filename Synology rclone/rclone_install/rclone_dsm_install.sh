#!/bin/bash

# Check if rclone is installed
if ! command -v rclone &> /dev/null
then
    echo "rclone not found, installing..."
    curl https://rclone.org/install.sh | sudo bash
else
    echo "rclone found, checking for updates..."
    # Get the currently installed version
    installed_version=$(rclone --version | head -1 | awk '{print $2}')

    # Get the latest version number from rclone's website
    latest_version=$(curl -s https://downloads.rclone.org/version.txt | awk '{print $2}')

    if [ "$installed_version" != "$latest_version" ]; then
        echo "An update is available. Updating rclone from $installed_version to $latest_version."
        curl https://rclone.org/install.sh | sudo bash
    else
        echo "rclone is up to date."
    fi
fi