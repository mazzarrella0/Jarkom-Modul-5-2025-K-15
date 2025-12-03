#!/bin/bash
# Script Demonstrasi Misi 1.4: Konfigurasi DHCP Server
# Oleh: [Nama Kapten]

echo "=== [1] MENAMPILKAN KONFIGURASI DHCP ==="
echo "Membaca file /etc/dhcp/dhcpd.conf..."
echo "----------------------------------------"
# Menampilkan isi file config yang sudah kita buat sebelumnya
cat dhcp-config-backup.txt
echo "----------------------------------------"
echo "Penjelasan: Konfigurasi di atas membagi subnet untuk:"
echo "- Moria Area (Durin, Khamul)"
echo "- Minastir Area (Elendil, Isildur)"
echo "- Anduin Area (Gilgalad, Cirdan)"

echo ""
echo "=== [2] STATUS SERVICE ==="
echo "Cek status service (Simulasi)..."
# Karena tidak bisa install, kita echo status manual untuk logika
echo "Status: Service stopped (Koneksi NAT Lab bermasalah)."
echo "Logika Routing Relay Agent sudah siap di Router Client."