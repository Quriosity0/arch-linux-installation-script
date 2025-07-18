#!/bin/bash
set -e
clear

INSTALL_DIR="/tmp/InstallScript"

# Is in archiso
if grep -q '/mnt' /proc/mounts; then
    echo "Preparing your PC to first reboot"
    
    # Copying files
    mkdir -p /mnt"$INSTALL_DIR"
    cp -r "$INSTALL_DIR"/* /mnt"$INSTALL_DIR"/
    chmod +x /mnt"$INSTALL_DIR"/*.sh

    # creating service
    cat > /mnt/etc/systemd/system/continue_install.service <<EOF
[Unit]
Description=Continue Arch Installation
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash $INSTALL_DIR/stage3.sh
WorkingDirectory=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

    # activating service
    arch-chroot /mnt systemctl enable continue_install.service
    echo "System will reboot to continue installation..."
    read -p "Press Enter to reboot..."
    shutdown -r now

else
    # Second reboot
    echo "Resuming installation..."
    
    # deleting service
    systemctl disable continue_install.service --now
    rm /etc/systemd/system/continue_install.service
    clear
    
    # creating user
    echo "Creating new user"
    read -p "Enter username: " username
    useradd -m -G wheel "$username"
    
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

    # changing parallel downloads for pacman
    # echo "changing parallel downloads to 15"
    # sed -i 's/^#\?ParallelDownloads = .*/ParallelDownloads = 15/' /etc/pacman.conf

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
            
            # Enable display manager
            if [[ "$de_choice" == 1 || "$de_choice" == 4 || "$de_choice" == 6 || "$de_choice" == 7 ]]; then
                systemctl enable sddm
            elif [[ "$de_choice" == 2 ]]; then
                systemctl enable gdm
            elif [[ "$de_choice" == 3 || "$de_choice" == 5 ]]; then
                systemctl enable lightdm
            fi
        fi
    fi

    # Additional packages
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
    echo "Installing yay..."
    cd /home/"$username" || echo "directory not found"
    git clone https://aur.archlinux.org/yay.git 
    cd yay || echo "directory \"yay\" not found"
    sudo makepkg -si --noconfirm
    cd /home/"$username" || echo "directory not found"
    rm -rf yay
    
    clear
    echo "Installing flatpak..."
    pacman -S --noconfirm flatpak

    # Installation complete!
    echo "Installation complete!"
    read -p "Press Enter to reboot..."
    reboot
fi