#!/bin/bash
# Script Pengujian Misi 2.2: Vilya Anti-Ping

iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

TARGET="10.71.2.10" # IP Vilya

# SKENARIO PENGUJIAN:
# Asal: Durin (Client)
# Tujuan: Vilya ($TARGET)
# Harapan: Request Timed Out (Diblokir)

ping -c 3 -W 2 $TARGET