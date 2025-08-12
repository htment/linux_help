#!/bin/bash

# Проверяем, что передан аргумент с директорией
if [ -z "$1" ]; then
    echo "Использование: $0 <директория>"
    exit 1
fi

target_dir="$1"

# Проверяем существование директории
if [ ! -d "$target_dir" ]; then
    echo "Ошибка: директория '$target_dir' не существует"
    exit 1
fi

echo "Поиск дубликатов в директории: $target_dir"
echo "----------------------------------------"

declare -A file_hashes
declare -A file_names
total_files=0
duplicates_found=0
deleted_files=0

# Функция для обработки файлов
process_file() {
    local file="$1"
    ((total_files++))
    
    # Пропускаем символьные ссылки и директории
    if [ -L "$file" ] || [ -d "$file" ]; then
        echo "[Пропуск] $file (это ссылка или директория)"
        return
    fi
    
    echo "[Анализ] Файл $total_files: $file"
    
    # Вычисляем MD5 хеш файла
    hash=$(md5sum "$file" | awk '{print $1}')
    
    if [ -n "${file_hashes[$hash]}" ]; then
        ((duplicates_found++))
        echo "  [!] ДУБЛИКАТ (хеш: $hash)"
        echo "  Оригинал: ${file_names[$hash]}"
        echo "  Копия:    $file"
        echo "  Удаление дубликата..."
        if rm "$file"; then
            ((deleted_files++))
            echo "  [Успешно] Файл удален"
        else
            echo "  [Ошибка] Не удалось удалить файл"
        fi
    else
        file_hashes["$hash"]=1
        file_names["$hash"]="$file"
        echo "  [+] Уникальный файл (хеш: $hash)"
    fi
    
    echo "----------------------------------------"
}

# Рекурсивно обходим директорию
while IFS= read -r -d '' file; do
    process_file "$file"
done < <(find "$target_dir" -type f -print0)

echo "Итоги:"
echo "Всего обработано файлов: $total_files"
echo "Найдено дубликатов: $duplicates_found"
echo "Удалено файлов: $deleted_files"
