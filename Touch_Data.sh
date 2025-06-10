#!/bin/bash

# Функция для извлечения даты из имени файла
extract_date() {
    local basename="$1"
    local date_str=""

    # 1. VID-YYYYMMDD-WAXXXX.mp4 (VID-20241003-WA0005.mp4)
    if [[ "$basename" =~ (VID-)([0-9]{4})([0-9]{2})([0-9]{2})(-WA[0-9]+) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} 12:00:00"

    # 2. YYYYMMDD_HHMMSS.jpg (20220219_163437.jpg)
    elif [[ "$basename" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2}) ]]; then
        date_str="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:${BASH_REMATCH[6]}"

    # 3. YYYY-MM-DDHH-MM-SS.jpg (2022-09-0108-45-24.jpg)
    elif [[ "$basename" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})([0-9]{2})-([0-9]{2})-([0-9]{2}) ]]; then
        date_str="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:${BASH_REMATCH[6]}"

    # 4. YYYYMMDD_HHMMSS-COLLAGE.jpg (20210514_151219-COLLAGE.jpg)
    elif [[ "$basename" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})- ]]; then
        date_str="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:${BASH_REMATCH[6]}"

    # 5. YYYY-MM-DD_com.* (2023-04-26_com.miui.gallery.records)
    elif [[ "$basename" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})_ ]]; then
        date_str="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} 12:00:00"

    # 6. Документ-YYYY-MM-DD-HHMMSS.pdf (Документ-2022-08-28-210406.pdf)
    elif [[ "$basename" =~ (Документ-)([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2}) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} ${BASH_REMATCH[5]}:${BASH_REMATCH[6]}:${BASH_REMATCH[7]}"

    # 7. PTT-YYYYMMDD-WAXXXX.opus (PTT-20230427-WA0002.opus)
    elif [[ "$basename" =~ (PTT-)([0-9]{4})([0-9]{2})([0-9]{2})(-WA[0-9]+) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} 12:00:00"

    # 8. IMG_YYYYMMDD_HHMMSS.jpg
    elif [[ "$basename" =~ (IMG_|IMG)([0-9]{4})([0-9]{2})([0-9]{2})_?([0-9]{2})([0-9]{2})([0-9]{2}) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} ${BASH_REMATCH[5]}:${BASH_REMATCH[6]}:${BASH_REMATCH[7]}"

    # 9. VID_YYYYMMDD_HHMMSS.mp4 (VID_20210911_161654.mp4, VID_20211211_180233.mp4)
    elif [[ "$basename" =~ (VID|VID_|VID-)([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2}) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} ${BASH_REMATCH[5]}:${BASH_REMATCH[6]}:${BASH_REMATCH[7]}"

    # 10. VIDYYYYMMDDHHMMSS.mp4
    elif [[ "$basename" =~ (VID)([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2}) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} ${BASH_REMATCH[5]}:${BASH_REMATCH[6]}:${BASH_REMATCH[7]}"

    # 11. Screenshot_YYYY-MM-DD-HH-MM-SS
    elif [[ "$basename" =~ (Screenshot_|WhatsApp Image |IMG-)([0-9]{4})-([0-9]{2})-([0-9]{2})[-_]([0-9]{2})-([0-9]{2})-([0-9]{2}) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} ${BASH_REMATCH[5]}:${BASH_REMATCH[6]}:${BASH_REMATCH[7]}"

    # 12. WhatsApp Image YYYY-MM-DD at HH.MM.SS
    elif [[ "$basename" =~ (WhatsApp Image )([0-9]{4})-([0-9]{2})-([0-9]{2})( at )([0-9]{2})\.([0-9]{2})\.([0-9]{2}) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} ${BASH_REMATCH[6]}:${BASH_REMATCH[7]}:${BASH_REMATCH[8]}"

    # 13. IMG-YYYYMMDD-WAXXXX
    elif [[ "$basename" =~ (IMG-)([0-9]{4})([0-9]{2})([0-9]{2})(-WA[0-9]+) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} 12:00:00"

    # 14. YYYY-MM-DD_HH.MM.SS.jpg (2023-02-2318.42.11.jpg)
    elif [[ "$basename" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})([0-9]{2})\.([0-9]{2})\.([0-9]{2}) ]]; then
        date_str="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:${BASH_REMATCH[6]}"

    # 15. STK-YYYYMMDD-WAXXXX.webp (STK-20230412-WA0010.webp)
    elif [[ "$basename" =~ (STK-)([0-9]{4})([0-9]{2})([0-9]{2})(-WA[0-9]+) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} 12:00:00"

    # 16. AUD-YYYYMMDD-WAXXXX.m4a (AUD-20230507-WA0000.m4a)
    elif [[ "$basename" =~ (AUD-)([0-9]{4})([0-9]{2})([0-9]{2})(-WA[0-9]+) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} 12:00:00"

    # 17. DOC-YYYYMMDD-WAXXXX (DOC-20241005-WA0005)
    elif [[ "$basename" =~ (DOC-)([0-9]{4})([0-9]{2})([0-9]{2})(-WA[0-9]+) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} 12:00:00"

    # 18. DD.MM.YYYY_* (05.04.2023_7дом_ДУсЭКОДОМ.pdf)
    elif [[ "$basename" =~ ^([0-9]{2})\.([0-9]{2})\.([0-9]{4})_ ]]; then
        date_str="${BASH_REMATCH[3]}-${BASH_REMATCH[2]}-${BASH_REMATCH[1]} 12:00:00"

    # 19. YYYY-MM-DD-HH-MM-SS_*.mp4 (kate._777_2023-05-17-08-08-41_1684300121096.mp4)
    elif [[ "$basename" =~ _([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})_ ]]; then
        date_str="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:${BASH_REMATCH[6]}"

    # 20. MM-YYYY_*.pdf (05 2025-2.pdf)
    elif [[ "$basename" =~ ^([0-9]{2})\b[-]([0-9]{4}) ]]; then
        date_str="${BASH_REMATCH[2]}-${BASH_REMATCH[1]}-01 12:00:00"
    fi

    echo "$date_str"
}

# Функция для обработки файла
process_file() {
    local filename="$1"
    local basename=$(basename "$filename")
    local date_str=$(extract_date "$basename")

    if [ -n "$date_str" ]; then
        if touch -d "$date_str" "$filename" 2>/dev/null; then
            echo "Изменена дата для: $filename → $date_str"
        else
            echo "$(realpath "$filename")" >> "$FAILED_FILES"
            echo "Ошибка при изменении даты для: $filename"
        fi
    else
        echo "$(realpath "$filename")" >> "$FAILED_FILES"
        echo "Не удалось определить дату для: $filename"
    fi
}

# Проверяем аргументы командной строки
if [ $# -eq 0 ]; then
    echo "Использование: $0 <путь до цели>"
    exit 1
fi

target_dir=$1

# Проверяем существует ли директория
if [ ! -d "$target_dir" ]; then
    echo "Ошибка: Директория '$target_dir' не существует!"
    exit 1
fi

# Файл для записи ошибок
FAILED_FILES="$(dirname "$target_dir")/failed_files_$(date +%Y%m%d_%H%M%S).txt"
> "$FAILED_FILES"

echo "Начинаем обработку директории: $target_dir"
echo "Файл с ошибками будет создан: $FAILED_FILES"

# Обработка файлов
find "$target_dir" -type f | while read -r file; do
    process_file "$file"
done

echo "Обработка завершена."
echo "Всего необработанных файлов: $(wc -l < "$FAILED_FILES")"
echo "Список необработанных файлов сохранен в: $FAILED_FILES"
