#!/bin/bash
# Project Jarkom - The Shadow of the East
# Script Config & Routing & Firewall

# Cek hostname untuk menentukan config mana yang dipakai
HOST=$(hostname)
echo "Mengkonfigurasi Node: $HOST..."

# Reset Config Lama
echo "Menghapus config lama..."
echo "auto lo" > /etc/network/interfaces
echo "iface lo inet loopback" >> /etc/network/interfaces

# --- KONFIGURASI ROUTER PUSAT ---

if [ "$HOST" == "Osgiliath" ]; then
    # Config Interface
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.71.2.45
    netmask 255.255.255.252

auto eth2
iface eth2 inet static
    address 10.71.2.37
    netmask 255.255.255.252

auto eth3
iface eth3 inet static
    address 10.71.2.41
    netmask 255.255.255.252
EOF
    
    # Restart Network
    /etc/init.d/networking restart
    
    # Enable Forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Routing Manual
    ip route add 10.71.2.8/29 via 10.71.2.46
    ip route add 10.71.2.16/29 via 10.71.2.38
    ip route add 10.71.1.128/26 via 10.71.2.38
    ip route add 10.71.2.0/29 via 10.71.2.38
    ip route add 10.71.0.0/24 via 10.71.2.42
    ip route add 10.71.1.192/27 via 10.71.2.42
    ip route add 10.71.2.24/29 via 10.71.2.42
    ip route add 10.71.1.0/25 via 10.71.2.42
    ip route add 10.71.1.224/27 via 10.71.2.42

    # SNAT (Misi 2 - No Masquerade)
    # Ambil IP DHCP eth0 secara otomatis lalu pasang rule SNAT
    IP_WAN=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source $IP_WAN
    echo "SNAT diaktifkan menggunakan IP: $IP_WAN"


# --- KONFIGURASI CABANG BARAT (MORIA AREA) ---

elif [ "$HOST" == "Moria" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.2.38
    netmask 255.255.255.252
    gateway 10.71.2.37

auto eth1
iface eth1 inet static
    address 10.71.2.17
    netmask 255.255.255.248

auto eth2
iface eth2 inet static
    address 10.71.2.49
    netmask 255.255.255.252
EOF
    /etc/init.d/networking restart
    echo 1 > /proc/sys/net/ipv4/ip_forward
    # Routing ke Wilderland
    ip route add 10.71.1.128/26 via 10.71.2.50
    ip route add 10.71.2.0/29 via 10.71.2.50

elif [ "$HOST" == "Wilderland" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.2.50
    netmask 255.255.255.252
    gateway 10.71.2.49

auto eth1
iface eth1 inet static
    address 10.71.1.129
    netmask 255.255.255.192

auto eth2
iface eth2 inet static
    address 10.71.2.1
    netmask 255.255.255.248
EOF
    /etc/init.d/networking restart
    echo 1 > /proc/sys/net/ipv4/ip_forward

elif [ "$HOST" == "Durin" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.1.130
    netmask 255.255.255.192
    gateway 10.71.1.129
EOF
    /etc/init.d/networking restart

elif [ "$HOST" == "Khamul" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.2.2
    netmask 255.255.255.248
    gateway 10.71.2.1
EOF
    /etc/init.d/networking restart

elif [ "$HOST" == "IronHills" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.2.18
    netmask 255.255.255.248
    gateway 10.71.2.17
EOF
    /etc/init.d/networking restart
    
    # Misi 2: Blokir Akses Senin-Jumat (Port 80)
    # Asumsi waktu server UTC/sesuai. Mon-Fri DROP.
    iptables -A INPUT -p tcp --dport 80 -m time --weekdays Mon,Tue,Wed,Thu,Fri -j DROP


# --- KONFIGURASI CABANG SELATAN (RIVENDELL AREA) ---

elif [ "$HOST" == "Rivendell" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.2.46
    netmask 255.255.255.252
    gateway 10.71.2.45

auto eth1
iface eth1 inet static
    address 10.71.2.9
    netmask 255.255.255.248
EOF
    /etc/init.d/networking restart
    echo 1 > /proc/sys/net/ipv4/ip_forward

elif [ "$HOST" == "Vilya" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.2.10
    netmask 255.255.255.248
    gateway 10.71.2.9
EOF
    /etc/init.d/networking restart
    
    # Misi 2: Block Incoming Ping (ICMP Echo Request)
    iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

elif [ "$HOST" == "Narya" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.2.11
    netmask 255.255.255.248
    gateway 10.71.2.9
EOF
    /etc/init.d/networking restart
    
    # Misi 2: Allow DNS (UDP 53) hanya dari Vilya
    iptables -A INPUT -p udp --dport 53 -s 10.71.2.10 -j ACCEPT
    iptables -A INPUT -p udp --dport 53 -j DROP


# --- KONFIGURASI CABANG TIMUR (MINASTIR AREA) ---

elif [ "$HOST" == "Minastir" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.2.42
    netmask 255.255.255.252
    gateway 10.71.2.41

auto eth1
iface eth1 inet static
    address 10.71.0.1
    netmask 255.255.255.0
    # Multinetting IP Kedua
    up ip addr add 10.71.1.193/27 dev eth1

auto eth2
iface eth2 inet static
    address 10.71.2.53
    netmask 255.255.255.252
EOF
    /etc/init.d/networking restart
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Matikan Redirect
    echo 0 > /proc/sys/net/ipv4/conf/eth1/send_redirects
    echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
    
    # Routing Kanan
    ip route add 10.71.2.24/29 via 10.71.2.54
    ip route add 10.71.1.0/25 via 10.71.2.54
    ip route add 10.71.1.224/27 via 10.71.2.54

elif [ "$HOST" == "Pelargir" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.2.54
    netmask 255.255.255.252
    gateway 10.71.2.53

auto eth1
iface eth1 inet static
    address 10.71.2.57
    netmask 255.255.255.252

auto eth2
iface eth2 inet static
    address 10.71.2.25
    netmask 255.255.255.248
EOF
    /etc/init.d/networking restart
    echo 1 > /proc/sys/net/ipv4/ip_forward
    # Routing Ujung Kanan
    ip route add 10.71.1.0/25 via 10.71.2.58
    ip route add 10.71.1.224/27 via 10.71.2.58

elif [ "$HOST" == "AnduinBanks" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.2.58
    netmask 255.255.255.252
    gateway 10.71.2.57

auto eth1
iface eth1 inet static
    address 10.71.1.1
    netmask 255.255.255.128
    # Multinetting IP Kedua
    up ip addr add 10.71.1.225/27 dev eth1
EOF
    /etc/init.d/networking restart
    echo 1 > /proc/sys/net/ipv4/ip_forward
    # Matikan Redirect
    echo 0 > /proc/sys/net/ipv4/conf/eth1/send_redirects

elif [ "$HOST" == "Elendil" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.0.2
    netmask 255.255.255.0
    gateway 10.71.0.1
EOF
    /etc/init.d/networking restart

elif [ "$HOST" == "Isildur" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.1.194
    netmask 255.255.255.224
    gateway 10.71.1.193
EOF
    /etc/init.d/networking restart

elif [ "$HOST" == "Gilgalad" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.1.2
    netmask 255.255.255.128
    gateway 10.71.1.1
EOF
    /etc/init.d/networking restart

elif [ "$HOST" == "Cirdan" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.1.226
    netmask 255.255.255.224
    gateway 10.71.1.225
EOF
    /etc/init.d/networking restart

elif [ "$HOST" == "Palantir" ]; then
    cat <<EOF >> /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.71.2.26
    netmask 255.255.255.248
    gateway 10.71.2.25
EOF
    /etc/init.d/networking restart

else
    echo "Hostname tidak dikenali: $HOST"
fi

echo "Konfigurasi Selesai untuk $HOST."