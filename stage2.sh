#!/bin/bash

clear
pacman -Sy --noconfirm reflector
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers nano vim bash-completion

# Generating fstab
genfstab -U /mnt >> /mnt/etc/fstab
clear


# mounting partitions
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys

# instead of arch-chroot using this function
chroot_exec() {
    arch-chroot /mnt /bin/bash -c "$1" || {
        echo "error during command execution: $1"
        exit 1
    }
}

# Chrooting into system
chroot_exec "ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime"
chroot_exec "hwclock --systohc"
chroot_exec "echo "en_US.UTF-8 UTF-8" > /etc/locale.gen"
chroot_exec "echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen"
chroot_exec "locale-gen"
chroot_exec "echo LANG=en_US.UTF-8 > /etc/locale.conf"
chroot_exec "echo KEYMAP=us > /etc/vconsole.conf"
chroot_exec "echo arch-pc > /etc/hostname"
chroot_exec "mkinitcpio -P"

# setting root password
read -sp "Enter root password: " rootpass
arch-chroot /mnt bash -c "echo 'root:$rootpass' | chpasswd"
unset rootpass

# installing bootloader
chroot_exec "bootctl install"

# unmounting /dev /poc /sys partitions
umount -R /mnt/dev /mnt/proc /mnt/sys

# reflector adds new mirrors
reflector --latest 10 --sort rate --save /mnt/etc/pacman.d/mirrorlist

read -p "Linux kernel installation finished"
sleep 4
clear
./stage3.sh