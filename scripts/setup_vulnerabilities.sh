#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt-get update

# --- INITIAL ACCESS ---

# Vector 1 & 2: NFS no_root_squash and SSH Key Theft
apt-get install -y nfs-kernel-server python3 python3-flask python3-pip

# Create the developer user
id developer &>/dev/null || useradd -m -s /bin/bash developer

# Generate SSH keys for developer (No passphrase)
mkdir -p /home/developer/.ssh
ssh-keygen -t rsa -b 2048 -f /home/developer/.ssh/id_rsa -N ""

# Set exact permissions
chmod 700 /home/developer/.ssh
chmod 600 /home/developer/.ssh/id_rsa
chmod 644 /home/developer/.ssh/id_rsa.pub

# Ensure public key is authorized so the private key works
cat /home/developer/.ssh/id_rsa.pub > /home/developer/.ssh/authorized_keys
chmod 600 /home/developer/.ssh/authorized_keys

# Set exact ownership
chown -R developer:developer /home/developer/.ssh

# Configure NFS to share /home insecurely
echo '/home *(rw,sync,no_root_squash,no_subtree_check,insecure)' > /etc/exports
exportfs -arv
systemctl restart nfs-kernel-server
systemctl enable nfs-kernel-server

# Hem eski hem yeni sshd_config formatlarını destekle
SSHD_CONF="/etc/ssh/sshd_config"
grep -q "^PasswordAuthentication" "$SSHD_CONF" \
  && sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONF" \
  || echo "PasswordAuthentication yes" >> "$SSHD_CONF"

# Ubuntu 22.04'te servis adı 'ssh' veya 'sshd' olabilir
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null

# --- INITIAL ACCESS 2 (Web Command Injection) ---

mkdir -p /opt/vuln_webapp
cat << 'EOF' > /opt/vuln_webapp/app.py
from flask import Flask, request, render_template_string
import subprocess

app = Flask(__name__)

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head><title>Network Diagnostic Tool</title></head>
<body>
    <h2>Altay Network Diagnostic Tool</h2>
    <p>Enter an IP address to ping:</p>
    <form method="POST">
        <input type="text" name="ip" placeholder="127.0.0.1">
        <input type="submit" value="Ping">
    </form>
    <pre>{{ result }}</pre>
</body>
</html>
"""

@app.route('/', methods=['GET', 'POST'])
def index():
    result = ""
    if request.method == 'POST':
        ip = request.form.get('ip', '')
        # VULNERABILITY: No sanitization of user input before passing to shell
        cmd = f"ping -c 3 {ip}"
        try:
            # Use shell=True which allows command injection via ; or & or |
            output = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT, timeout=5)
            result = output.decode('utf-8')
        except subprocess.CalledProcessError as e:
            result = e.output.decode('utf-8')
        except Exception as e:
            result = str(e)
            
    return render_template_string(HTML_TEMPLATE, result=result)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# Create a systemd service to keep the vulnerable web app running
cat << 'EOF' > /etc/systemd/system/vuln_webapp.service
[Unit]
Description=Vulnerable Network Diagnostic Tool (Altay Lab)
After=network.target

[Service]
User=developer
WorkingDirectory=/opt/vuln_webapp
ExecStart=/usr/bin/python3 app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start vuln_webapp
systemctl enable vuln_webapp


# --- PRIVILEGE ESCALATION ---

# Vector 3 (SUID - gizli cp kopyası)
cp /bin/cp /usr/local/bin/.hidden_cp
chmod u+s /usr/local/bin/.hidden_cp

# Auditd ile SUID tetiklendiğinde Wazuh'a log gönderilmesini sağla
apt-get install -y auditd audispd-plugins
grep -q "hidden_cp" /etc/audit/rules.d/audit.rules || \
  echo "-w /usr/local/bin/.hidden_cp -p x -k suid_hidden_cp" >> /etc/audit/rules.d/audit.rules
systemctl restart auditd
systemctl enable auditd

# Vector 4 (Sudoers Misconfig - find NOPASSWD)
echo "developer ALL=(ALL) NOPASSWD: /usr/bin/find" > /etc/sudoers.d/developer
chmod 440 /etc/sudoers.d/developer

# --- EXFILTRATION ---

# Vector 5 (Data - sahte shadow dosyası)
echo 'fakeuser:$6$rounds=5000$fakemacro$fakepasswordhash:19200:0:99999:7:::' > /etc/shadow_backup.txt
chmod 644 /etc/shadow_backup.txt

echo "[*] Tüm zafiyet vektorleri (NFS, SSH Key, Web RCE, SUID, Sudoers, Exfil) basariyla kuruldu."
