#!/bin/bash
# Скрипт установки 3proxy на операционные системы семейства CentOS

# Этот скрипт будет работать только на CentOS и, возможно, на его
# производных дистрибутивах

if [[ "$EUID" -ne 0 ]]; then
	echo "Этот скрипт нужно запускать с правами root"
	exit 2
fi


# Пробуем получить наш IP адрес
yum install wget -y
IP=$(wget -4qO- "http://whatismyip.akamai.com/")


clear
# Установка 3proxy
echo "Несколько вопросов перед началом установки"
echo "Вы можете оставлять параметры по умолчанию и просто нажимать «Enter», если они вас устраивают."
echo "Если хотите изменить параметр, то сотрите предлагаемое значение и введите своё"
echo ""
echo "Для начала введите IP адрес, на который 3proxy будет принимать подкючения"
echo "Если автоматически определённый IP адрес правильный, просто нажмите Enter"
echo "Если ничего не работает попробуйте 0.0.0.0"
read -p "Определён IP адрес: " -e -i $IP IP
echo ""
echo "На какой порт будем принимать подключения HTTP(S) (1080 рекомендуется)?"
read -p "Порт: " -e -i 1080 PORTHTTP
echo ""
echo "На какой порт будем принимать подключения SOCKS5 (1081 рекомендуется)?"
read -p "Порт: " -e -i 1081 PORTSOCKS
echo ""
echo "Имя пользователя для авторизации на прокси"
read -p "Username: " -e -i user001 BUSERNAME
echo ""
echo "Пароль пользователя для авторизации на прокси"
read -p "Password: " -e -i password BPASSWORD
echo ""
echo "Отлично. Сейчас обновим сервер и выполним установку 3proxy."
read -n1 -r -p "Нажмите любую кнопку для продолжения..."
yum install epel-release -y
yum update -y
yum upgrade -y
yum install zip unzip -y
yum install gcc -y
cd /tmp/
wget https://github.com/3proxy/3proxy/archive/refs/tags/0.9.4.tar.gz
tar -xvzf 0.9.4.tar.gz
cd 3proxy-0.9.4
make -f Makefile.Linux
mkdir /etc/3proxy
cp bin/3proxy /usr/bin/
touch /etc/3proxy/3proxy.cfg

#Делаем скрипт управления службой 3proxy
echo '[Unit]
Description=3proxy Proxy Server

[Service]
Type=simple
ExecStart=/usr/bin/3proxy /etc/3proxy/3proxy.cfg
RemainAfterExit=yes
Restart=on-failure

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/3proxy.service

#Делаем конфиг 3proxy
echo 'daemon' > /etc/3proxy/3proxy.cfg
echo 'nserver 8.8.8.8' >> /etc/3proxy/3proxy.cfg
echo 'nserver 8.8.4.4' >> /etc/3proxy/3proxy.cfg
echo 'nscache 65536' >> /etc/3proxy/3proxy.cfg

echo '' >> /etc/3proxy/3proxy.cfg

echo 'timeouts 1 5 30 60 180 1800 15 60' >> /etc/3proxy/3proxy.cfg
echo "users $BUSERNAME:CL:$BPASSWORD" >> /etc/3proxy/3proxy.cfg
echo 'log /dev/null' >> /etc/3proxy/3proxy.cfg

echo '' >> /etc/3proxy/3proxy.cfg

echo "external $IP" >> /etc/3proxy/3proxy.cfg
echo '' >> /etc/3proxy/3proxy.cfg

echo '#HTTP(S)' >> /etc/3proxy/3proxy.cfg
echo 'auth strong' >> /etc/3proxy/3proxy.cfg
echo 'flush' >> /etc/3proxy/3proxy.cfg
echo 'allow *' >> /etc/3proxy/3proxy.cfg
echo 'maxconn 64' >> /etc/3proxy/3proxy.cfg
echo "proxy -n -p$PORTHTTP" >> /etc/3proxy/3proxy.cfg

echo '' >> /etc/3proxy/3proxy.cfg

echo '#SOCKS5' >> /etc/3proxy/3proxy.cfg
echo 'auth strong' >> /etc/3proxy/3proxy.cfg
echo 'flush' >> /etc/3proxy/3proxy.cfg
echo 'allow *' >> /etc/3proxy/3proxy.cfg
echo 'maxconn 64' >> /etc/3proxy/3proxy.cfg
echo "socks -p$PORTSOCKS" >> /etc/3proxy/3proxy.cfg

#Запускаем
systemctl daemon-reload
/usr/bin/killall 3proxy
systemctl start 3proxy
systemctl enable 3proxy

echo "3proxy установлен и запущен"
read -n1 -r -p "Нажмите любую кнопку для продолжения..."
