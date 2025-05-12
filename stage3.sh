#!/bin/bash

set -e
clear

# Путь установки
INSTALL_DIR="/tmp/InstallScript"

# Проверяем, что мы уже в новой системе (не в установочной среде)
if [[ ! -f /etc/arch-release ]]; then
    # Если ещё в установочной среде — копируем файлы и настраиваем автозапуск
    echo "Copying installation files to the new system..."
    mkdir -p /mnt"$INSTALL_DIR"
    cp -r "$INSTALL_DIR"/* /mnt"$INSTALL_DIR"/
    chmod +x /mnt"$INSTALL_DIR"/*.sh

    # Создаём сервис в /mnt/etc (после перезагрузки это станет /etc)
    echo "Setting up auto-start after reboot..."
    cat > /mnt/etc/systemd/system/continue_install.service <<EOF
[Unit]
Description=Continue Arch Linux Installation
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash $INSTALL_DIR/main.sh
WorkingDirectory=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

    # Проверяем, что сервис создан
    if [[ ! -f /mnt/etc/systemd/system/continue_install.service ]]; then
        echo "ERROR: Failed to create service file!"
        exit 1
    fi

    # Включаем сервис в chroot
    arch-chroot /mnt systemctl daemon-reload
    arch-chroot /mnt systemctl enable continue_install.service --now

    echo "Installation files copied. The system will now reboot."
    echo "After reboot, the installation will continue automatically."
    read -p "Press Enter to reboot..."
    reboot
else
    # Если мы уже в новой системе — продолжаем установку
    echo "Continuing installation..."
    
    # Отключаем сервис (чтобы не запускался снова)
    systemctl disable continue_install.service || true
    rm -f /etc/systemd/system/continue_install.service
    systemctl daemon-reload
    clear
    
    # Создание пользователя
    echo "Creating new user"
    read -p "Enter username: " username
    useradd -m -G wheel "$username"
    
    # Безопасный ввод пароля
    while true; do
        read -sp "Enter password for $username: " password
        echo
        read -sp "Confirm password: " password_confirm
        echo
        if [[ "$password" == "$password_confirm" ]]; then
            echo "$username:$password" | chpasswd
            break
        else
            echo "Passwords don't match. Try again."
        fi
    done
    
    echo "User $username created."
    sleep 2
    clear

    # Установка DE/WM
    read -p "Would you like to install a desktop environment? (Y/n): " install_de
    if [[ "$install_de" =~ ^[Yy]$ || -z "$install_de" ]]; then
        echo "Available DEs:"
        echo "1) KDE Plasma"
        echo "2) GNOME"
        echo "3) Xfce"
        echo "4) Hyprland"
        echo "5) Cinnamon"
        echo "6) i3 window manager"
        echo "7) awesomeWM"
        read -p "Select DE (1-7): " de_choice
        clear

        case $de_choice in
            1) packages="plasma-meta kde-applications sddm" ;;
            2) packages="gnome gdm" ;;
            3) packages="xfce4 xfce4-goodies lightdm lightdm-gtk-greeter" ;;
            4) packages="hyprland sddm" ;;
            5) packages="cinnamon metacity gnome-shell lightdm lightdm-gtk-greeter" ;;
            6) packages="i3 sddm" ;;
            7) packages="awesome sddm" ;;
            *) echo "Invalid choice. Skipping DE installation." ;;
        esac

        if [[ -n "$packages" ]]; then
            echo "Installing selected DE..."
            pacman -Syu --noconfirm $packages
            
            # Включение display manager
            if [[ "$de_choice" == 1 || "$de_choice" == 4 || "$de_choice" == 6 || "$de_choice" == 7 ]]; then
                systemctl enable sddm
            elif [[ "$de_choice" == 2 ]]; then
                systemctl enable gdm
            elif [[ "$de_choice" == 3 || "$de_choice" == 5 ]]; then
                systemctl enable lightdm
            fi
        fi
    fi

    # Дополнительные пакеты
    clear
    echo "Installing common useful packages..."
    pacman -Syu --noconfirm \
        firefox \
        fastfetch \
        htop \
        git \
        wget \
        curl \
        openssh \
        networkmanager \
        pulseaudio \
        pavucontrol \
        reflector
    systemctl enable NetworkManager
    clear

    # Настройка sudo
    echo "Configuring sudo for wheel group..."
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

    # Установка yay и flatpak
    clear
    echo "Installing yay..."
    sudo -u "$username" git clone https://aur.archlinux.org/yay.git /home/"$username"/yay
    cd /home/"$username"/yay
    sudo -u "$username" makepkg -si --noconfirm
    cd ~
    rm -rf /home/"$username"/yay
    
    clear
    echo "Installing flatpak..."
    pacman -S --noconfirm flatpak

    # Завершение установки
    echo "Installation complete!"
    read -p "Press Enter to reboot..."
    reboot
fi