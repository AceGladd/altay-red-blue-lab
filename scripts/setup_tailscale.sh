#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

if [ -z "$TAILSCALE_AUTH_KEY" ]; then
  echo "[-] TAILSCALE_AUTH_KEY ortam degiskeni bulunamadi. Lutfen 'export TAILSCALE_AUTH_KEY=tskey-auth-...' komutunu calistirip 'vagrant up' yapin."
  echo "[-] Tailscale kurulumu ATLANDI."
  exit 0
fi

if ! command -v tailscale >/dev/null 2>&1; then
  echo "[*] Tailscale indiriliyor ve kuruluyor..."
  curl -fsSL https://tailscale.com/install.sh | sh
fi

echo "[*] Subnet Router icin IP Forwarding aktif ediliyor..."
echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding = 1" | tee -a /etc/sysctl.conf
sysctl -p

echo "[*] Iptables Masquerade (SNAT) kurali ekleniyor..."
# Vagrant'ta eth1 genellikle private_network arayüzüdür.
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

echo "[*] Tailscale Subnet Router olarak baglanti saglaniyor (192.168.56.0/24)..."
tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --advertise-routes=192.168.56.0/24 --accept-dns=false --hostname=blue-server

echo "[+] Tailscale Subnet Router kurulumu TAMAMLANDI."
echo "[!] DİKKAT: Tailscale Admin Paneline gidip 'blue-server' makinesinin 'Subnet routes' ayarlarindan 192.168.56.0/24 agini ONAYLAMAYI UNUTMAYIN!"
