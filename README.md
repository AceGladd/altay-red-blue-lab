# Altay Deception Network Simulation

Bu proje, altyapı güvenliği, zafiyet yönetimi ve siber aldatma (deception) taktiklerini test etmek amacıyla oluşturulmuş 2 makineli bir laboratuvar ortamıdır. 

Temel amacı, DNS üzerinde tanımlanan sahte kayıtlar (AXFR zafiyeti) aracılığıyla saldırganlara daha büyük bir ağdaymış yanılsaması (deception) vermektir. Böylece hem Kırmızı Takım (Red Team) saldırı senaryolarını çalışabilir hem de Mavi Takım (Blue Team) Wazuh SIEM üzerinden bu saldırıları tespit etmeyi öğrenebilir.

## Makine Bilgileri ve Roller

Laboratuvar, Vagrant ve VMware/VirtualBox altyapısı üzerinde çalışan iki Ubuntu 22.04 makinesinden oluşmaktadır:

* **`blue-server` (192.168.56.20)**: Savunma ve Aldatma (Deception) makinesi. 
  - Wazuh Manager, Indexer ve Dashboard bu makinede çalışır. 
  - Üzerindeki zafiyetli Bind9 DNS sunucusu, ağda `nfs`, `docker`, `pam` gibi birçok makine varmış gibi davranarak saldırganları asıl hedefe (`red-target`) yönlendirir.
  
* **`red-target` (192.168.56.10)**: Kurban / Hedef makine. 
  - İçerisinde hiçbir otomatik yapılandırma bulunmayan temiz bir makinedir. 
  - Zafiyet senaryoları ve saldırı hedefleri manuel olarak bu makine üzerinde uygulanacaktır.

## Dizin Yapısı

- `blue_team/`: Mavi takımın tespit kural setleri, Wazuh yapılandırmaları ve analiz betiklerini saklayacağı dizin.
- `red_team/`: Kırmızı takımın sömürü (exploit) araçlarını, payload'ları ve zafiyet senaryolarını barındıracağı dizin.
- `scripts/`: Vagrant ayağa kalkarken otomatik çalışan temel altyapı kurulum dosyaları (`deploy_wazuh_manager.sh` ve `setup_dns_deception.sh`).
- `Vagrantfile`: Sanal makinelerin ağ ve donanım yapılandırmalarını barındıran temel dosya.

## Kurulum ve Kullanım

Laboratuvarı başlatmak ve makineleri ayağa kaldırmak için terminalde şu komutu çalıştırın:
```bash
vagrant up
```

Makineler başarıyla oluşturulduktan sonra, SSH ile içlerine erişmek için aşağıdaki komutları kullanabilirsiniz:

```bash
# Savunma sunucusuna bağlanmak için:
vagrant ssh blue-server

# Hedef makineye bağlanmak için:
vagrant ssh red-target
```

Laboratuvarı durdurmak için `vagrant halt`, tamamen silmek için ise `vagrant destroy -f` komutlarını kullanabilirsiniz.
