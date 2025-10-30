https://github.com/htment/linux_help/blob/main/Удаление%20графического%20интерфейса.md
Установите Linux Mint обычным способом через графический установщик

После установки и перезагрузки откройте терминал и выполните:

bash
# Удаляем графическую оболочку Cinnamon
```
sudo apt purge cinnamon*
```
# Удаляем X сервер и графические компоненты
```
sudo apt purge xorg*
```
# Удаляем ненужные пакеты
```
sudo apt autoremove --purge
```
# Устанавливаем системные утилиты для текстового режима
```
sudo apt install ssh mc htop nano
```
# Устанавливаем режим по умолчанию - многопользовательский (текстовый)

```
sudo systemctl set-default multi-user.target
```
# Перезагружаемся
```
sudo reboot
```





2. Включение пересылки пакетов
bash
```
# Включить немедленно
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

# Сделать постоянным
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
```
3. Настройка SSH как джамп-хоста
а) Настройте SSH-сервер для проброса подключений:

Отредактируйте /etc/ssh/sshd_config:
```
bash
sudo nano /etc/ssh/sshd_config
```
Добавьте или раскомментируйте:
```
text
AllowTcpForwarding yes
GatewayPorts yes
PermitRootLogin yes  # Или настройте конкретного пользователя
PasswordAuthentication yes  # Если используете парольную аутентификацию
```
б) Перезапустите SSH:
```
bash
sudo systemctl restart ssh
```
4. Настройка правил iptables для проброса портов
а) Проброс порта 3000 на 192.168.31.115:3000:
```
bash
# DNAT - проброс входящих подключений
sudo iptables -t nat -A PREROUTING -i ens33 -p tcp --dport 3000 -j DNAT --to-destination 192.168.31.115:3000
sudo iptables -t nat -A PREROUTING -i tailscale0 -p tcp --dport 3000 -j DNAT --to-destination 192.168.31.115:3000

# Разрешить форвардинг для этих подключений
sudo iptables -A FORWARD -i ens33 -o ens33 -p tcp --dport 3000 -d 192.168.31.115 -j ACCEPT
sudo iptables -A FORWARD -i tailscale0 -o ens33 -p tcp --dport 3000 -d 192.168.31.115 -j ACCEPT
```
б) Включить MASQUERADE для исходящих подключений:
```
bash
sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
```
5. Сохранение правил iptables
bash

# Установите iptables-persistent если еще не установлен
```
sudo apt update
sudo apt install iptables-persistent -y
```
# Сохраните правила
```
sudo netfilter-persistent save
```
6. Способы подключения через джамп-хост
Способ 1: SSH Agent Forwarding (для доступа к другим хостам)
bash
# С клиента подключайтесь к джамп-хосту
```
ssh -A user@192.168.31.131
```

# Затем с джамп-хоста подключайтесь к любому хосту в сети 192.168.31.0/24
```
ssh user@192.168.31.115
ssh user@192.168.31.120
```
Способ 2: SSH ProxyJump (начиная с OpenSSH 7.3)
bash
```
# Прямое подключение через джамп-хост
ssh -J user@192.168.31.131 user@192.168.31.115
```
Способ 3: Настройка в ~/.ssh/config
Создайте/отредактируйте файл ~/.ssh/config на клиентской машине:
```
text
Host jump-host
    HostName 192.168.31.131
    User your_username
    IdentityFile ~/.ssh/your_private_key

Host *.internal
    User your_username
    IdentityFile ~/.ssh/your_private_key
    ProxyJump jump-host

# Конкретные хосты
Host host115.internal
    HostName 192.168.31.115

Host host120.internal  
    HostName 192.168.31.120
```
Теперь подключайтесь просто:
```
bash
ssh host115.internal
```
7. Проверка работы
а) Проверьте проброс порта 3000:
```
bash
# С другого хоста в сети
curl http://192.168.31.131:3000
```
# Должен показать содержимое с 192.168.31.115:3000
```
# Через Tailscale
curl http://100.80.221.32:3000
```
б) Проверьте SSH-доступ:
```
bash
# Прямое подключение через джамп
ssh -J user@192.168.31.131 user@192.168.31.115
```
8. Дополнительные настройки безопасности (рекомендуется)
bash
```
# Ограничьте SSH доступ только с доверенных IP (опционально)
sudo ufw allow from 192.168.31.0/24 to any port 22
sudo ufw enable

# Или если используете iptables напрямую
sudo iptables -A INPUT -p tcp -s 192.168.31.0/24 --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j DROP
```
Теперь ваш хост 192.168.31.131 работает как полноценный джамп-хост! Вы можете:

Подключаться по SSH к любым хостам в сети 192.168.31.0/24

Доступ к сервису на 192.168.31.115:3000 через 192.168.31.131:3000


```
# Просмотр NAT таблицы
iptables -t nat -L -n -v

# Просмотр правил FORWARD
iptables -L FORWARD -n -v

```

