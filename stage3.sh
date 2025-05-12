#!/bin/bash

set -e
clear

# finding installation path
INSTALL_DIR="/tmp/InstallScript"

# Checking chroot or not
if ! grep -q '/mnt' /proc/mounts; then
    # if not - copying files into system
    echo "Copying installation files to the new system..."
    mkdir -p /mnt"$INSTALL_DIR"
    cp -r "$INSTALL_DIR"/* /mnt"$INSTALL_DIR"/
    chmod +x /mnt"$INSTALL_DIR"/*.sh

    # creating autostart service
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

    # turning service on
    arch-chroot /mnt systemctl enable continue_install.service

    echo "Installation files copied. The system will now reboot."
    echo "After reboot, the installation will continue automatically."
    read -p "Press Enter to reboot..."
    reboot
else
    echo "Continuing installation..."
    
    # turning service off
    systemctl disable continue_install.service
    rm /etc/systemd/system/continue_install.service
    clear
    
    # creating user
    echo "creating new user"
    read -p "Enter username: " username
    useradd -m -G wheel "$username"
    passwd "$username"
    echo "User $username created."
    sleep 2
    clear

    # changing parallel downloads for pacman
    # sed -i 's/^#\?ParallelDownloads = .*/ParallelDownloads = 15/' /etc/pacman.conf

    # installing DE/WM
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
        read -p "" de_choice
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
            
            # turning display manager on
            if [[ "$de_choice" == 1 || "$de_choice" == 4 || "$de_choice" == 6 || "$de_choice" == 7 ]]; then
                systemctl enable sddm
            elif [[ "$de_choice" == 2 ]]; then
                systemctl enable gdm
            elif [[ "$de_choice" == 3 || "$de_choice" == 5 ]]; then
                systemctl enable lightdm
            fi
        fi
    fi

    # additional packages
    
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

    # sudo
    echo "Configuring sudo for wheel group..."
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

    # installing yay and flatpak
    clear
    echo "installing yay"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    
    clear
    echo "installing flatpak"
    sudo pacman -S --noconfirm flatpak

    # installation complete
    echo "Installation complete"
    read -p "Press Enter to reboot..."
    reboot
fi