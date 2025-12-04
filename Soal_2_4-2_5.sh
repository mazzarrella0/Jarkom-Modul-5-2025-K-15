# MORIA: KONFIGURASI PERSISTENSI DAN SEMUA ATURAN MISI 2

set -e
echo ">>> MEMULAI MISI 2: Persistensi IP dan Keamanan di MORIA <<<"

# =========================================================================
# TAHAP 1: KONFIGURASI IP PERSISTENSI (HARUS DI REBOOT)
# =========================================================================

echo ">>> TAHAP 1: Menulis konfigurasi IP Address permanen ke /etc/network/interfaces <<<"

# Pastikan file interfaces Moria dikonfigurasi secara statis untuk mencegah crash dan memastikan OSPF bekerja
cat <<'EOF' > /etc/network/interfaces
# Interface loopback
auto lo
iface lo inet loopback

# eth0: Inter-Router Link (ke Osgiliath/Rivendell)
auto eth0
iface eth0 inet static
    address 10.71.2.13
    netmask 255.255.255.248

# eth1: Client Elendil (Manusia) - Misi 2.1
auto eth1
iface eth1 inet static
    address 10.71.0.1
    netmask 255.255.255.0

# eth2: Client Gilgalad (Elf) - Misi 2.1
auto eth2
iface eth2 inet static
    address 10.71.1.1
    netmask 255.255.255.128

# eth3: Client Durin (Netral) - Misi 2.1
auto eth3
iface eth3 inet static
    address 10.71.1.129
    netmask 255.255.255.192
EOF

echo 1 > /proc/sys/net/ipv4/ip_forward

echo ">>> TAHAP 1 SELESAI. MOHON REBOOT MORIA SEKARANG. <<<"
echo "Setelah reboot, jalankan lagi script ini untuk TAHAP 2 (Firewall)."

# Perintah 'exit' digunakan untuk menghentikan eksekusi script setelah menulis file
exit 0

# =========================================================================
# TAHAP 2: IMPLEMENTASI FIREWALL (Dijalankan SETELAH reboot)
# =========================================================================

# Variabel yang Dibutuhkan untuk Misi 2.3, 2.4, 2.5
PALANTIR_IP="10.71.2.18"
IRONHILLS_IP="10.71.2.19"
VILYA_IP="10.71.2.11"
KHAMUL_IP="10.71.1.190"
ELENDIL_SUBNET="10.71.0.0/24"
CLIENT_SUBNET="10.71.0.0/16"

echo ">>> TAHAP 2: Membersihkan dan mengaplikasikan Aturan Keamanan Misi 2 <<<"

# Clear Firewall dan set default ACCEPT (untuk routing)
iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X
iptables -P INPUT ACCEPT; iptables -P FORWARD ACCEPT; iptables -P OUTPUT ACCEPT


# --- MISI 2.1: PEMBATASAN WAKTU (FORWARD CHAIN) ---

echo "--- Misi 2.1: Pembatasan Waktu (Elendil/Gilgalad) ---"
# Elf (Gilgalad: 10.71.1.0/25): Boleh 07:00 - 15:00
iptables -A FORWARD -s 10.71.1.0/25 -p tcp -m multiport --dports 80,443 -m time --timestart 07:00 --timestop 15:00 -j ACCEPT
iptables -A FORWARD -s 10.71.1.0/25 -p tcp -m multiport --dports 80,443 -j DROP
# Manusia (Elendil: 10.71.0.0/24): Boleh 17:00 - 23:00
iptables -A FORWARD -s 10.71.0.0/24 -p tcp -m multiport --dports 80,443 -m time --timestart 17:00 --timestop 23:00 -j ACCEPT
iptables -A FORWARD -s 10.71.0.0/24 -p tcp -m multiport --dports 80,443 -j DROP


# --- MISI 2.3: ANTI PORT SCAN KE PALANTIR (FORWARD CHAIN) ---

echo "--- Misi 2.3: Anti Port Scan ke Palantir ($PALANTIR_IP) ---"
# 2.3a/b: Deteksi 15 port/20 detik dari Elendil, DROP dan Log.
iptables -A FORWARD -s $ELENDIL_SUBNET -d $PALANTIR_IP -p tcp -m state --state NEW -m recent --update --seconds 20 --hitcount 15 --name PORT_SCANNER -j LOG --log-prefix "PORT_SCAN_DETECTED "
iptables -A FORWARD -s $ELENDIL_SUBNET -d $PALANTIR_IP -p tcp -m state --state NEW -m recent --update --seconds 20 --hitcount 15 --name PORT_SCANNER -j DROP
# 2.3c: Blokir total akses (termasuk ping) dari penyerang yang terdeteksi
iptables -A FORWARD -s $ELENDIL_SUBNET -d $PALANTIR_IP -m recent --rcheck --name PORT_SCANNER -j DROP


# --- MISI 2.4: BATAS KONEKSI KE IRONHILLS (FORWARD CHAIN) ---

echo "--- Misi 2.4: Batas Koneksi ke IronHills ($IRONHILLS_IP) ---"
# Batas 3 koneksi aktif per IP ke IronHills
iptables -A FORWARD -s $CLIENT_SUBNET -d $IRONHILLS_IP -p tcp --syn -m connlimit --connlimit-above 3 --connlimit-mask 32 -j DROP


# --- MISI 2.5: REDIRECT VILYA KE IRONHILLS (NAT PREROUTING CHAIN) ---

echo "--- Misi 2.5: Redirect Vilya ($VILYA_IP) -> Khamul -> IronHills ($IRONHILLS_IP) ---"
# Moria melakukan DNAT (Misi 2.5)
iptables -t nat -A PREROUTING -s $VILYA_IP -d $KHAMUL_IP -j DNAT --to-destination $IRONHILLS_IP


echo "✅ Misi 2.1, 2.3, 2.4, dan 2.5 selesai di Moria."

echo "====================================================================="
echo "VERIFIKASI MORIA (Firewall Rules):"
echo "---------------------------------------------------------------------"
echo "FORWARD CHAIN (Misi 2.1, 2.3, 2.4):"
iptables -L FORWARD -n -v
echo "---------------------------------------------------------------------"
echo "NAT PREROUTING CHAIN (Misi 2.5):"
iptables -t nat -L PREROUTING -n -v
echo "====================================================================="