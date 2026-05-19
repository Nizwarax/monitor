import http.server
import socketserver
import json
import os
import subprocess
from urllib.parse import urlparse, parse_qs

PORT = 7171
# Token ini akan diisi otomatis oleh install.sh nanti
TOKEN = "SECRET_TOKEN_HERE" 

class GTNHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass # Matikan log agar tidak nyepam di memori VPS

    def check_auth(self):
        if self.headers.get('X-GTN-Token') != TOKEN:
            self.send_response(403)
            self.end_headers()
            self.wfile.write(b'{"error": "Akses Ditolak!"}')
            return False
        return True

    def do_GET(self):
        if not self.check_auth(): return
        
        parsed_path = urlparse(self.path)
        
        # 📊 RUTE 1: MENGIRIM STATUS VPS KE HP
        if parsed_path.path == '/status':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            uptime = subprocess.getoutput("uptime -p").replace("up ", "")
            
            try:
                # Ambil idle CPU, lalu hitung usage
                cpu_idle = subprocess.getoutput("top -bn1 | grep 'Cpu(s)' | awk '{print $8}'")
                cpu_usage = int(100.0 - float(cpu_idle.replace(',','.')))
            except:
                cpu_usage = 0
                
            try:
                free_m = subprocess.getoutput("free -m").splitlines()[1].split()
                ram_total = int(free_m[1])
                ram_used = int(free_m[2])
                ram_percent = int((ram_used / ram_total) * 100) if ram_total > 0 else 0
            except:
                ram_total = 0
                ram_used = 0
                ram_percent = 0
            
            data = {
                "uptime": uptime,
                "cpu_usage": cpu_usage,
                "ram_total": ram_total,
                "ram_used": ram_used,
                "ram_percent": ram_percent
            }
            self.wfile.write(json.dumps(data).encode())
            
        # ⚡ RUTE 2: MENERIMA PERINTAH BRUTAL DARI HP
        elif parsed_path.path == '/action':
            qs = parse_qs(parsed_path.query)
            cmd = qs.get('cmd', [''])[0]
            
            if cmd == 'flush_ram':
                os.system('sync; echo 3 > /proc/sys/vm/drop_caches')
                msg = "RAM Berhasil di-Flush ⚡"
                
            elif cmd == 'restart_tunnel':
                os.system('systemctl restart ssh ws dropbear stunnel4 xray > /dev/null 2>&1') 
                msg = "Tunnel Service Direstart 🔄"
                
            elif cmd == 'clear_logs':
                os.system('journalctl --vacuum-time=1d > /dev/null 2>&1')
                os.system('rm -rf /var/log/*.log > /dev/null 2>&1')
                msg = "Log Sistem & Sampah Berhasil Dihapus! 🗑️"
                
            elif cmd == 'reboot_vps':
                # Delay 2 detik agar aplikasi Android menerima respons sukses dulu sebelum VPS mati
                os.system('sleep 2 && reboot &')
                msg = "VPS Sedang Di-Reboot! Tunggu 1 menit. ☠️"
                
            else:
                msg = "Perintah tidak dikenal"
                
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "sukses", "pesan": msg}).encode())
            
        else:
            self.send_response(404)
            self.end_headers()

# Jalankan server nonstop
with socketserver.TCPServer(("", PORT), GTNHandler) as httpd:
    httpd.serve_forever()
