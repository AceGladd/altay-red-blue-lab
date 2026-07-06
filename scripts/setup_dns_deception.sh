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
                              4         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@           IN      NS      blue-server.altay.local.
@           IN      MX  10  mail.altay.local.

; Infrastructure & Core
blue-server IN      A       192.168.56.20
red-target  IN      A       192.168.56.10
dc01        IN      A       192.168.56.11
dc02        IN      A       192.168.56.12
vcenter     IN      A       192.168.56.15
vpn         IN      A       192.168.56.50
mail        IN      A       192.168.56.60

; DevOps & CI/CD
devops      IN      A       192.168.56.10
gitlab      IN      A       192.168.56.70
jenkins     IN      A       192.168.56.71
nexus       IN      A       192.168.56.72
sonar       IN      A       192.168.56.73

; Monitoring & Security
wazuh       IN      CNAME   blue-server.altay.local.
grafana     IN      A       192.168.56.80
prometheus  IN      A       192.168.56.81
splunk      IN      A       192.168.56.82

; Corporate Services
intranet    IN      A       192.168.56.90
jira        IN      A       192.168.56.91
confluence  IN      A       192.168.56.92
erp         IN      A       192.168.56.93
crm         IN      A       192.168.56.94
hr-portal   IN      A       192.168.56.95

; Deception & Vulnerable Targets (Honeypots pointing to red-target)
nfs         IN      A       192.168.56.10
ssh         IN      A       192.168.56.10
secret      IN      A       192.168.56.10
backup      IN      A       192.168.56.10
legacy-db   IN      A       192.168.56.10
test-api    IN      A       192.168.56.10
staging     IN      A       192.168.56.10

; TXT Records
@           IN      TXT     "v=spf1 ip4:192.168.56.0/24 -all"
_dmarc      IN      TXT     "v=DMARC1; p=reject; rua=mailto:admin@altay.local;"
flag        IN      TXT     "ALTAY{W3LC0M3_T0_TH3_C0RP0R4T3_N3TW0RK}"
ZONEEOF

# Ubuntu 22.04'te servis adı 'named' olarak çalışır, 'bind9' değil
named-checkconf
named-checkzone altay.local /etc/bind/db.altay.local
systemctl restart named
systemctl enable named

echo "[*] DNS Deception (AXFR) kurulumu tamamlandi."