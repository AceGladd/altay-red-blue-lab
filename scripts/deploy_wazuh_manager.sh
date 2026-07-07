#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

echo "[*] Wazuh Docker kurulumu basliyor..."

# 1. Gerekli paketler
apt-get update
apt-get install -y docker.io docker-compose git curl wget

systemctl enable docker
systemctl start docker

# 2. Elasticsearch / Indexer icin kritik Kernel ayari (Zorunlu)
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# 3. Wazuh Docker reposunu indir (v4.7.2 - Ajanlarla ayni versiyon)
if [ ! -d "/opt/wazuh-docker" ]; then
  git clone https://github.com/wazuh/wazuh-docker.git -b v4.7.2 /opt/wazuh-docker
fi

cd /opt/wazuh-docker/single-node

# 4. Sertifikalari Uret
echo "[*] Indexer sertifikalari uretiliyor..."
docker-compose -f generate-indexer-certs.yml run --rm generator

# 5. Wazuh'u Baslat
echo "[*] Wazuh Docker agaci baslatiliyor (Bu islem biraz surebilir)..."
docker-compose up -d

# 6. Manager'in tam acilmasi icin bekle
echo "[*] Manager container'inin hazir olmasi bekleniyor (30 sn)..."
sleep 30

# 7. Custom kurallari iceri aktar
if [ -f /vagrant/blue_team/wazuh_custom_rules.xml ]; then
  MANAGER_CONTAINER=$(docker ps -qf "name=wazuh.manager")
  if [ -n "$MANAGER_CONTAINER" ]; then
    docker cp /vagrant/blue_team/wazuh_custom_rules.xml $MANAGER_CONTAINER:/var/ossec/etc/rules/local_rules.xml
    docker exec $MANAGER_CONTAINER chown wazuh:wazuh /var/ossec/etc/rules/local_rules.xml
    docker exec $MANAGER_CONTAINER /var/ossec/bin/wazuh-control restart
    echo "[*] Custom Wazuh rules kopyalandi ve Manager yeniden baslatildi."
  fi
fi

# 8. Kimlik Bilgilerini Yazdir
echo "[*] Wazuh parolalari /vagrant/wazuh_credentials.txt dosyasina yaziliyor..."
echo "==========================================" > /vagrant/wazuh_credentials.txt
echo "WAZUH DASHBOARD ERIŞIMI (DOCKER)" >> /vagrant/wazuh_credentials.txt
echo "URL: https://192.168.56.20" >> /vagrant/wazuh_credentials.txt
echo "Kullanici Adi: admin" >> /vagrant/wazuh_credentials.txt
echo "Sifre: SecretPassword" >> /vagrant/wazuh_credentials.txt
echo "==========================================" >> /vagrant/wazuh_credentials.txt

echo "[*] Wazuh Docker kurulumu tamamlandi."