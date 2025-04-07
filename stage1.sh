#!/bin/bash

clear
echo "Disk partitioning"
echo
echo "Available disks:"
lsblk -dno NAME,SIZE,MODEL | grep -v "loop"

read -p "Enter disk name (e.g., sda/nvme0n1): " disk_name
DISK="/dev/$disk_name"

# Проверка существования диска
if [ ! -b "$DISK" ]; then
    echo "Error: $DISK doesn't exist!"
    exit 1
fi

# Проверка на наличие разделов
if lsblk -nlo NAME "$DISK" | grep -q "${disk_name}[0-9]"; then
    echo -e "\nWARNING: Disk $DISK contains existing partitions!"
    lsblk "$DISK"

    read -p "Do you want to wipe ALL data on $DISK? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Operation cancelled."
        exit 1
    fi

    echo "Wiping disk..."
    wipefs -a "$DISK"
    sleep 2
fi

echo -e "\nSelected disk: $DISK"
parted "$DISK" mklabel gpt
parted "$DISK" mkpart "EFI" fat32 1MiB 500MiB
parted "$DISK" set 1 esp on
parted "$DISK" mkpart "ROOT" ext4 500MiB 100%

echo -e "\nPartitioning completed. Result:"
lsblk "$DISK"
sleep 2

# Определяем имена разделов (для SATA и NVMe)
if [[ "$DISK" =~ "nvme" ]]; then
    EFI_PART="${DISK}p1"
    ROOT_PART="${DISK}p2"
else
    EFI_PART="${DISK}1"
    ROOT_PART="${DISK}2"
fi

# Форматирование
echo "Creating filesystems..."
mkfs.fat -F 32 "$EFI_PART" || { echo "Error creating FAT32"; exit 1; }
mkfs.ext4 "$ROOT_PART" || { echo "Error creating ext4"; exit 1; }

# Монтирование
echo "Mounting partitions..."
mount "$ROOT_PART" /mnt || { echo "Failed to mount root"; exit 1; }
mount --mkdir "$EFI_PART" /mnt/boot || { echo "Failed to mount EFI"; exit 1; }

echo "Verifying mounts:"
lsblk -o NAME,MOUNTPOINT "$DISK"
sleep 2

# Явный переход к stage2
echo "Starting stage2..."
if [ -f ./stage2.sh ]; then
    exec /bin/bash ./stage2.sh
else
    echo "Error: stage2.sh not found!"
    exit 1
fi
