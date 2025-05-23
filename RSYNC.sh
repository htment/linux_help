#!/bin/bash

# Путь к лог-файлу
# Конфигурация
LOGFILE=~/RSYNC_COPY3.log
SOURCE_INDEX=~/SOURCE_INDEX_FINAL.txt
SOURCE_INDEX_FILE=~/SOURCE_INDEX_FILE.txt
DEST_INDEX=~/DEST_INDEX_FINAL.txt
FILE_LIST=~/RSYNC_FILE_LIST_FINAL.txt
FAILED_LIST=~/RSYNC_FAILED_FINAL.txt
SUCCESS_LIST=~/RSYNC_SUCCESS_FINAL.txt
DESTINATION_SOURCE_INDEX_FILE=~/DESTINATION_SOURCE_INDEX_FILE.txt
RSYNC_FILE=RSYNC_FILE.txt
DIST_FILE_NAME=DIST_FILE_NAME.txt
SRC_FILE_NAME=SRC_FILE_NAME.txt

SOURCE_HOST="art@192.168.31.112"
SOURCE_DIR="/home/upload"
DEST_DIR="/raid_upl/upload"
DESTINATION="/raid_upl/upload"

RSYNC_OPTS="-avh --partial --timeout=1600 --progress --bwlimit=1M --block-size=16384"
MAX_ATTEMPTS=3
RETRY_DELAY=10
SCRIPT_NAME=$(basename "$0")

# Улучшенное логирование с выводом в консоль и файл
log() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$message" | tee -a "$LOGFILE"
}

# Проверка и завершение дублирующихся процессов
ensure_single_instance() {
    local existing_pids=$(pgrep -f "$SCRIPT_NAME" | grep -v $$)
    if [ -n "$existing_pids" ]; then
        log "Найден работающий процесс (PID: $existing_pids). Завершаем..."
        kill -TERM $existing_pids 2>/dev/null
        sleep 5
        kill -KILL $existing_pids 2>/dev/null
        sleep 2
    fi
}


# Функция для создания индекса файлов
create_index() {
    log "Создание индекса файлов..."
    ssh art@192.168.31.112 "find /home/upload/ -type f"  |  sed '/^$/d' | sort > "$SOURCE_INDEX_FILE"
    if [ $? -ne 0 ]; then
        log "Ошибка при создании индекса файлов."
        return 1
    fi
     log "Индекс исходных файлов создан. Всего: $(wc -l < "$SOURCE_INDEX_FILE")"
    return 0
}

# Функция для создания индекса скопированных файлов на целевом каталоге
create_destination_index() {
    log "Создание индекса файлов на целевом каталоге..."
    find "$DESTINATION" -type f  |  sed '/^$/d' | sort > "$DESTINATION_SOURCE_INDEX_FILE"
    log "Индекс целевых файлов создан. Всего: $(wc -l < "$DESTINATION_SOURCE_INDEX_FILE")"
}

# Функция для выявления недостающих файлов и их записи в RSYNC_FILE
compare_indexes() {
    log "Сравнение индексов..."
    awk -F/ '{print $NF}'  $DESTINATION_SOURCE_INDEX_FILE > $DIST_FILE_NAME
    awk -F/ '{print $NF}'  $SOURCE_INDEX_FILE > $SRC_FILE_NAME

    grep -vx -f "$DIST_FILE_NAME" "$SRC_FILE_NAME" |  sed '/^$/d' > RSYNC_FILE_nopath.txt
    #grep -v -F -f   RSYNC_FILE_nopath.txt  $SOURCE_INDEX_FILE > "$RSYNC_FILE"
    /dev/null > "$RSYNC_FILE"
    while IFS= read -r fullpath; do
         filename=$(basename "$fullpath")
          if  grep  -F "$filename" RSYNC_FILE_nopath.txt ; then
             echo "$fullpath" >> "$RSYNC_FILE"
          fi
    done < $SOURCE_INDEX_FILE

    if [ $? -ne 0 ]; then
        log "Ошибка при сравнении индексов."
        return 1
    fi
    log "Количество файлов для копирования: $(wc -l < "$RSYNC_FILE")"
    return 0
}

# Функция для копирования одного файла
copy_single_file() {
    local source_file="$1"
    local dest_file="$2"
    local attempt

    for attempt in $(seq 1 $MAX_RETRIES); do
        log "Копирование файла '$source_file', попытка $attempt из $MAX_RETRIES"
        rsync --progress $RSYNC_OPTIONS "$source_file" "$dest_file" >> "$LOGFILE" 2>&1
        rsync_exit_code=$?

        if [ $rsync_exit_code -eq 0 ]; then
            log "Файл '$source_file' успешно скопирован."
            echo "$source_file" >> "$SUCCESSFUL_FILES"
            return 0 # Успех
        else
            log "Ошибка копирования файла '$source_file' (exit code: $rsync_exit_code). Ожидание $SLEEP_TIME секунд..."
            sleep $SLEEP_TIME
        fi
    done

    log "Не удалось скопировать файл '$source_file' после $MAX_RETRIES попыток."
    echo "$source_file" >> "$FAILED_FILES" # Записываем в список неудачных
    return 1 # Неудача
}

# Основная логика
ensure_single_instance
# 1. Создаем индекс исходных файлов
if ! create_index; then
    exit 1
fi

# 2. Создаем индекс файлов в целевом каталоге
create_destination_index

# 3. Сравниваем индексы
if ! compare_indexes; then
    exit 1
fi

# 4. Копируем все файлы, указанные в RSYNC_FILE
log "Начало копирования файлов из RSYNC_FILE..."
while IFS= read -r source_file; do
    # Добавляем префикс к имени файла
    source_file="art@192.168.31.112:$source_file"

    # Получаем имя файла относительно /home/upload
    relative_path=$(echo "$source_file" | sed 's/art@192.168.31.112:\/home\/upload\///')

    # Создаем соответствующую директорию в целевом пути, если это необходимо
    dest_dir=$(dirname "$DESTINATION/$relative_path")
    if [ ! -d "$dest_dir" ]; then
        log "Создание директории '$dest_dir'"
        mkdir -p "$dest_dir"
        if [ $? -ne 0 ]; then
            log "Ошибка при создании директории '$dest_dir'"
            echo "$source_file" >> "$FAILED_FILES" # Помечаем как неудачное
            continue # Переходим к следующему файлу
        fi
    fi

    if ! copy_single_file "$source_file" "$DESTINATION/$relative_path"; then
        log "Пропущен файл '$source_file'"
    fi

done < "$RSYNC_FILE"

log "Копирование файлов завершено."

# 5. Удаляем временные файлы (можно закомментировать для отладки)
#rm -f "$FAILED_FILES" "$RSYNC_FILE"

log "Скрипт завершен."
exit 0
