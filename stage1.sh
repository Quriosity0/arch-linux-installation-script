#!/bin/bash

clear
echo "Disk partitioning"
echo
echo "Available disks:"
lsblk -dno NAME,SIZE,MODEL | grep -v "loop"

read -p "Enter disk name (e.g., sda): " disk_name
DISK="/dev/$disk_name"

# Проверка существования диска
if [ ! -b "$DISK" ]; then
    echo "Error: $DISK doesn't exist!"
    exit 1
fi

# echo "do you need swap partition?"

# Проверка на наличие разделов
if lsblk -nlo NAME "$DISK" | grep -q "${disk_name}[0-9]"; then
    echo -e "\nWARNING: Disk $DISK contains existing partitions!"
    lsblk "$DISK"

    read -p "Do you want to wipe ALL data on $DISK? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Operation cancelled."
        exit 1
    fi

    # Очистка диска (осторожно!)
    echo "Wiping disk..."
    wipefs -a "$DISK"
    sleep 2
fi

echo -e "\nSelected disk: $DISK"
parted "$DISK" mklabel gpt
parted "$DISK" mkpart "EFI" fat32 1MiB 500MiB
parted "$DISK" set 1 esp on
parted "$DISK" mkpart "/" ext4 500MiB 100%

echo -e "\nPartitioning completed. Result:"
lsblk "$DISK"
sleep 10

mkfs.ext4 /dev/sda2
mkfs.fat -F 32 /dev/sda1
mount /dev/sda2 /mnt
mount --mkdir /dev/sda1 /mnt/boot
sleep 10
./stage2.sh

# TODO
# swapon /dev/swap_partition
