# Altay Deception Network Simulation

Bu proje, altyapı güvenliği, zafiyet yönetimi ve siber aldatma (deception) taktiklerini test etmek amacıyla oluşturulmuş 3 makineli bir laboratuvar ortamıdır. 

Temel amacı, hem savunma hem de saldırı operasyonlarını (Red/Blue Team) izole bir ortamda pratik edebilmek ve DNS yanıltmaları üzerinden saldırganı tespit/takip etme becerilerini geliştirmektir.

## Makine Bilgileri ve Roller

Laboratuvar, Vagrant altyapısı üzerinde çalışan üç makineden oluşmaktadır:

* **`blue-server` (Savunma Merkezi & SIEM - 192.168.56.20)**: 
  - Ağın izlenmesi ve saldırıların tespiti için Wazuh Manager, Indexer ve Dashboard içerir. 
  - Kendi üzerindeki DNS sunucusu sahte (deception) kayıtlar barındırarak saldırganları tuzağa düşürmeyi hedefler.
  
* **`red-target` (Kurban / Zafiyetli Sunucu - 192.168.56.10)**: 
  - Temiz, varsayılan bir Ubuntu 22.04 makinesidir. 
  - Zafiyet senaryoları ve saldırı pratikleri manuel olarak bu makine üzerinde uygulanır.

* **`kali-attacker` (Saldırgan Makinesi - 192.168.56.30)**: 
  - CLI tabanlı (arayüzsüz) Kali Linux dağıtımıdır. 
  - Ağ keşfi, sömürü (exploit) ve Red Team operasyonlarının yürütüldüğü ana saldırı makinesidir.

## Dizin Yapısı

- `blue_team/`: Mavi takımın tespit kural setleri, analiz scriptleri ve yapılandırmaları için.
- `red_team/`: Kırmızı takımın sömürü (exploit) araçları ve payload'ları için.
- `scripts/`: Altyapı ayağa kalkarken otomatik çalışan yapılandırma betiklerini barındırır.

## Kurulum ve Kullanım

Laboratuvardaki tüm makineleri başlatmak için:
```bash
vagrant up
```

Sadece saldırgan (Kali) makinesini başlatmak isterseniz:
```bash
vagrant up kali-attacker
```

Makineler çalışmaya başladıktan sonra, SSH ile içlerine erişmek için aşağıdaki komutları kullanın:

```bash
vagrant ssh blue-server
vagrant ssh red-target
vagrant ssh kali-attacker
```

Laboratuvarı tamamen silmek için `vagrant destroy -f` komutunu kullanabilirsiniz.
