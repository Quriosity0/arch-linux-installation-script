#!/bin/bash

clear
pacman -Sy --noconfirm reflector
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers nano vim bash-completion
genfstab -U /mnt >> /mnt/etc/fstab
reflector --latest 10 --sort rate --save /mnt/etc/pacman.d/mirrorlist

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
echo asus-pc > /etc/hostname
mkinitcpio -P
exit
CHROOT

echo "Enter root pasword"
arch-chroot /mnt passwd
arch-chroot /mnt bootctl install
clear

# Writing bootloader
mkdir -p /mnt/boot/loader
cat > /mnt/boot/loader/loader.conf <<EOF
default arch
timeout 5
EOF
clear

# reflector adds new mirrors
reflector --latest 10 --sort rate --save /mnt/etc/pacman.d/mirrorlist

read -p "Linux kernel installation finished"
sleep 4
./stage3.sh