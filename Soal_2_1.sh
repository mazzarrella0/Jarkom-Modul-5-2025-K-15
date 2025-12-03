#!/bin/bash
# Script Demonstrasi Misi 2.1: Routing SNAT (No Masquerade)

iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source 192.168.122.223

echo "=== [1] TABEL NAT (POSTROUTING) ==="
# Menampilkan hanya tabel NAT bagian POSTROUTING
iptables -t nat -L POSTROUTING -v -n

# Analisis: 
# Terlihat aturan SNAT mengarah ke IP eth0 secara spesifik.
# Ini memenuhi syarat: TIDAK MENGGUNAKAN MASQUERADE.

echo ""
echo "=== [2] CEK KONEKSI GATEWAY ==="
GATEWAY=$(ip route show | grep default | awk '{print $3}')
echo "Pinging Gateway ($GATEWAY)..."
ping -c 3 $GATEWAY

# Kesimpulan: 
# Koneksi ke Gateway LAN berhasil. (Internet luar putus dari Provider).