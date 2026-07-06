# Altay Deception Network Simulation

Bu proje, altyapı güvenliği, zafiyet yönetimi ve siber aldatma (deception) taktiklerini test etmek amacıyla oluşturulmuş 3 makineli bir laboratuvar ortamıdır. 

## Makine Bilgileri ve Roller

* **`blue-server` (192.168.56.20)**: Savunma Merkezi & SIEM (Wazuh). Deception (sahte) DNS kayıtlarını barındırır.
* **`red-target` (192.168.56.10)**: Kurban Sunucu. Üzerinde bilinçli olarak bırakılmış 8 farklı zafiyet vektörü bulunur.
* **`kali-attacker` (192.168.56.5)**: Saldırgan Makinesi. Otomatize saldırı betikleri bu makineden çalıştırılır.

## Barındırılan Zafiyet Vektörleri (APT Simülasyonu)

Laboratuvarda tam teşekküllü bir siber saldırı zinciri (Kill Chain) simüle edilebilmesi için şu 8 zafiyet bulunur:

**İlk Erişim (Initial Access):**
1. **DNS Zone Transfer (AXFR):** `blue-server` üzerinde sahte ağ haritasını sızdıran zafiyet.
2. **Web Komut Enjeksiyonu (OS Command Injection):** Web uygulaması üzerinden doğrudan kurban sisteme Reverse Shell alınabilmesi.
3. **NFS `no_root_squash` Zafiyeti:** Dışarıya root yetkisiyle açık `/home` dizini paylaşımı.
4. **Açığa Çıkmış Şifresiz SSH Anahtarı:** NFS üzerinden `developer` kullanıcısına ait `id_rsa` anahtarının çalınıp hedefe sızılması (Lateral Movement).

**Kalıcılık (Persistence):**
5. **Yetkilendirilmiş Anahtar (Authorized Keys) Ekleme:** Hedefteki `.ssh/authorized_keys` dosyasına şifresiz arka kapı (backdoor) anahtarı bırakılması.

**Yetki Yükseltme (Privilege Escalation):**
6. **SUID (Gizli Kopya):** SUID biti aktif `/usr/local/bin/.hidden_cp` ile kritik dosya kopyalama.
7. **Sudoers Yanlış Yapılandırması:** `developer` kullanıcısının root olarak `find` komutu çalıştırabilmesi.

**Veri Sızdırma (Exfiltration):**
8. **DNS Tünelleme:** Sistemdeki kritik bir dosyanın DNS TXT kayıtlarıyla dışarı sızdırılması.

## Kurulum ve Kullanım Yönergesi

### 1. Ön Hazırlık
Sisteminizde aşağıdaki yazılımların kurulu olduğundan emin olmalısınız:
* **Vagrant** (Makineleri yönetmek için): [İndirme Bağlantısı](https://developer.hashicorp.com/vagrant/install/vmware)
* **VMware Workstation/Player veya VirtualBox** (Sanallaştırma altyapısı için)

### 2. Genel Kurulum (Makineleri Başlatma)
Terminal veya komut satırını açıp, projenin bulunduğu klasöre (`altay-red-blue-lab`) gidin. Ardından aşağıdaki komutu çalıştırarak laboratuvarı inşa etmeye başlayın:

```bash
vagrant up
```
Bu komut; `blue-server`, `red-target` ve `kali-attacker` makinelerini sırasıyla indirecek, kuracak ve tüm zafiyet ile ağ ayarlarını otomatik olarak yapılandıracaktır.

### 3. Makinelere Bağlanma
Kurulum tamamlandıktan sonra, herhangi bir makineye terminal üzerinden şifresiz olarak doğrudan bağlanabilirsiniz:

**Savunma (Wazuh & DNS) Sunucusuna Bağlanmak İçin:**
```bash
vagrant ssh blue-server
```
*(Wazuh Dashboard'a tarayıcınızdan `https://localhost:8443/` adresinden ulaşabilirsiniz).*

**Kurban (Zafiyetli) Sunucuya Bağlanmak İçin:**
```bash
vagrant ssh red-target
```

**Saldırgan (Kali Linux) Makinesine Bağlanmak İçin:**
```bash
vagrant ssh kali-attacker
```

### 4. Laboratuvarda Saldırı Senaryosunu Tetikleme
Tüm sistem hazır olduktan sonra, zafiyet zincirini (Kill Chain) otomatik olarak test etmek ve Mavi Takım için (Wazuh SIEM) log oluşturmak isterseniz Kali makinesini kullanabilirsiniz.

Kali makinesine bağlanın:
```bash
vagrant ssh kali-attacker
```
Otomatik test betiğini çalıştırın:
```bash
cd ~/red_team
./test_apt_chain.sh
```

### 5. Laboratuvarı Durdurma ve Silme
Çalışmanız bittiğinde kaynak tüketimini durdurmak veya sistemi sıfırlamak için şu komutları kullanabilirsiniz:

**Makineleri Geçici Olarak Durdurmak İçin (Veriler silinmez):**
```bash
vagrant halt
```

**Tüm Laboratuvarı Tamamen Silip Sıfırlamak İçin:**
```bash
vagrant destroy -f
```
