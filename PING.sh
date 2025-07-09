#!/bin/bash

# Функция для выхода и восстановления терминала
function cleanup {
  tput cnorm # Показать курсор
  echo ""     # Добавить пустую строку для чистого вывода после завершения
  exit
}

# Перехват сигналов завершения, чтобы восстановить курсор
trap cleanup SIGINT SIGTERM EXIT

# Скрыть курсор, чтобы он не мигал во время обновления
tput civis

# Чтение списка хостов из файла
host_file="host_list_ping" # Имя файла со списком хостов

if [ ! -f "$host_file" ]; then
  echo "Ошибка: Файл '$host_file' не найден."
  echo "Создайте его и добавьте по одному хосту на строку."
  cleanup
fi

hosts=( $(cat "$host_file") )

if [ ${#hosts[@]} -eq 0 ]; then
  echo "Ошибка: Файл '$host_file' пуст."
  cleanup
fi

# Определяем максимальную длину имени хоста для форматирования таблицы
max_host_len=0
for h in "${hosts[@]}"; do
  if (( ${#h} > max_host_len )); then
    max_host_len=${#h}
  fi
done

# Минимальная ширина для колонки хоста (чтобы заголовок "Хост" поместился)
host_col_width=$((max_host_len > 4 ? max_host_len : 4))
# Ширина для колонки статуса (чтобы "----Недоступен" поместился)
status_col_width=12 # "----Недоступен" = 12 символов

# Отступы для красивого отображения в printf
host_printf_width=$((host_col_width + 2)) # +2 для пробелов по краям
status_printf_width=$((status_col_width + 2)) # +2 для пробелов по краям

# Вывод статической части таблицы (один раз)
echo "Результаты проверки доступности хостов:"
echo "--------------------------------------"
printf "| %-${host_printf_width}s | %-${status_printf_width}s |\n" "Хост" "Состояние"
printf "|-%-${host_printf_width}s-|-%-${status_printf_width}s-|\n" $(printf '%0.s-' $(seq 1 $((host_printf_width)))) $(printf '%0.s-' $(seq 1 $((status_printf_width))))

# Вывод начальных строк для каждого хоста (они будут перезаписываться)
# Запоминаем, сколько строк вывели для хостов, чтобы потом вернуться курсором
num_host_lines=0
for host in "${hosts[@]}"; do
  printf "| %-${host_printf_width}s | %-${status_printf_width}s |\n" "$host" "Ожидание..."
  ((num_host_lines++))
done

# Непрерывная проверка доступности хостов
while true; do
  # Перемещаем курсор вверх на количество строк, равное количеству хостов
  # Это ставит курсор на первую строку со статусом хоста
  tput cuu "$num_host_lines"

  # Проверка доступности каждого хоста
  for host in "${hosts[@]}"; do
    # Пинг хоста с таймаутом 1 секунда (-W 1)
    ping -c 1 -W 1 "$host" &> /dev/null
    # Определение статуса доступности
    if [ $? -eq 0 ]; then
      stat="ДОСТУПЕН"
    else
      stat="----Недоступен"
    fi
    # Вывод обновленной строки таблицы
    # \r - возвращает курсор в начало текущей строки
    # tput el - стирает от курсора до конца строки (важно, если новый статус короче старого)
    printf "\r| %-${host_printf_width}s | %-${status_printf_width}s |" "$host" "$stat"
    tput el
    echo "" # Переход на новую строку (для следующего хоста)
  done

  # Задержка между проверками (например, 2 секунды)
  sleep 2
done
