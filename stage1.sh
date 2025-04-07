clear
echo "Разметка дисков"
echo
echo "Доступные диски:"
lsblk -dno NAME,SIZE,MODEL | grep -v "loop"

read -p "Введите имя диска: " disk_name
DISK="/dev/$disk_name"

# Проверка существования диска
if [ ! -b "$DISK" ]; then
    echo "Ошибка: $DISK не существует!"
    exit 1
fi

echo "Выбранный диск: $DISK"
