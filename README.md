# linux_help


копирование в фоне 
```
nohup rsync -av --progress auto/ art@192.168.31.112:/mnt/ > rsync_status.log 2>&1 &
tail -f rsync_status.log
```
-----------------------------------------------------------------------------------
## Анализ проблем с диском


```
lsblk

art@art-virtual-machine:~$ sudo dd if=/dev/sdc of=/dev/null bs=1M count=1024
```
```
dd: ошибка чтения '/dev/sdc': Ошибка ввода/вывода
6+1 записей получено
6+1 записей отправлено
7106560 байт (7,1 MB, 6,8 MiB) скопирован, 1,98313 s, 3,6 MB/s
```
```
 sudo udevadm info --query=all --name=/dev/sdc
 sudo hdparm -I /dev/sdc
```
-----------------------------------------------------------------------------------
