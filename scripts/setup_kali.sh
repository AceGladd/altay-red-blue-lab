#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y sshpass nfs-common curl dnsutils nmap

# Red Team betiklerini Kali'nin ana dizinine kopyala
mkdir -p /home/vagrant/red_team
cp /vagrant/red_team/*.sh /home/vagrant/red_team/ 2>/dev/null || true

# Eger red_team dizini bossa nfs_mount shortcut'i ekle
cat <<'EOF' > /home/vagrant/red_team/1_nfs_exploit_shortcut.sh
#!/bin/bash
echo "[*] NFS Paylasimi Mount Ediliyor..."
sudo mount -t nfs 192.168.56.10:/home /tmp/nfs_mount
echo "[*] Mount basarili! Dosyalar listeleniyor:"
ls -la /tmp/nfs_mount
EOF

# Çalıştırma yetkisi ver
chmod +x /home/vagrant/red_team/*.sh

# Sahipliği vagrant kullanıcısına devret
chown -R vagrant:vagrant /home/vagrant/red_team

# Kali bashrc'ye kolaylık aliası ekle
grep -q "cd ~/red_team" /home/vagrant/.bashrc || \
  echo -e '\n# Altay Lab - Red Team\nalias lab="cd ~/red_team && ls -la"' >> /home/vagrant/.bashrc

echo "[*] Kali kurulumu tamamlandi. Red Team araclari ~/red_team/ dizininde."
