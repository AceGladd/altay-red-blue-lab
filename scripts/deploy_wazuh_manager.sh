#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y curl

# Wazuh 4.7 All-in-One kurulumu
curl -sOL https://packages.wazuh.com/4.7/wazuh-install.sh
bash ./wazuh-install.sh -a --ignore-check

# Konfigürasyon dosyasında queryall ve syslog koleksiyonunu aktif et
# (Bind9 syslog kayıtlarını Wazuh'un yakalaması için)
if [ -f /var/ossec/etc/ossec.conf ]; then
  # Bind9 query logları için syslog'u izle
  sed -i 's|<log_format>syslog</log_format>|<log_format>syslog</log_format>|' /var/ossec/etc/ossec.conf
fi

# Wazuh custom rules dosyasını yerleştir
if [ -f /vagrant/blue_team/wazuh_custom_rules.xml ]; then
  cp /vagrant/blue_team/wazuh_custom_rules.xml /var/ossec/etc/rules/local_rules.xml
  echo "[*] Custom Wazuh rules kopyalandi."
fi

# Wazuh yeniden başlat
systemctl restart wazuh-manager

# Şifreleri paylaşılan Vagrant dizinine aktar (Windows'tan kolay erişim)
echo "[*] Wazuh parolalari /vagrant/wazuh_credentials.txt dosyasina yaziliyor..."
sleep 5
if [ -f wazuh-install-files.tar ]; then
  tar -O -xf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt > /vagrant/wazuh_credentials.txt
  echo "[*] HAZIR: Wazuh Dashboard => https://192.168.56.20" >> /vagrant/wazuh_credentials.txt
else
  echo "[!] wazuh-install-files.tar bulunamadi, sifre cikarimi basarisiz." >> /vagrant/wazuh_credentials.txt
fi

echo "[*] Wazuh Manager kurulumu tamamlandi."