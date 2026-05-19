#!/bin/bash
clear
echo -e "\e[36m=========================================\e[0m"
echo -e "\e[36m    GTN SERVER MONITOR PRO - INSTALLER   \e[0m"
echo -e "\e[36m=========================================\e[0m"
echo "Memulai instalasi Agen GTN..."

# 1. Update & Install dependensi (Termasuk alat firewall)
apt-get update -y > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get install -y python3 curl wget procps iptables iptables-persistent ufw > /dev/null 2>&1

# 2. Setup direktori
mkdir -p /etc/gtn-monitor
cd /etc/gtn-monitor

# 3. Download Script Agen dari Repo Nizwarax
echo "Mengunduh mesin inti dari GitHub..."
wget -qO gtn_agent.py https://raw.githubusercontent.com/Nizwarax/monitor/main/gtn_agent.py

# 4. Generate Token (6 Karakter Random) & Masukkan ke script Python
RANDOM_TOKEN=$(tr -dc 'A-Z0-9' </dev/urandom | head -c 6)
sed -i "s/SECRET_TOKEN_HERE/$RANDOM_TOKEN/g" gtn_agent.py

# 5. Buat Systemd Service agar jalan 24/7 di background walau VPS direboot
cat > /etc/systemd/system/gtn-monitor.service << EOF
[Unit]
Description=GTN Server Monitor Backend
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /etc/gtn-monitor/gtn_agent.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# 6. Reload & Hidupkan Service
systemctl daemon-reload
systemctl enable gtn-monitor > /dev/null 2>&1
systemctl restart gtn-monitor

# ==========================================
# 🔓 BUKA GEMBOK FIREWALL SECARA BRUTAL (ANTI DIBLOKIR DO/ALIBABA)
# ==========================================
echo "Membuka jalur rahasia port 7171..."

# Buka via Iptables (Universal)
iptables -I INPUT -p tcp --dport 7171 -j ACCEPT
netfilter-persistent save > /dev/null 2>&1

# Buka via UFW (Ubuntu/Debian)
if command -v ufw > /dev/null 2>&1; then
    ufw allow 7171/tcp > /dev/null 2>&1
fi
# ==========================================

# 7. Ambil IP Public
VPS_IP=$(curl -s -4 icanhazip.com)

clear
echo -e "\e[32m[+] INSTALASI SUKSES 100%!\e[0m"
echo -e "Agen GTN sudah berjalan di latar belakang (Port 7171)."
echo ""
echo -e "\e[33mSilakan masukkan data ini ke Aplikasi Android GTN Anda:\e[0m"
echo -e "IP Address   : \e[36m$VPS_IP\e[0m"
echo -e "Secret Token : \e[36m$RANDOM_TOKEN\e[0m"
echo -e "\e[36m=========================================\e[0m"
