#!/bin/bash

clear
pacman -Sy --noconfirm reflector
reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
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

# Жёсткая проверка всех файлов
required_files=("locale.conf" "vconsole.conf" "hostname")
missing_files=()

for file in "${required_files[@]}"; do
    [ ! -f "/tmp/InstallScript/RequiredFiles/$file" ] && missing_files+=("$file")
done

if [ ${#missing_files[@]} -gt 0 ]; then
    echo "Error: Missing required files: ${missing_files[*]}"
    echo "Redownload script and copy it in /tmp"
    exit 1
fi


# cp /tmp/InstallScript/RequiredFiles/locale.conf /etc/
cd /etc/
echo LANG=en_US.UTF-8 > locale.conf

# cp /tmp/InstallScript/RequiredFiles/vconsole.conf /etc/
echo KEYMAP=us > vconsole.conf

# cp /tmp/InstallScript/RequiredFiles/hostname /etc/
echo asus-pc > hostname

mkinitcpio -P

echo "enter new root password"
passwd

bootctl install
exit
CHROOT

cat > /mnt/boot/loader/loader.conf <<EOF
default arch
timeout 3
EOF

read -p "Linux kernel installation finished"
sleep 4
chmod +x stage3.sh
./stage3.sh
clear


echo "installation finished"
exit 0
