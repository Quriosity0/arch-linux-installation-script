#!/bin/bash

clear
pacman -Sy --noconfirm reflector
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers nano vim bash-completion

# Generating fstab
genfstab -U /mnt >> /mnt/etc/fstab
clear

# Chrooting into system
arch-chroot /mnt <<'CHROOT'
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo KEYMAP=us > /etc/vconsole.conf
echo arch-pc > /etc/hostname
mkinitcpio -P
CHROOT

sleep 4
./stage3.sh