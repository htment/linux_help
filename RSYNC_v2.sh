# Путь к лог-файлу
LOGFILE=~/RSYNC_COPY3.log
SOURCE_INDEX_FILE=~/SOURCE_INDEX.txt
DESTINATION_SOURCE_INDEX_FILE=~/DESTINATION_SOURCE_INDEX.txt
RSYNC_FILE=~/RSYNC_FILE.txt
FAILED_FILES=~/RSYNC_FAILED.txt
SUCCESSFUL_FILES=~/RSYNC_SUCCESSFUL.txt

SOURCE="art@192.168.31.112:/home/upload/"
SOURCE_ADDRESS="art@192.168.31.112"
SOURCE_PATH="/home/upload"
DESTINATION="/raid_upl/upload"

RSYNC_OPTIONS="-av --partial --timeout=1600 --progress --bwlimit=1000" # Опции rsync
MAX_RETRIES=3       # Максимальное количество попыток
SLEEP_TIME=20
SCRIPT_NAME=$(basename "$0")

# Функция для добавления даты в лог
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Функция для создания индекса файлов
create_index() {
    log "Создание индекса файлов..."
     ssh art@192.168.31.112 "find /home/upload/ -type f | awk -F/ '{print \$NF}'" > "$SOURCE_INDEX_FILE"
    if [ $? -ne 0 ]; then
        log "Ошибка при создании индекса файлов."
        return 1
    fi
    log "Индекс файлов создан."
    return 0
}



# Функция для создания индекса скопированных файлов на целевом каталоге
create_destination_index() {
    log "Создание индекса файлов на целевом каталоге..."
    find /raid_upl/upload -type f | awk -F/ '{print $NF}' > "$DESTINATION_SOURCE_INDEX_FILE"
    log "Индекс файлов на целевом каталоге создан."
}


# Функция для выявления недостающих файлов и их записи в RSYNC_FILE
compare_indexes() {
    log "Сравнение индексов..."
    #grep -vx  "$DESTINATION_SOURCE_INDEX_FILE" "$SOURCE_INDEX_FILE" > "$RSYNC_FILE"

    sort "$DESTINATION_SOURCE_INDEX_FILE" | uniq > sorted_dest.txt
    sort "$SOURCE_INDEX_FILE" | uniq > sorted_src.txt   

    #comm -23 <(sort "$DESTINATION_SOURCE_INDEX_FILE" | uniq) <(sort "$SOURCE_INDEX_FILE" | uniq) > "$RSYNC_FILE"
    comm -23 sorted_src.txt sorted_dest.txt  > "$RSYNC_FILE"
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
        rsync $RSYNC_OPTIONS "$source_file" "$dest_file" >> "$LOGFILE" 2>&1
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


############################################################################################


# Основная логика

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

# # 4. Копируем все файлы, указанные в RSYNC_FILE
# log "Начало копирования файлов из RSYNC_FILE..."
 while IFS= read -r source_file; do
     # Добавляем префикс к имени файла
     # ищем 
     echo " ищем $source_file" 
     log " ищем $source_file" 
     # path_source=$(ssh $SOURCE_ADDRESS "find $SOURCE_PATH -name $source_file" )
     # echo $path_source
#      log $path_source
#     source_file="art@192.168.31.112:$source_file"
    
#     # Получаем имя файла относительно /home/upload
#     relative_path=$(echo "$source_file" | sed 's/art@192.168.31.112:\/home\/upload\///')
    
#     # Создаем соответствующую директорию в целевом пути, если это необходимо
#     dest_dir=$(dirname "$DESTINATION/$relative_path")
#     if [ ! -d "$dest_dir" ]; then
#         log "Создание директории '$dest_dir'"
#         mkdir -p "$dest_dir"
#         if [ $? -ne 0 ]; then
#             log "Ошибка при создании директории '$dest_dir'"
#             echo "$source_file" >> "$FAILED_FILES" # Помечаем как неудачное
#             continue # Переходим к следующему файлу
#         fi
#     fi

#     if ! copy_single_file "$source_file" "$DESTINATION/$relative_path"; then
#         log "Пропущен файл '$source_file'"
#     fi
 done < "$RSYNC_FILE"
