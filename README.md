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

## Kurulum ve Kullanım

```bash
vagrant up
```

Makineler çalışmaya başladıktan sonra, Kali makinesinden tüm saldırı zincirini tek bir script ile başlatmak ve log oluşturmak için:
```bash
vagrant ssh kali-attacker
cd ~/red_team
./test_apt_chain.sh
```

Mavi Takım (Blue Team) üyeleri Wazuh SIEM üzerinden bu atakların loglarını ve alarmlarını inceleyebilir.
