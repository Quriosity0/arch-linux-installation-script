#!/bin/bash

clear
echo "Disk partitioning"
echo
echo "Available disks:"
lsblk -dno NAME,SIZE,MODEL | grep -v "loop"

read -p "Enter disk name (e.g., sda/nvme0n1): " disk_name
DISK="/dev/$disk_name"

# checking drive for existance
if [ ! -b "$DISK" ]; then
    echo "Error: $DISK doesn't exist!"
    exit 1
fi

# Checking for existing partitions
if lsblk -nlo NAME "$DISK" | grep -q "${disk_name}[0-9]"; then
    echo -e "\nWARNING: Disk $DISK contains existing partitions!"
    lsblk "$DISK"

    read -p "Do you want to wipe ALL data on $DISK? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Operation cancelled."
        exit 1
    fi

# wiping old partitions
    echo "Wiping disk..."
    wipefs -a "$DISK"
    sleep 2
    clear
fi

echo -e "\nSelected disk: $DISK"
parted "$DISK" mklabel gpt
parted "$DISK" mkpart "EFI" fat32 1MiB 500MiB
parted "$DISK" set 1 esp on
parted "$DISK" mkpart "SWAP" linux-swap 500MiB 4.5GiB
parted "$DISK" mkpart "ROOT" ext4 4.5GiB 100%   

echo -e "\nPartitioning completed. Result:"
lsblk "$DISK"
sleep 2
clear

# naming partitions
if [[ "$DISK" =~ "nvme" ]]; then
    EFI_PART="${DISK}p1"
    SWAP_PART="${DISK}p2"
    ROOT_PART="${DISK}p3"
else
    EFI_PART="${DISK}1"
    SWAP_PART="${DISK}2"
    ROOT_PART="${DISK}3"
fi

# formating partitions
echo "Creating filesystems..."
mkfs.fat -F 32 "$EFI_PART" || { echo "Error creating FAT32"; exit 1; }
mkswap "$SWAP_PART" || { echo "Error creating swap"; exit 1; }
mkfs.ext4 "$ROOT_PART" || { echo "Error creating ext4"; exit 1; }
clear

# mounting
echo "Mounting partitions..."
mount "$ROOT_PART" /mnt || { echo "Failed to mount root"; exit 1; }
mount --mkdir "$EFI_PART" /mnt/boot || { echo "Failed to mount EFI"; exit 1; }
swapon "$SWAP_PART" || { echo "Failed to activate swap"; exit 1; }
clear

# displaying mounted partitions
echo "Mounted partitions:"
lsblk -o NAME,MOUNTPOINT "$DISK"
sleep 5
clear

echo "Starting stage2..."
if [ -f ./stage2.sh ]; then
    ./stage2.sh
else
    echo "Error: stage2.sh not found!"
    exit 1
fi
