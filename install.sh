#!/bin/bash
clear
echo -e "\e[36m=========================================\e[0m"
echo -e "\e[36m      GTN SERVER MONITOR - INSTALLER     \e[0m"
echo -e "\e[36m=========================================\e[0m"
echo "Memulai instalasi Agen GTN..."

# 1. Update & Install dependensi
apt-get update -y > /dev/null 2>&1
apt-get install python3 curl wget procps -y > /dev/null 2>&1

# 2. Setup direktori
mkdir -p /etc/gtn-monitor
cd /etc/gtn-monitor

# 3. Download Script Agen dari Repo Nizwarax
echo "Mengunduh file agen dari GitHub..."
wget -qO gtn_agent.py https://raw.githubusercontent.com/Nizwarax/monitor/main/gtn_agent.py

# 4. Generate Token (6 Karakter Random) & Masukkan ke script Python
RANDOM_TOKEN=$(tr -dc 'A-Z0-9' </dev/urandom | head -c 6)
sed -i "s/SECRET_TOKEN_HERE/$RANDOM_TOKEN/g" gtn_agent.py

# 5. Buat Systemd Service agar jalan 24/7 di background
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
systemctl enable gtn-monitor
systemctl restart gtn-monitor

# 7. Ambil IP Public
VPS_IP=$(curl -s -4 icanhazip.com)

clear
echo -e "\e[32m[+] INSTALASI SUKSES!\e[0m"
echo -e "Agen GTN sudah berjalan di port 7171."
echo ""
echo -e "\e[33mSilakan masukkan data ini ke Aplikasi Android Anda:\e[0m"
echo -e "IP Address   : \e[36m$VPS_IP\e[0m"
echo -e "Secret Token : \e[36m$RANDOM_TOKEN\e[0m"
echo -e "\e[36m=========================================\e[0m"
