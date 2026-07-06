#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y bind9 bind9utils bind9-doc

# Bind9'un tüm arayüzleri dinlemesini ve AXFR'a açık olmasını sağla
cat > /etc/bind/named.conf.options <<'OPTEOF'
options {
    directory "/var/cache/bind";
    listen-on { any; };
    listen-on-v6 { any; };
    allow-query { any; };
    recursion no;
    forwarders {};
};
OPTEOF

# altay.local zone tanımı - AXFR zafiyeti: allow-transfer { any; }
cat > /etc/bind/named.conf.local <<'LOCALEOF'
zone "altay.local" {
    type master;
    file "/etc/bind/db.altay.local";
    allow-transfer { any; };
};
LOCALEOF

# Zone dosyası - sahte (deception) kayıtlar, hepsi red-target'a işaret ediyor
cat > /etc/bind/db.altay.local <<'ZONEEOF'
$TTL    604800
@       IN      SOA     blue-server.altay.local. admin.altay.local. (
                              3         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@           IN      NS      blue-server.altay.local.
blue-server IN      A       192.168.56.20
red-target  IN      A       192.168.56.10
nfs         IN      A       192.168.56.10
ssh         IN      A       192.168.56.10
secret      IN      A       192.168.56.10
devops      IN      A       192.168.56.10
backup      IN      A       192.168.56.10
ZONEEOF

# Ubuntu 22.04'te servis adı 'named' olarak çalışır, 'bind9' değil
named-checkconf
named-checkzone altay.local /etc/bind/db.altay.local
systemctl restart named
systemctl enable named

echo "[*] DNS Deception (AXFR) kurulumu tamamlandi."