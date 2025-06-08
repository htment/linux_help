
## 🔧 Шаг 1: Подготовка дисков  
Перед созданием RAID убедимся, что диски не содержат данных и не используются.  

#### 1.1. Проверяем диски  
```
lsblk | grep -E 'sdb|sdc|sdd|sde|sdf'
```
Если на дисках есть разделы, их нужно удалить:  
```
for disk in sdb sdc sdd sde sdf; do sudo sgdisk --zap-all /dev/$disk; done
```


Альтернатива (если sgdisk нет):
bash
```
for disk in sdb sdc sdd sde sdf; do sudo wipefs -a /dev/$disk; sudo dd if=/dev/zero of=/dev/$disk bs=1M count=100; done
→ wipefs стирает сигнатуры, а dd перезаписывает начало диска нулями.



```
mdadm --stop /dev/md
```
```
#### 1.2. Очищаем суперблоки (если ранее был RAID)  
```
for disk in sdb sdc sdd sde sdf; do sudo mdadm --zero-superblock /dev/$disk; done
---
```
## 🛠️ Шаг 2: Создание RAID 10  
RAID 10 (зеркало + страйпинг) обеспечивает:  
- Отказоустойчивость (можно потерять до 2 дисков, если они из разных зеркальных пар).  
- Высокую скорость (чтение/запись распределяются по страйпам).  

#### 2.1. Создаём RAID 10  
```
sudo mdadm --create --verbose /dev/md0 \
    --level=10 \
    --raid-devices=5 \
    /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf
- `--level=10 – указываем RAID 10.  
- --raid-devices=5 – количество дисков.  
- /dev/md0 – имя RAID-устройства.  
```
#### **2.2. Проверяем статус RAID**  
```
cat /proc/mdstat
```
Вывод должен быть примерно таким: 
```
md0 : active raid10 sdf[4] sde[3] sdd[2] sdc[1] sdb[0]
      209584128 blocks super 1.2 512K chunks 2 near-copies [5/5] [UUUUU]
```
- `[UUUUU]` – все диски работают.  
- Если есть `[_]` – значит, диск не подключён.  

#### **2.3. Детальная информация о RAID**  
```
sudo mdadm --detail /dev/md0
```
Проверяем:  
- **State** → `clean, degraded, recovering` (должно быть `clean`).  
- **Active Devices** → `5` (все диски должны быть активны).  

#### **2.4. Сохраняем конфигурацию RAID**  
Чтобы RAID пересоздавался после перезагрузки:  
```
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
sudo update-initramfs -u
copy
```

---

## **💾 Шаг 3: Настройка LVM поверх RAID**  
LVM даёт возможность:  
- Изменять размер томов на лету.  
- Делать снапшоты.  
- Добавлять новые диски без переразметки.  

#### **3.1. Создаём Physical Volume (PV)**  
```
sudo pvcreate /dev/md0
```
Проверяем:  
```
sudo pvs
```
Вывод: 
```
  PV         VG     Fmt  Attr PSize   PFree  
  /dev/md0          lvm2 ---   200G   200G
```

#### **3.2. Создаём Volume Group (VG)**  
```
sudo vgcreate vg_raid /dev/md0
```
Проверяем:  
```
sudo vgs
```
Вывод:  
```
  VG       #PV #LV #SN Attr   VSize   VFree  
  vg_raid   1   0   0 wz--n- 200.00g 200.00g
```

#### **3.3. Создаём Logical Volume (LV)**  
```
sudo lvcreate -l 100%FREE -n lv_data vg_raid
```
Проверяем:  
```
sudo lvs
```
Вывод: 
```
  LV      VG       Attr       LSize   Pool Origin Data%  Meta%  
  lv_data vg_raid  -wi-a----- 200.00g
```

---

## **📂 Шаг 4: Форматирование и монтирование**  
#### **4.1. Форматируем в ext4 (можно выбрать XFS, btrfs и др.)**  
```
sudo mkfs.ext4 /dev/vg_raid/lv_data
```

4.2. Монтируем том
```
vg_raid/lv_data
```

#### **4.2. Монтируем том**  
```
sudo mkdir /mnt/raid_data
sudo mount /dev/vg_raid/lv_data /mnt/raid_data
```

#### **4.3. Добавляем в `/etc/fstab` для автоматического монтирования**  
```
echo "/dev/vg_raid/lv_data /mnt/raid_data ext4 defaults 0 2" | sudo tee -a /etc/fstab
```
Проверяем:  
```
sudo mount -a
df -h | grep raid_data
```

---

## **🔍 Шаг 5: Проверка отказоустойчивости**  
#### **5.1. Имитируем сбой диска**  
```
sudo mdadm --manage /dev/md0 --fail /dev/sdb
```
Проверяем статус:  
```
sudo mdadm --detail /dev/md0
```
Должно появиться что-то вроде:  
State : clean, degraded  
Acti5.2. Удаляем "сбойный" диск : 1 (на /dev/sdb)
```

#### **5.2. Удаляем "сбойный" диск**  
```
sudo mdadm --manage /dev/md0 --remove /dev/sdb
```
Проверяем:  
```
cat /proc/mdstat
```
#### 5.3. Добавляем новый диск (если замена была)  
```
sudo mdadm --manage /dev/md0 --add /dev/sdb
RAID начнёт автоматическое восстановление:  
```
```
watch cat /proc/mdstat  # Можно следить за прогрессом
---
```
## 📌 Итог  
✅ RAID 10 – обеспечивает отказоустойчивость и скорость.  
✅ LVM – даёт гибкость в управлении томами.  
✅ Автомонтирование – после перезагрузки всё поднимется само.  
✅ Проверка на сбой – система выдержит отказ диска.  

Если нужно максимально надёжное хранилище – этот вариант оптимален! 🚀
