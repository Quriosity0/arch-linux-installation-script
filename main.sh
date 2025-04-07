#!/bin/bash

clear
echo "Welcome to Quriosity's Arch installation script"
echo "Checking internet connection..."

# Функция для проверки интернета
check_internet() {
    if ping -c 3 archlinux.org &> /dev/null; then
        return 0  # Интернет есть
    else
        return 1  # Интернета нет
    fi
}

# Основная проверка
if check_internet; then
    echo "Internet connection detected!"
    ./stage1.sh
    exit 0
else
    echo "ERROR: No internet connection detected!"

    # Предлагаем варианты
    echo -e "\nOptions:"
    echo "1) Try to reconnect and check again"
    echo "2) Continue without internet (NOT recommended)"
    echo "3) Exit"

    read -p "Choose an option (1-3): " choice

    case $choice in
        1)
            echo "Trying to reconnect..."
            # Попытка запустить WiFi-менеджер (измените под свою систему)
            if command -v nmtui &> /dev/null; then
                nmtui
            elif command -v iwctl &> /dev/null; then
                iwctl
            else
                echo "No network manager found. Please connect manually."
            fi

            # Повторная проверка
            if check_internet; then
                echo "Success! Internet is working now."
                ./stage1.sh
            else
                echo "Still no internet. Exiting."
                exit 1
            fi
            ;;
        2)
            echo "Continuing without internet at your own risk..."
            ./stage1.sh
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Exiting."
            exit 1
            ;;
    esac
fi
