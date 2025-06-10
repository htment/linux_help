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

    # Получаем дату изменения файла (mtime)
    local timestamp=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file")
    local month_year=$(date -d "@$timestamp" +"%m-%Y" 2>/dev/null)

    if [ -z "$month_year" ]; then
        echo "Ошибка: не удалось определить дату для файла '$file'"
        return 1
    fi

    # Создаем целевую директорию
    local target_dir="${target_path}/${month_year}"
    mkdir -p "$target_dir"



    # Получаем базовое имя файла
    local filename=$(basename "$file")

    # Проверяем, существует ли уже файл в целевой директории
    if [ ! -e "${target_dir}/${filename}" ]; then
        # Используем rsync для перемещения с сохранением всех атрибутов
#        rsync -a --remove-source-files "$file" "$target_dir/"
        rsync -a --progress "$file" "$target_dir/"

message="$(date '+%Y-%m-%d %H:%M:%S')"
echo "$message Копируем $file в $target_dir"
        # Проверяем успешность выполнения
 #       if [ $? -eq 0 ]; then
 #           # Удаляем исходный файл, если rsync его не удалил (--remove-source-files может оставить пустой файл)
 #           [ -f "$file" ] && rm "$file"
 #       else
 #           echo "Ошибка при перемещении файла '$file'"
 #           return 1
 #        fi



   else
        echo "Предупреждение: файл '$filename' уже существует в '$target_dir' и не был перемещён"
        return 1
    fi
}

export -f process_file
export target_path

# Находим все файлы (не директории) и обрабатываем их
find "$source_path" -type f -exec bash -c 'process_file "$0"' {} \;

echo "Обработка завершена. Файлы перемещены по месяцам в '$target_path' с сохранением всех атрибутов"
