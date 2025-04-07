#!/bin/bash

clear
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers nano vim bash-completion
genfstab -U /mnt >> /mnt/etc/fstab

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

cp /tmp/InstallScript/RequiredFiles/locale.conf /etc/
cp /tmp/InstallScript/RequiredFiles/vconsole.conf /etc/
cp /tmp/InstallScript/RequiredFiles/hostname /etc/

mkinitcpio -P

echo "enter new root password"
passwd

bootctl install
CHROOT

cat > /mnt/boot/loader/loader.conf <<EOF
default arch
timeout 3
EOF

read -p "Linux kernel installation finished, do you want to continue? (Y/n): " FinishQuestion
case "$FinishQuestion" in
    y|Y)
        clear
        ;;
    n|N)
        echo "Exiting installation..."
        sleep 2
        exit 0
        ;;
    *)
        echo "Invalid input. Continuing installation by default."
        sleep 2
        clear
        ;;
esac

echo "installation finished"
exit 0
