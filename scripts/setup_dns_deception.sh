#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y bind9 bind9utils bind9-doc

cat <<EOF > /etc/bind/named.conf.local
zone "altay.local" {
    type master;
    file "/etc/bind/db.altay.local";
    allow-transfer { any; };
};
EOF

cat <<EOF > /etc/bind/db.altay.local
$TTL    604800
@       IN      SOA     blue-server.altay.local. admin.altay.local. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      blue-server.altay.local.
blue-server IN      A       192.168.56.20
red-target  IN      A       192.168.56.10
nfs         IN      A       192.168.56.10
pam         IN      A       192.168.56.10
docker      IN      A       192.168.56.10
caps        IN      A       192.168.56.10
systemd     IN      A       192.168.56.10
EOF

systemctl restart named
systemctl enable named