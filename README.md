# Jarkom-Modul-5-2025-K-15

|No|Nama anggota|NRP|
|---|---|---|
|1. | Evan Christian Nainggolan | 5027241026|
|2. | Az Zahrra Tasya Adelia | 5027241087|

## Deskripsi Proyek

Proyek ini mencakup pembangunan infrastruktur jaringan komprehensif dalam GNS3 untuk domain K15.com dengan fokus pada keamanan, layanan DNS, dan web server. Dimulai dari konfigurasi dasar alamat IP, subnetting, dan routing dengan router pusat (Osgiliath), sistem dibangun menjadi tiga cabang utama: **Moria Area** (Barat), **Rivendell Area** (Selatan), dan **Minastir Area** (Timur).

Infrastruktur mencakup:
- **Konfigurasi Jaringan**: Pemberian alamat IP statis, subnetting, dan routing antar subnet
- **Network Address Translation (NAT)**: Implementasi SNAT untuk akses internet
- **Keamanan Firewall**: Aturan iptables untuk blocking ICMP, proteksi DNS, dan time-based access control
- **Layanan DNS**: Server DNS Master (Narya) dan Slave dengan zone transfer
- **Web Server Statis**: Nginx di Lindon untuk menyajikan konten statis dengan autoindex
- **Web Server Dinamis**: Nginx + PHP-FPM di Vingilot untuk konten dinamis dengan URL rewrite
- **Reverse Proxy**: Nginx di Sirion dengan path-based routing, Basic Auth, dan pengalihan hostname
- **Pengujian Performa**: Stress testing dengan ApacheBench
- **Autostart Services**: Memastikan semua layanan berjalan otomatis setelah reboot

## Topologi Jaringan
<img width="1188" height="835" alt="Screenshot 2025-11-30 214334" src="https://github.com/user-attachments/assets/8d9667bd-2c95-4c95-819a-90d294a20422" />
<img width="1152" height="648" alt="TreeVLSM_Modul5" src="https://github.com/user-attachments/assets/66e5499f-313e-4dd4-b400-ee3631471d35" />

Topologi terdiri dari:
- **Router Pusat**: Osgiliath (Gateway untuk 3 cabang)
- **Cabang Barat (Moria)**: Router intermediate Moria → Wilderland
  - Durin, Khamul (Client/Host)
  - IronHills (Web Server Blocker)
- **Cabang Selatan (Rivendell)**: Router intermediate Rivendell
  - Vilya (DNS Testing), Narya (DNS Server)
- **Cabang Timur (Minastir)**: Router intermediate Minastir → Pelargir → AnduinBanks
  - Elendil, Isildur, Gilgalad, Cirdan (Client/Host)
  - Palantir (DMZ/Web Server)

## Penjelasan Tiap Soal

### Soal 1-4: Konfigurasi Alamat & Jalur (Routing Dasar)

#### Tujuan
Menetapkan fondasi topologi jaringan dengan pemberian alamat IP statis unik kepada setiap node dan mendefinisikan subnet serta gateway untuk setiap segmen jaringan.

#### Kaitan dengan Skrip
File: `Soal_1_4.sh` (Demonstrasi konfigurasi DHCP untuk Moria Area)
File: `script_project.sh` (Konfigurasi lengkap untuk semua node)

#### Penjelasan Kode

**Konfigurasi Router Pusat (Osgiliath)**:
```bash
auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.71.2.45
    netmask 255.255.255.252
```

- `auto eth0`: Mengaktifkan antarmuka eth0 secara otomatis saat boot
- `iface eth0 inet dhcp`: Menerima alamat IP dari DHCP provider (NAT)
- `auto eth1, eth2, eth3`: Interface untuk ketiga cabang dengan alamat statis
- `netmask 255.255.255.252`: Subnet /30 untuk link point-to-point antar router

**Konfigurasi Klien (Contoh: Durin)**:
```bash
auto eth0
iface eth0 inet static
    address 10.71.1.130
    netmask 255.255.255.192
    gateway 10.71.1.129
```

- `address 10.71.1.130`: Alamat IP unik untuk Durin
- `gateway 10.71.1.129`: Menunjuk ke router intermediate (Wilderland)
- Ketika paket dikirim ke subnet lain, router akan meneruskannya

#### Verifikasi
```bash
# Cek konfigurasi antarmuka
ip addr show

# Cek routing table
route -n

# Ping ke node di subnet berbeda
ping 10.71.2.10  # Ping ke Vilya dari subnet berbeda
```

---

### Soal 2.1: Network Address Translation (NAT) - SNAT

#### Tujuan
Mengkonfigurasi router pusat (Osgiliath) untuk melakukan SNAT (Static Network Address Translation) dengan IP spesifik, bukan MASQUERADE, agar koneksi internal dapat akses internet.

#### Kaitan dengan Skrip
File: `Soal_2_1.sh` (Implementasi SNAT di Osgiliath)
File: `script_project.sh` (Baris 72-76: SNAT dengan IP DHCP otomatis)

#### Penjelasan Kode

**Implementasi SNAT**:
```bash
IP_WAN=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source $IP_WAN
```

- `IP_WAN=$(...)`: Mengambil alamat IP DHCP yang diterima eth0 (interface ke NAT lab)
- `iptables -t nat`: Menargetkan tabel NAT untuk translasi alamat
- `-A POSTROUTING`: Menambahkan aturan pada tahap POSTROUTING (paket keluar)
- `-o eth0`: Hanya berlaku untuk paket keluar melalui eth0 (ke internet)
- `-j SNAT --to-source $IP_WAN`: Ganti sumber paket dengan IP WAN
- `-s 10.71.0.0/16`: (Jika digunakan) Hanya untuk paket dari jaringan internal

#### Perbedaan dengan MASQUERADE
- **SNAT**: Mengarahkan ke IP spesifik (statis) - lebih efisien
- **MASQUERADE**: Menyesuaikan otomatis dengan IP interface - untuk DHCP dinamis

#### Verifikasi
```bash
# Tampilkan tabel NAT POSTROUTING
iptables -t nat -L POSTROUTING -v -n

# Ping gateway dari klien (harus berhasil)
ping 192.168.122.1

# Trace paket (source IP berubah menjadi IP WAN)
tcpdump -i eth0 -n
```

---

### Soal 2.2: Vilya Anti-Ping (Firewall ICMP Blocking)

#### Tujuan
Mengkonfigurasi firewall di node Vilya untuk memblokir semua incoming ping (ICMP Echo Request), mencegah host lain mendeteksi keberadaannya.

#### Kaitan dengan Skrip
File: `Soal_2_2.sh` (Implementasi blocking ICMP di Vilya)
File: `script_project.sh` (Baris 169-170: Implementasi di Vilya)

#### Penjelasan Kode

**Blocking ICMP Echo Request**:
```bash
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
```

- `iptables -A INPUT`: Menambahkan aturan pada chain INPUT (paket masuk)
- `-p icmp`: Menentukan protokol ICMP
- `--icmp-type echo-request`: Tipe ICMP yang diblokir (ping request)
- `-j DROP`: Buang paket tanpa memberikan response

#### Perbedaan DROP vs REJECT
- **DROP**: Paket dibuang, pengirim tidak mendapat notifikasi → timeout
- **REJECT**: Paket dibuang + kirim ICMP error reply → pengirim tahu ditolak

#### Verifikasi
```bash
# Dari Durin, coba ping Vilya
ping -c 3 -W 2 10.71.2.10

# Hasil: Timeout (tidak ada response)
# Harapan: Request timed out atau "Destination Unreachable"
```

---

### Soal 2.3: Proteksi DNS Narya (Firewall UDP Filtering)

#### Tujuan
Mengkonfigurasi firewall di node Narya untuk membatasi akses UDP port 53 (DNS) hanya dari Vilya, mencegah klien lain langsung query DNS.

#### Kaitan dengan Skrip
File: `Soal_2_3.sh` (Implementasi blocking DNS kecuali dari Vilya)
File: `script_project.sh` (Baris 177-179: Implementasi di Narya)

#### Penjelasan Kode

**Proteksi DNS dengan Source IP Filtering**:
```bash
# Allow DNS hanya dari Vilya
iptables -A INPUT -p udp --dport 53 -s 10.71.2.10 -j ACCEPT

# Block DNS dari host lain
iptables -A INPUT -p udp --dport 53 -j DROP
```

- Aturan pertama: ACCEPT jika source adalah Vilya (10.71.2.10)
- Aturan kedua: DROP untuk semua source lainnya
- Penting: Urutan aturan iptables sangat berpengaruh (first match wins)

#### Strategi Firewall
```
1. Jika source = 10.71.2.10 → ACCEPT (keluar dari chain INPUT)
2. Jika port = 53 → DROP (tidak ada ACCEPT sebelumnya)
3. Paket lain → continue (tidak ada aturan yang cocok)
```

#### Verifikasi
```bash
# Dari Vilya, DNS query harus berhasil
dig @10.71.2.11 example.com

# Dari host lain (Durin), DNS query harus ditolak
dig @10.71.2.11 example.com  # Timeout

# Tampilkan rules INPUT untuk port 53
iptables -A INPUT -p udp --dport 53 -v -n
```

---

## Struktur File Script

### `script_project.sh`
**Fungsi**: Script utama konfigurasi jaringan untuk semua node
**Fitur**:
- Deteksi hostname dan apply konfigurasi sesuai node
- Konfigurasi interface network dengan IP statis
- Activation IP Forwarding untuk router
- Manual routing untuk topologi complex
- Implementasi SNAT, ICMP blocking, DNS filtering
- Autostart untuk semua services

**Penggunaan**:
```bash
# Jalankan di setiap node (hostname harus sesuai)
bash script_project.sh
```

### `Soal_1_4.sh`
**Fungsi**: Demonstrasi konfigurasi DHCP Server
**Isi**: Display konfigurasi DHCP untuk Moria Area dengan penjelasan segmentasi subnet

### `Soal_2_1.sh`
**Fungsi**: Demonstrasi SNAT tanpa MASQUERADE
**Isi**: 
- Konfigurasi iptables untuk SNAT dengan IP spesifik
- Verifikasi koneksi gateway

### `Soal_2_2.sh`
**Fungsi**: Demonstrasi Vilya Anti-Ping
**Isi**: 
- Blocking ICMP Echo Request di Vilya
- Testing dari Durin (harus timeout)

### `Soal_2_3.sh`
**Fungsi**: Demonstrasi Proteksi DNS Narya
**Isi**: 
- Konfigurasi iptables UDP 53 filtering
- Allow hanya dari Vilya, block yang lain

---

---

## IP Address Scheme

| Node | Subnet | IP Address | Fungsi |
|------|--------|------------|--------|
| Osgiliath (eth0) | 192.168.122.0/24 | DHCP | Internet Gateway |
| Osgiliath (eth1) | 10.71.2.44/30 | 10.71.2.45 | Link ke Moria |
| Osgiliath (eth2) | 10.71.2.44/30 | 10.71.2.41 | Link ke Rivendell |
| Osgiliath (eth3) | 10.71.2.40/30 | 10.71.2.41 | Link ke Minastir |
| Moria (eth0) | 10.71.2.36/30 | 10.71.2.38 | Link ke Osgiliath |
| Moria (eth1) | 10.71.2.16/29 | 10.71.2.17 | Link ke IronHills |
| Moria (eth2) | 10.71.2.48/30 | 10.71.2.49 | Link ke Wilderland |
| Wilderland (eth1) | 10.71.1.128/26 | 10.71.1.129 | Link ke Durin, Khamul |
| Durin | 10.71.1.128/26 | 10.71.1.130 | Client ICMP Blocker Tester |
| Khamul | 10.71.2.0/29 | 10.71.2.2 | Client - Moria Area |
| IronHills | 10.71.2.16/29 | 10.71.2.18 | Web Blocker Mon-Fri |
| Rivendell (eth0) | 10.71.2.44/30 | 10.71.2.46 | Link ke Osgiliath |
| Rivendell (eth1) | 10.71.2.8/29 | 10.71.2.9 | Link ke Vilya, Narya |
| Vilya | 10.71.2.8/29 | 10.71.2.10 | DNS Tester (Ping Blocked) |
| Narya | 10.71.2.8/29 | 10.71.2.11 | DNS Server (UDP 53 Protected) |
| Minastir (eth1) | 10.71.0.0/24 | 10.71.0.1 | Link ke Elendil |
| Minastir (eth1-alias) | 10.71.1.192/27 | 10.71.1.193 | Multinetting ke Isildur |
| Elendil | 10.71.0.0/24 | 10.71.0.2 | DHCP Relay Tester |
| Isildur | 10.71.1.192/27 | 10.71.1.194 | DHCP Relay Tester |
| Pelargir (eth0) | 10.71.2.52/30 | 10.71.2.54 | Link ke Minastir |
| Pelargir (eth1) | 10.71.2.56/30 | 10.71.2.57 | Link ke AnduinBanks |
| Pelargir (eth2) | 10.71.2.24/29 | 10.71.2.25 | DMZ Network |
| AnduinBanks (eth1) | 10.71.1.0/25 | 10.71.1.1 | Link ke Gilgalad |
| AnduinBanks (eth1-alias) | 10.71.1.224/27 | 10.71.1.225 | Multinetting ke Cirdan |
| Gilgalad | 10.71.1.0/25 | 10.71.1.2 | Client/Tester |
| Cirdan | 10.71.1.224/27 | 10.71.1.226 | Client/Tester |
| Palantir | 10.71.2.24/29 | 10.71.2.26 | DMZ/Testing Node |

---

## Implementasi Keamanan Firewall

### Ringkasan Aturan iptables yang Diterapkan

| Node | Chain | Protokol | Port | Aksi | Tujuan |
|------|-------|----------|------|------|--------|
| Osgiliath | POSTROUTING | - | - | SNAT | Akses Internet |
| Vilya | INPUT | ICMP | - | DROP | Block Ping |
| Narya | INPUT | UDP | 53 | ACCEPT (if source=10.71.2.10) | Allow DNS from Vilya only |
| Narya | INPUT | UDP | 53 | DROP | Block DNS from others |
| IronHills | INPUT | TCP | 80 | DROP (Mon-Fri) | Time-based Web Blocker |

### Testing Firewall Rules

```bash
# Test SNAT - dari klien, check apakah internet accessible
ping 8.8.8.8

# Test Vilya Anti-Ping - dari Durin
ping 10.71.2.10  # Should timeout

# Test Narya DNS Protection - dari Durin
dig @10.71.2.11 example.com  # Should timeout

# Test Narya DNS Protection - dari Vilya
dig @10.71.2.11 example.com  # Should resolve

# Test IronHills HTTP Blocker - akses hari kerja
curl http://10.71.2.18  # Should timeout on Mon-Fri
```

## Testing & Verification

### Test Koneksi Dasar
```bash
# Dari Earendil ping Vilya (beda subnet)
ping 10.71.2.10
# Output: timeout (Vilya antiping)

# Dari Vilya ping ke Narya (sama subnet)
ping 10.71.2.11
# Output: success

# DNS query dari Vilya
dig @10.71.2.11 K15.com
# Output: berhasil resolve

# DNS query dari Durin
dig @10.71.2.11 K15.com
# Output: timeout (DNS protection)
```

### Test Internet Connectivity
```bash
# Dari any klien
ping 8.8.8.8
# Output: success (via SNAT)

traceroute 8.8.8.8
# Output: path melalui Osgiliath (SNAT)
```

### Test Firewall Blocking
```bash
# Cek rules di setiap node
iptables -L -v -n
iptables -t nat -L -v -n

# Real-time monitoring
tcpdump -i any -n icmp
tcpdump -i any -n udp port 53
```

---

## Troubleshooting

### Network Interface Tidak Terupdate
```bash
# Force restart networking
systemctl restart networking

# Verify konfigurasi
ip addr show
ip route show
```

### SNAT Tidak Jalan
```bash
# Cek IP DHCP eth0
ip addr show eth0

# Cek iptables NAT rules
iptables -t nat -L POSTROUTING -v -n

# Enable IP Forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Persist IP Forwarding (edit /etc/sysctl.conf)
net.ipv4.ip_forward=1
sysctl -p
```

### Routing tidak jalan
```bash
# Cek route table
route -n

# Add route manual (jika belum otomatis)
ip route add 10.71.x.x/24 via 10.71.x.1

# Enable forwarding di router
echo 1 > /proc/sys/net/ipv4/ip_forward
```

### iptables Rules Tidak Persist
```bash
# Install iptables-persistent
apt-get install -y iptables-persistent

# Save rules
iptables-save > /etc/iptables/rules.v4

# Load saat boot
systemctl enable iptables
```

---

## Kesimpulan

Proyek Jarkom Modul 5 K-15 ini memberikan pengalaman praktik lengkap dalam membangun infrastruktur jaringan modern yang mencakup:

1. **Routing & Networking**: IP addressing, subnetting, routing, NAT
2. **Keamanan**: Firewall rules, port filtering, access control
3. **Services**: DNS, Web Server, Reverse Proxy, Authentication
4. **Monitoring & Testing**: Troubleshooting, performance testing, verification

Semua komponen terintegrasi dalam topologi yang realistis dan kompleks, memberikan fondasi kuat untuk memahami network infrastructure modern.
