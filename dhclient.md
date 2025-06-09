🔹 Как принудительно сменить IP?
Способ 1: Выполнить полный сброс DHCP
bash
```
sudo dhclient -r eth0  # Освободить текущий IP
sudo dhclient eth0     # Запросить новый

```
Если dhclient нет, установите:

bash
```
sudo apt install isc-dhcp-client  # Для Debian/Ubuntu
```
Способ 2: Вручную сменить MAC-адрес
bash
```
sudo ip link set eth0 down
sudo ip link set eth0 address 00:1c:23:b5:bb:19  # Изменяем последний символ MAC
sudo ip link set eth0 up
```
