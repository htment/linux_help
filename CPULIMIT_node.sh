#!/bin/bash

# Проверка установки cpulimit
if ! command -v cpulimit &> /dev/null
then
    echo "cpulimit не установлен. Пожалуйста, установите его с помощью: sudo apt-get install cpulimit"
    exit 1
fi

while true
do
    # Поиск PID всех процессов Node.js
    pids=$(pgrep node)

    # Проверка, были ли найдены процессы Node.js
    if [ -z "$pids" ]
    then
        echo "Процессы Node.js не найдены. Сплю 5 минут..."
        sleep 300
        continue
    fi

    # Завершение существующих процессов cpulimit для найденных PID
    for pid in $pids
    do
        sudo killall -q cpulimit -u $(whoami)
    done

    # Ограничение использования CPU для каждого процесса Node.js с помощью cpulimit
    echo "Ограничение использования CPU процессов Node.js до 50%."
    for pid in $pids
    do
        echo "Ограничение PID: $pid"
        sudo cpulimit -l 50 -p $pid &
    done

    echo "Ограничение CPU применено ко всем процессам Node.js. Сплю 5 минут..."
    sleep 300
done
