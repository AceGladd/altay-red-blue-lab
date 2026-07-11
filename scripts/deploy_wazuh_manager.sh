#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "[*] Wazuh Docker kurulumu basliyor..."
# 1. Gerekli paketler
apt-get update
apt-get install -y docker.io docker-compose git curl wget bind9
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

# ============================================
# Kisi 3: BIND9 query logging aktif etme
# ============================================
mkdir -p /var/log/named
chown bind:bind /var/log/named
cat >> /etc/bind/named.conf.options << 'BINDEOF'

logging {
    channel query_log {
        file "/var/log/named/query.log" versions 3 size 5m;
        severity info;
        print-time yes;
        print-severity yes;
        print-category yes;
    };
    category queries { query_log; };
    category xfer-out { query_log; };
};
BINDEOF
systemctl restart bind9
echo "[*] Kisi 3: BIND9 query logging aktif edildi."

# ============================================
# Kisi 3: BIND9 logunu Wazuh manager config'ine ekle
# ============================================
sed -i 's|</ossec_config>$|  <localfile>\n    <log_format>syslog</log_format>\n    <location>/var/log/named/query.log</location>\n  </localfile>\n</ossec_config>|' /opt/wazuh-docker/single-node/config/wazuh_cluster/wazuh_manager.conf

# Kisi 3: BIND9 log dosyasini container'a mount et
sed -i 's|./config/wazuh_cluster/wazuh_manager.conf:/wazuh-config-mount/etc/ossec.conf|./config/wazuh_cluster/wazuh_manager.conf:/wazuh-config-mount/etc/ossec.conf\n      - /var/log/named:/var/log/named:ro|' /opt/wazuh-docker/single-node/docker-compose.yml

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

    # Kisi 3: BIND9 decoder'ini yukle
    if [ -f /vagrant/blue_team/local_decoder.xml ]; then
      docker cp /vagrant/blue_team/local_decoder.xml $MANAGER_CONTAINER:/var/ossec/etc/decoders/local_decoder.xml
      docker exec $MANAGER_CONTAINER chown wazuh:wazuh /var/ossec/etc/decoders/local_decoder.xml
      echo "[*] Kisi 3: BIND9 decoder kopyalandi."
    fi

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