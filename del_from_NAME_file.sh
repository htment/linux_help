#!/bin/bash

# Укажите директорию, в которой нужно удалить скобки и пробелы
DIRECTORY="/path/to/your/directory"

# Переход в указанную директорию
cd "$DIRECTORY" || { echo "Директория не найдена"; exit 1; }

# Используйте команду "find" для поиска файлов
find . -type f -name '*(*' -or -name '*)*' -or -name '* *' | while read -r file; do
    # Создайте новое имя файла, удаляя круглые скобки и пробелы
    new_file=$(echo "$file" | tr -d '()' | tr -d ' ')
    
    # Переименуйте файл, если новое имя отличается
    if [ "$file" != "$new_file" ]; then
        mv "$file" "$new_file"
        echo "Переименовано: $file -> $new_file"
    fi
done

echo "Готово!"
