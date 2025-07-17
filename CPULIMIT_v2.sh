#!/bin/bash

# Настройки
CPU_LIMIT=10                  # Макс. использование CPU (%)
MEMORY_LIMIT=15               # Макс. использование памяти (%)
CHECK_INTERVAL=60             # Проверка каждые 60 сек
EXCLUDE_PIDS=""               # Исключить PID node_exporter (1120)
EXCLUDE_PROCESSES="node_exporter|CPULIMIT.sh"  # Исключить эти процессы

while true; do
    # Поиск PID процессов Node.js (исключая ненужные)
    pids=$(pgrep node | while read pid; do
        if ! ps -p $pid -o cmd= | grep -qE "$EXCLUDE_PROCESSES"; then
            echo $pid
        fi
    done)

    if [ -z "$pids" ]; then
        echo "🔍 Node.js процессы не найдены. Жду $CHECK_INTERVAL сек..."
        sleep $CHECK_INTERVAL
        continue
    fi

    # Убиваем старые процессы cpulimit
    sudo killall -q cpulimit -u $(whoami)

    echo "⚡ Ограничение Node.js процессов: CPU ≤ $CPU_LIMIT%, MEM ≤ $MEMORY_LIMIT%"
    for pid in $pids; do
        # Проверяем использование памяти
        mem_usage=$(ps -p $pid -o %mem | tail -n 1 | awk '{print int($1)}')
        cmd=$(ps -p $pid -o cmd= | cut -c1-80)
        
        if [ "$mem_usage" -gt "$MEMORY_LIMIT" ]; then
            echo "💥 Убиваю PID $pid (использует $mem_usage% памяти): $cmd"
            sudo kill -9 $pid
        else
            echo "🔹 PID $pid: CPU ≤ $CPU_LIMIT%, MEM = $mem_usage% ($cmd)"
            sudo cpulimit -l $CPU_LIMIT -p $pid -z &
        fi
    done

    sleep $CHECK_INTERVAL
done
