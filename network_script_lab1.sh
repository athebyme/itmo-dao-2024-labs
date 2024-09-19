
#!/bin/bash

function network_card_info(){
delimiter;
echo "Информация о сетевой карте" $'\n'
interface=$(ip link show | awk -F: '$0 !~ "lo|vir|wl|docker|^[^0-9]"{print $2;getline}')

for iface in $interface; do
  echo "Интерфейс:" $iface $'\n'
  echo "Модель сетевой карты:" $'\n'
  lspci | grep -i ethernet

  ethtool $iface | grep -E "Speed|Duplex"
  ethtool $iface | grep "Link detected"

  echo $'\n' "MAC-адрес: $(ip link show $iface | grep link/ether | awk '{print $2}')"  $'\n'

done
}

function ipv4_config(){
delimiter;
echo $'\n' "Информация о текущей IPv4 конфигурации: " $'\n'
ip address show | grep -w inet

echo "DNS серверы: " $'\n'

cat /etc/resolv.conf | grep nameserver
}

function static_scenario(){
delimiter;
echo "Настройка интерфейса по сценарию 1. Статическая конфигурация."
IFACE="enp0s3"
IP="10.100.0.2"
MASK="255.255.255.0"
GATE="10.100.0.1"
DNS="8.8.8.8"

echo
echo "Статическая адресация со следующими параметрами:" $'\nIP: ' $IP $'\nMASK: ' $MASK $'\nGATE: ' $GATE $'\nDNS: ' $DNS

sudo ip address add $IP/$MASK dev $IFACE
sudo ip route add default via $GATE
sudo bash -c "echo 'nameserver' $DNS > /etc/resolv.conf"

echo $'\nГотово!\n'
}


function dh_scenario(){
delimiter;

echo $'Настройка интерфейса по сценарию 2. DHCP\n'

read -p "Введите название интерфейса: " IFACE

if ! ip link show "$IFACE" > /dev/null 2>&1; then
  echo "Интерфейс $IFACE не найден."
  return;
fi

echo -n "Сброс текущих настроек для $IFACE..."
sudo ip addr flush dev "$IFACE"

sudo dhclient $IFACE

if [ $? -eq 0 ]; then
 echo $'\nНастройки сети получены через DHCP для интерфейса $IFACE.\n'

 echo $'Текущие настройки IP:\n'
 ip addr show $IFACE | grep -w inet
 echo $'Текущие настройки шлюзов:\n'
 ip route show dev $IFACE | grep default

 echo $'DNS серверы:\n'
 cat /etc/resolv.conf
else
 echo "Не удалось получить настройки через DHCP для интерфейса $IFACE."
fi
}


function configure_scenario (){
while true; do
echo
echo "1. Статическая адресация"
echo "2. DHCP конфигурация"
echo "3. Вернуться назад"

read -p "Выберите действие: " choice2

case $choice2 in
1) static_scenario ;;
2) dh_scenario ;;
3) echo "Вернуться назад"; return ;;
*) echo "Выберите действие из списка" ;;
esac
echo

done
}


function delimiter(){
echo $'\n-------------------------------------------------------------------------\n'
}


while true; do

delimiter;
echo "Меню:" $'\n'
echo "1. Узнать инофрмацию о сетевой карте"
echo "2. Узнать информацию о текущем IPv4 конфиге"
echo "3. Настроить сетевой интерфейс"
echo "4. Выход"

echo

read -p "Выберите действие: " choice

case $choice in
1) network_card_info ;;
2) ipv4_config ;;
3) configure_scenario ;;
4) echo "Закрытие скрипта ..."; exit ;;
*) echo "Неверный выбор. Выберите из списка." ;;
esac

done
