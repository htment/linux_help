#!/bin/bash

# Файл для записи путей к файлам, у которых не удалось определить дату
FAILED_FILES="failed_files.txt"
> "$FAILED_FILES"  # Очищаем файл, если он существует

# Функция для извлечения даты из имени файла и изменения времени модификации
process_file() {
    local filename="$1"
    local basename=$(basename "$filename")
    local date_str=""

    # Попытка извлечь дату в формате IMG_YYYYMMDD_HHMMSS
    if [[ "$basename" =~ (IMG_|IMG)([0-9]{4})([0-9]{2})([0-9]{2})_?([0-9]{2})([0-9]{2})([0-9]{2}) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} ${BASH_REMATCH[5]}:${BASH_REMATCH[6]}:${BASH_REMATCH[7]}"
    
    # Попытка извлечь дату в формате VIDYYYYMMDDHHMMSS (видео файлы)
    elif [[ "$basename" =~ (VID)([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2}) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} ${BASH_REMATCH[5]}:${BASH_REMATCH[6]}:${BASH_REMATCH[7]}"
    
    # Попытка извлечь дату в формате Screenshot_YYYY-MM-DD-HH-MM-SS
    elif [[ "$basename" =~ (Screenshot_|WhatsApp Image |IMG-)([0-9]{4})-([0-9]{2})-([0-9]{2})[-_]([0-9]{2})-([0-9]{2})-([0-9]{2}) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} ${BASH_REMATCH[5]}:${BASH_REMATCH[6]}:${BASH_REMATCH[7]}"
    
    # Попытка извлечь дату в формате WhatsApp Image YYYY-MM-DD at HH.MM.SS
    elif [[ "$basename" =~ (WhatsApp Image )([0-9]{4})-([0-9]{2})-([0-9]{2})( at )([0-9]{2})\.([0-9]{2})\.([0-9]{2}) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} ${BASH_REMATCH[6]}:${BASH_REMATCH[7]}:${BASH_REMATCH[8]}"
    
    # Попытка извлечь дату в формате IMG-YYYYMMDD-WAXXXX
    elif [[ "$basename" =~ (IMG-)([0-9]{4})([0-9]{2})([0-9]{2})(-WA[0-9]+) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} 12:00:00"
    fi

    if [ -n "$date_str" ]; then
        # Изменяем дату модификации файла
        if touch -d "$date_str" "$filename" 2>/dev/null; then
            echo "Изменена дата для: $filename → $date_str"
        else
            echo "$(realpath "$filename")" >> "$FAILED_FILES"
            echo "Ошибка при изменении даты для: $filename"
        fi
    else
        # Записываем в файл, если дату не удалось определить
        echo "$(realpath "$filename")" >> "$FAILED_FILES"
        echo "Не удалось определить дату для: $filename"
    fi
}

# Рекурсивный поиск файлов и обработка каждого
find . -type f | while read -r file; do
    process_file "$file"
done

echo "Обработка завершена. Файлы с неудачными попытками сохранены в $FAILED_FILES"
