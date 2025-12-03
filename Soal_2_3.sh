#!/bin/bash
# Script Demonstrasi Misi 2.3: Proteksi DNS Narya

# di narya
iptables -A INPUT -s 10.71.2.10 -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --dport 53 -j DROP