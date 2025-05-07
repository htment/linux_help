# linux_help


копирование в фоне 
```
nohup rsync -av --progress auto/ art@192.168.31.112:/mnt/ > rsync_status.log 2>&1 &
tail -f rsync_status.log
```
-----------------------------------------------------------------------------------
## Анализ проблем с диском
Измерение скорости работы диска можно выполнить с помощью различных инструментов и команд в зависимости от операционной системы и ваших предпочтений. Вот несколько распространённых методов, которые могут быть использованы на Linux и Windows:

На Linux
1. dd:
Команда dd позволяет произвести тесты на запись и чтение. Вот пример, который записывает 1 ГБ файла и измеряет скорость записи:
``dd if=/dev/zero of=testfile bs=1G count=1 oflag=direct``

Для тестирования скорости чтения:
``dd if=testfile of=/dev/null bs=1G count=1``

Примечание: После тестов, не забудьте удалить созданный файл:
``rm testfile``

2. ioping:
ioping — это утилита, предназначенная для проверки скорости диска с помощью I/O запросов.
Установка:
``sudo apt install ioping``

Использование:
``ioping -c 10 .``

Эта команда будет отправлять 10 запросов на чтение к текущему каталогу и покажет результаты.

3. fio:
fio - это мощный инструмент для тестирования I/O. Он позволяет выполнять более сложные тесты.
Установка:
``sudo apt install fio``

Простой тест на запись:
``fio --name=write-test --ioengine=libaio --rw=write --bs=4k --size=1G --numjobs=1 --runtime=30s --group_reporting``

Простой тест на чтение:
``fio --name=read-test --ioengine=libaio --rw=read --bs=4k --size=1G --numjobs=1 --runtime=30s --group_reporting``

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
использовать команду mdadm --examine для просмотра информации о старом суперблоке на диске:
  ``
     sudo mdadm --examine /dev/sdc
``
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



------------------------------------------------------------

*Алгоритм для сборки RAID 10 из дисков sdc, sdd, sde, sdf и sdg*

*Шаг 1: Проверка доступных дисков*
1. Убедитесь, что диски sdc, sdd, sde, sdf и sdg не содержат важных данных и не размечены.
2. Используйте команду `lsblk` или `fdisk -l`, чтобы убедиться, что диски правильно распознаются.

*Шаг 2: Установка необходимых утилит*
1. Установите пакет `mdadm`, если он еще не установлен:
```   
   sudo apt-get update
   sudo apt-get install mdadm
```   


*Шаг 3: Создание RAID 10*
1. Выполните следующую команду для создания RAID 10 из дисков:
  ``` 
   sudo mdadm --create --verbose /dev/md0 --level=10 --raid-devices=5 /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg
  ``` 

   Замените `/dev/md0` на желаемое имя для RAID устройства.

*Шаг 4: Проверьте состояние RAID*
1. С помощью команды `cat /proc/mdstat` проверьте состояние созданного RAID:
```   
   cat /proc/mdstat
   
```

*Шаг 5: Форматирование RAID устройства*
1. Отформатируйте RAID устройство в нужной файловой системе, например, ext4:
 ```  
   sudo mkfs.ext4 /dev/md0
```

*Шаг 6: Монтирование RAID*
1. Создайте точку монтирования:
  ``` 
   sudo mkdir /mnt/raid10
   
```
2. Смонтируйте RAID устройство:
 ```  
   sudo mount /dev/md0 /mnt/raid10
   
```

*Шаг 7: Обновление файла fstab*
1. Для автоматического монтирования RAID устройства при загрузке добавьте запись в файл `/etc/fstab`:
```   
   /dev/md0    /mnt/raid10    ext4    defaults    0    0
   
```

*Шаг 8: Завершение*
1. Проверьте, что RAID корректно смонтирован:
 ```  
   df -h

```
     
