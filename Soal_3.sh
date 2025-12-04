# Moria Console

# 1. Definisikan IP host Khamul (misalnya host pertama yang valid)
KHAMUL_HOST_IP="10.71.1.194"

echo ">>> Menerapkan Misi 3: Isolasi Sang Nazgûl ($KHAMUL_HOST_IP) <<<"

# 2. BLOKIR TRAFFIC KELUAR DARI KHAMUL (FORWARD CHAIN)
iptables -A FORWARD -s $KHAMUL_HOST_IP -j DROP

# 3. BLOKIR TRAFFIC MASUK KE KHAMUL (FORWARD CHAIN)
iptables -A FORWARD -d $KHAMUL_HOST_IP -j DROP

# 4. BLOKIR AKSES KE MORIA DARI KHAMUL (INPUT CHAIN)
iptables -A INPUT -s $KHAMUL_HOST_IP -j DROP

# 5. BLOKIR AKSES DARI MORIA KE KHAMUL (OUTPUT CHAIN)
iptables -A OUTPUT -d $KHAMUL_HOST_IP -j DROP

echo "✅ Misi 3 (Isolasi Khamul) selesai di Moria."
iptables -L FORWARD -n -v