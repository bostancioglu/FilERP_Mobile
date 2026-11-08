# Proje bağlamı

- FilERP Mobile, `D:\Projeler\Ihesap\IHesappBackend\DTMobil.API` projesinin API'sinden veri alır.
- Backend Git deposu: `D:\Projeler\Ihesap\IHesappBackend`.
- Kullanıcı bu backend deposunda yalnızca güncelleme çeker. Push, yayınlama veya karşı tarafa dosya/commit gönderme işlemi yapılmaz.
- Yerel `DTMobil.API/appsettings.json` korunur; uzak sürümüyle değiştirilmez ve içeriği çıktılarda gösterilmez.
- Yerel `DTMobil.Service/DTMobil.Service.csproj` dosyasındaki DLL yolu korunur; backend deposunun kendi `Agents.md` talimatlarına uyulur.
- Yerel ayarları koruyan güncelleme komutu backend kökünde `git pull-local` komutudur; betiği `.git/pull-local.ps1` altında bulunur.
- E-fatura/e-irsaliye API projesi: `D:\Projeler\EFatura.Backend`; mevcut portal istemcisi: `D:\Projeler\EFatura.Frontend\EFatura.Frontend`.
- Portala gönderme IHesap API'sindeki `Fatura/portala-gonder/{id}` ve `Irsaliye/portala-gonder/{id}` işlemleridir. Gerçek e-belge gönderimi ayrı API'deki `EFatura/send-invoice` ve `EIrsaliye/send-waybill` uçlarıyla yapılır; bu iki aşama birbirine karıştırılmamalıdır.
- E-belge inceleme ve testlerinde canlı belge gönderimi yapılmaz. Entegratör sırları kod içine sabitlenmez ve çıktılarda gösterilmez.
- Kullanıcının verdiği e-belge API adresleri: test `31.207.84.254:7197`, canlı `152.89.38.195:7199`. Mobil ortam seçimi bu adreslerle eşleşir; API yolları `/api` altındadır.
