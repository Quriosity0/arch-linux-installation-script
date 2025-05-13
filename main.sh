#!/bin/bash

clear
loadkeys us
echo "Welcome to Quriosity's Arch installation script"

# Checking, is script running in /tmp/InstallScript
if [[ "$(pwd)" != "/tmp/InstallScript" ]]; then
    echo "Script is not running from /tmp/InstallScript - copying files..."
    sleep 2

    # Removing old InstallScript
    rm -rf /tmp/InstallScript

    # Copying files
    mkdir -p /tmp/InstallScript
    cp -r "$(dirname "$0")"/* /tmp/InstallScript/

    # Переходим в /tmp
    if ! cd /tmp/InstallScript; then
        echo "ERROR: Failed to change directory to /tmp/InstallScript"
        sleep 2
        exit 1
    fi

    chmod +x main.sh
    chmod +x stage1.sh
    chmod +x stage2.sh
    chmod +x stage3.sh
    sleep 2
    ./main.sh
fi

echo "Checking internet connection..."

# Checking network connection
check_internet() {
    if ping -c 3 archlinux.org &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Connecting to wifi (if there's no ethernet)
connect_wifi() {
    echo "Trying to connect via WiFi..."

    if ! command -v iwctl &> /dev/null; then
        echo "Error: iwctl (WiFi manager) not found. Please connect manually."
        return 1
    fi

    # running iwctl and displaying tutorial
    echo "Please connect to WiFi manually in the iwctl shell. Example commands:"
    echo "  station list"
    echo "  station wlan0 scan"
    echo "  station wlan0 get-networks"
    echo "  station wlan0 connect YOUR_NETWORK"
    echo "  exit"
    echo
    read -p "to continue press enter"
    iwctl
    clear
}

if check_internet; then
    echo "Internet connection detected!"
    sleep 5
    ./stage1.sh
    exit 0
else
    echo "ERROR: No internet connection detected!"

    
    echo "Attempting to connect via Ethernet..."
    dhcpcd
    sleep 5

    if check_internet; then
        echo "Ethernet connection successful!"
        sleep 5
        chmod +x stage1.sh
        ./stage1.sh
        exit 0
    else
        connect_wifi

        if check_internet; then
            echo "WiFi connection successful!"
            sleep 5
            ./stage1.sh
        else
            echo "FAILED: Could not connect to the internet. Please connect manually and rerun the script."
            exit 1
        fi
    fi
fi
