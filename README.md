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

очень долго
`` sudo badblocks -sv /dev/sdc``

``sudo fsck /dev/sdc``


забить нолями

```
sudo dd if=/dev/zero of=/dev/sdc bs=1M status=progress
```
-----------------------------------------------------------------------------------

подготовим диск
```
 sudo wipefs -a /dev/sdc
```
```
sudo mdadm --manage /dev/md1 --add /dev/sdc
```
```
cat /proc/mdstat

```
использовать команду mdadm --examine для просмотра информации о старом суперблоке на диске:
  
     sudo mdadm --examine /dev/sdc

2. Удаление старого суперблока:
   - Для удаления старого суперблока с диска sdc, используйте команду mdadm --zero-superblock:
     
```
     sudo mdadm --zero-superblock /dev/sdc
```
     

### Пересобрать рейд
```

 sudo mdadm --stop /dev/md1
 sudo lsof /dev/sdc
 sudo mdadm --manage /dev/md1 --remove /dev/sdc
 sudo lsof /dev/md1

sudo fuser -m /dev/md1
sudo mdadm --grow /dev/md1 --raid-devices=4 --force
sudo  mdadm --grow /dev/md1 --array-size 976507904

sudo mdadm --grow /dev/md1 --raid-devices=4 --force
watch cat /proc/mdstat
```



### Шаги по форматированию диска sdc и монтированию к папке /SDC:

1. Форматирование диска sdc:
   - Запустите команду для форматирования диска sdc с использованием файловой системы ext4:
     
```
     sudo mkfs.ext4 /dev/sdc
 ```    

2. Создание точки монтирования /SDC:
   - Убедитесь, что каталог /SDC существует. Если нет, создайте его:
     
```
     sudo mkdir /SDC
 ```    

3. Монтирование диска sdc к /SDC:
   - Примонтируйте отформатированный диск sdc к каталогу /SDC:
     
```
     sudo mount /dev/sdc /SDC
```     

4. Проверка монтирования и настройка автозагрузки:
   - Убедитесь, что диск успешно примонтирован к /SDC и можно начать использовать его.
   - Для автоматического монтирования при перезагрузке добавьте запись в файл /etc/fstab:
     
```
     /dev/sdc   /SDC   ext4   defaults   0   2
```
     
