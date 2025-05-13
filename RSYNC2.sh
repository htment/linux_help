#!/bin/bash

# Путь к лог-файлу
LOGFILE=~/RSYNC_COPY3.log
INDEX_FILE=~/RSYNC_INDEX.txt
FAILED_FILES=~/RSYNC_FAILED.txt

SOURCE="art@192.168.31.112:/home/upload/"
DESTINATION="/raid_upl/upload"

RSYNC_OPTIONS="-av --partial --timeout=1600 --progress --bwlimit=1000" # Опции rsync
MAX_RETRIES=5       # Максимальное количество попыток
SLEEP_TIME=60
SCRIPT_NAME=$(basename "$0")

# Функция для добавления даты в лог
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Функция для проверки, запущен ли скрипт
is_running() {
  local count=$(ps -ef | grep "$SCRIPT_NAME" | grep -v grep | grep -v $$ | wc -l)
  if [ "$count" -gt 0 ]; then
    return 0 # Script is running
  else
    return 1 # Script is not running
  fi
}

# Функция для принудительного завершения предыдущего процесса
kill_existing_process() {
  local pid
  pid=$(ps -ef | grep "$SCRIPT_NAME" | grep -v grep | grep -v $$ | awk '{print $2}')
  #pid=$( ps -ef | grep RSYNC.sh |  grep -v grep | grep -v $$ | awk '{print $2}')
  if [ -n "$pid" ]; then
    log "Обнаружен другой запущенный процесс (PID: $pid). Отправка SIGTERM..."
    kill -TERM "$pid" 2>/dev/null
    sleep 5
    if ps -p "$pid" > /dev/null; then
      log "Процесс (PID: $pid) не завершился вовремя. Отправка SIGKILL..."
      kill -KILL "$pid" 2>/dev/null
    fi
    log "Старый процесс (PID: $pid) завершен."
  else
    log "Не обнаружено других запущенных процессов."
  fi
}


# Функция для создания индекса файлов (локально, т.к. ssh)
create_index() {
  log "Создание индекса файлов..."
  ssh art@192.168.31.112 "find /home/upload/ -type f" > "$INDEX_FILE"
  if [ $? -ne 0 ]; then
    log "Ошибка при создании индекса файлов."
    return 1
  fi
  log "Индекс файлов создан."
  return 0
}

# Функция для копирования одного файла
copy_single_file() {
  local source_file="$1"
  local dest_file="$2"
  local attempt

  for attempt in $(seq 1 $MAX_RETRIES); do
    log "Копирование файла '$source_file', попытка $attempt из $MAX_RETRIES"
    # Копирование происходит с помощью команды rsync
    rsync $RSYNC_OPTIONS "$source_file" "$dest_file" >> "$LOGFILE" 2>&1
    rsync_exit_code=$?

    if [ $rsync_exit_code -eq 0 ]; then
      log "Файл '$source_file' успешно скопирован."
      return 0 # Успех
    else
      log "Ошибка копирования файла '$source_file' (exit code: $rsync_exit_code). Waiting $SLEEP_TIME seconds..."
      sleep $SLEEP_TIME
    fi
  done

  log "Не удалось скопировать файл '$source_file' после $MAX_RETRIES попыток."
  echo "$source_file" >> "$FAILED_FILES" # Записываем в список неудачных
  return 1 # Неудача
}

# Основная логика

# 0. Проверяем, не запущен ли уже скрипт
# if is_running; then
#     log "Скрипт уже запущен. Завершение..."
#     kill_existing_process #Kill the old process

# else
#     log "Скрипт не запущен. Начинаем выполнение..."
# fi

     kill -9 $(ps -ef | grep RSYNC.sh | grep -v grep | grep -v $$ | awk '{print $2}')
     kill -9 $(ps -ef | grep rsync | grep -v grep | grep -v $$ | awk '{print $2}')


# 1. Создаем индекс файлов
if ! create_index; then
  exit 1
fi

# 2. Создаем список неудачных файлов (если его нет)
touch "$FAILED_FILES"

# 3. Читаем индекс и копируем файлы
log "Начало копирования файлов из индекса..."
while IFS= read -r source_file; do
  # Make sure to add art@192.168.31.112: to the source file, rsync expects it
  source_file="art@192.168.31.112:$source_file"
  # Get the file name relative to /home/upload
  relative_path=$(echo "$source_file" | sed 's/art@192.168.31.112:\/home\/upload\///')

  # Create the corresponding directory in the destination if needed
  dest_dir=$(dirname "$DESTINATION/$relative_path")
  if [ ! -d "$dest_dir" ]; then
    log "Создание директории '$dest_dir'"
    mkdir -p "$dest_dir"
    if [ $? -ne 0 ]; then
      log "Ошибка при создании директории '$dest_dir'"
      echo "$source_file" >> "$FAILED_FILES" # Mark as failed
      continue # Continue to the next file
    fi
  fi
  if ! copy_single_file "$source_file" "$DESTINATION/$relative_path"; then
    log "Пропущен файл '$source_file'"
  fi
done < "$INDEX_FILE"

log "Первый этап копирования завершен."

# 4. Копируем неудачные файлы
log "Начало копирования неудачных файлов..."
while IFS= read -r source_file; do
  # Get the file name relative to /home/upload
  relative_path=$(echo "$source_file" | sed 's/art@192.168.31.112:\/home\/upload\///')
  if ! copy_single_file "$source_file" "$DESTINATION/$relative_path"; then
    log "Не удалось скопировать неудачный файл '$source_file'"
  fi
done < "$FAILED_FILES"

log "Копирование неудачных файлов завершено."

# 5. Удаляем список неудачных файлов (можно закомментировать для отладки)
rm "$FAILED_FILES"

log "Скрипт завершен."
exit 0
