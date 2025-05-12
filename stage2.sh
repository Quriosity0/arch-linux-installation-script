#!/bin/bash

clear
pacman -Sy --noconfirm reflector
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers nano vim bash-completion pacstrap -K /mnt base linux linux-firmware --parallel-downloads=15
genfstab -U /mnt >> /mnt/etc/fstab
reflector --latest 10 --sort rate --save /mnt/etc/pacman.d/mirrorlist

arch-chroot /mnt <<'CHROOT'
clear
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

cd /etc/
echo LANG=en_US.UTF-8 > locale.conf

echo KEYMAP=us > vconsole.conf

echo asus-pc > hostname

mkinitcpio -P

echo "enter new root password"
passwd

bootctl install
exit
CHROOT

touch /mnt/boot/loader/loader.conf
echo "default arch" > /mnt/boot/loader/loader.conf
echo "timeout 5" >> /mnt/boot/loader/loader.conf


# cat > /mnt/boot/loader/loader.conf <<EOF
# default arch
# timeout 5
# EOF

read -p "Linux kernel installation finished"
sleep 4
./stage3.sh
clear


echo "installation finished"
exit 0
