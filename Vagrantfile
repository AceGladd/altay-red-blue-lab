Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.define "blue-server" do |blue|
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
end