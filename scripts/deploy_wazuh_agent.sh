#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y curl apt-transport-https gnupg lsb-release

# Wazuh GPG anahtarı ve repo ekleme
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | \
  gpg --no-default-keyring \
      --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg \
      --import
chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
  > /etc/apt/sources.list.d/wazuh.list
apt-get update

# Agent kurulumu ve blue-server'a otomatik bağlantı
WAZUH_MANAGER="192.168.56.20" \
WAZUH_AGENT_NAME="red-target" \
  apt-get install -y wazuh-agent=4.7.2-1
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent
echo "[*] Wazuh Agent kuruldu ve 192.168.56.20 adresine baglanildi."

# ============================================
# Kisi 3: auditd + FIM kurulumu
# ============================================
apt-get install -y auditd audispd-plugins

cat > /etc/audit/rules.d/altay.rules << 'AUDITEOF'
-w /usr/local/bin/.hidden_cp -p x -k suid_abuse
-a always,exit -F arch=b64 -S execve -F path=/usr/bin/find -k sudo_find
-a always,exit -F arch=b32 -S execve -F path=/usr/bin/find -k sudo_find
AUDITEOF

systemctl enable auditd
systemctl restart auditd
augenrules --load

sed -i 's|<syscheck>|<syscheck>\n    <directories check_all="yes" realtime="yes" report_changes="yes">/home/developer/.ssh</directories>|' /var/ossec/etc/ossec.conf

systemctl restart wazuh-agent
echo "[*] Kisi 3: auditd ve FIM kurulumu tamamlandi."