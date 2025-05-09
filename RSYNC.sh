#!/bin/bash

# Путь к лог-файлу
LOGFILE=~/RSYNC_COPY3.log

# Проверка, запущен ли rsync
if pgrep -f "rsync -av" > /dev/null; then
    echo "Прерывание предыдущего выполнения rsync..." >> "$LOGFILE"
    pkill -f "rsync -av"
    sleep 2 # Даем время на завершение
fi

# Запуск rsync
echo "Запуск нового rsync..." >> "$LOGFILE"
nohup rsync -av --partial --timeout=160 --progress art@192.168.31.112:/home/upload/auto/ /raid_upl/upload/auto/ >> "$LOGFILE" 2>&1 &
