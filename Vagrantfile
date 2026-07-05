Vagrant.configure("2") do |config|
  config.vm.define "blue-server" do |blue|
    blue.vm.box = "bento/ubuntu-22.04"
    blue.vm.hostname = "blue-server"
    blue.vm.network "private_network", ip: "192.168.56.20"
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
  end
  config.vm.define "kali-attacker" do |kali|
    kali.vm.box = "kalilinux/rolling"
    kali.vm.hostname = "kali-attacker"
    kali.vm.network "private_network", ip: "192.168.56.30"
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
  end
end