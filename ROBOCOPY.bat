
```
# Сохраняем оригинальную кодировку
$oldEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(866)

# Выполняем robocopy

robocopy "f:\ФОТКИ\ТУРЦИЯ 2018" "\\192.168.31.119\upload_119\SORT_files\UNSORT\ТУРЦИЯ 2018" /E /DCOPY:T /COPY:DAT /R:3 /W:5 /MT:8 

# Возвращаем исходную кодировку
[Console]::OutputEncoding = $oldEncoding
```
