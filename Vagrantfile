Vagrant.configure("2") do |config|
  config.vm.define "blue-server" do |blue|
    blue.vm.box = "bento/ubuntu-22.04"
    blue.vm.hostname = "blue-server"
    blue.vm.network "private_network", ip: "192.168.56.20"
    blue.vm.network "forwarded_port", guest: 443, host: 8443
    blue.vm.provider "virtualbox" do |vb|
      vb.memory = "6144"
      vb.cpus = 2
    end
    blue.vm.provider "vmware_desktop" do |v|
      v.vmx["memsize"] = "6144"
      v.vmx["numvcpus"] = "2"
    end
    blue.vm.provision "shell", path: "scripts/setup_dns_deception.sh"
    blue.vm.provision "shell", path: "scripts/deploy_wazuh_manager.sh"
    blue.vm.provision "shell", env: {"TAILSCALE_AUTH_KEY" => ENV["TAILSCALE_AUTH_KEY"]}, path: "scripts/setup_tailscale.sh"
  end
  config.vm.define "red-target" do |red|
    red.vm.box = "bento/ubuntu-22.04"
    red.vm.hostname = "red-target"
    red.vm.network "private_network", ip: "192.168.56.10"
    red.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end
    red.vm.provider "vmware_desktop" do |v|
      v.vmx["memsize"] = "1024"
      v.vmx["numvcpus"] = "1"
    end
    red.vm.provision "shell", path: "scripts/setup_vulnerabilities.sh"
    red.vm.provision "shell", path: "scripts/deploy_wazuh_agent.sh"
  end
  config.vm.define "kali-attacker" do |kali|
    kali.vm.box = "kalilinux/rolling"
    kali.vm.hostname = "kali-attacker"
    kali.vm.network "private_network", ip: "192.168.56.5"
    kali.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.gui = false
    end
    kali.vm.provider "vmware_desktop" do |v|
      v.vmx["memsize"] = "2048"
      v.vmx["numvcpus"] = "2"
      v.gui = false
    end
    kali.vm.provision "shell", path: "scripts/setup_kali.sh"
    kali.vm.provision "shell", run: "always", inline: <<-SHELL
      echo "[*] Kali NetworkManager Bypass - Zirhli IP Atamasi Basliyor..."
      
      # 1. NetworkManager'in eth1'e mudehalesini KESIN olarak yasakla
      mkdir -p /etc/NetworkManager/conf.d
      cat <<'EOF' > /etc/NetworkManager/conf.d/99-unmanaged-eth1.conf
[keyfile]
unmanaged-devices=interface-name:eth1
EOF

      # 2. Yasagin devreye girmesi icin servisi yeniden baslat ve 2 saniye bekle
      systemctl restart NetworkManager
      sleep 2

      # 3. NM aradan cekildikten sonra IP'yi force ile ata
      ip link set eth1 up
      ip addr flush dev eth1
      ip addr add 192.168.56.5/24 dev eth1

      # 4. Son Kontrol
      ip_check=$(ip addr show eth1 2>/dev/null | grep '192.168.56.5')
      if [ -n "$ip_check" ]; then
        echo "[+] KALI NETWORK: 192.168.56.5 IP ADRESI %100 BASARIYLA KILITLENDI."
      else
        echo "[-] KALI NETWORK HATA: BIR SEYLER TERS GITTI."
      fi
    SHELL
  end
end