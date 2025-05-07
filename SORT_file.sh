#!/bin/bash

# Проверка количества аргументов
if [ "$#" -ne 2 ]; then
    echo "Использование: $0 <исходный_путь> <путь_назначения>"
    exit 1
fi

source_path="$1"
target_path="$2"

# Проверка существования исходного пути
if [ ! -d "$source_path" ]; then
    echo "Ошибка: исходный путь '$source_path' не существует или не является директорией"
    exit 1
fi

# Создание целевого пути, если он не существует
mkdir -p "$target_path"

# Функция для обработки одного файла
process_file() {
    local file="$1"

    # Получаем дату создания файла (или изменения, если creation time недоступен)
    local timestamp=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file")
    local month_year=$(date -d "@$timestamp" +"%m-%Y" 2>/dev/null)

    if [ -z "$month_year" ]; then
        echo "Ошибка: не удалось определить дату для файла '$file'"
        return 1
    fi

    # Создаем целевую директорию
    local target_dir="${target_path}/${month_year}"
    mkdir -p "$target_dir"

    # Перемещаем файл (с проверкой на перезапись)
