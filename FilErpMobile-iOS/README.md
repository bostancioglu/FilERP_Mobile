# FilERP Mobile

Flutter tabanlı FilERP mobil istemcisi.

## iOS geliştirme

Gereksinimler: Flutter SDK (kilitli paketlerin SDK gereksinimlerini karşılayan bir stable sürüm), Xcode ve CocoaPods. Minimum iOS sürümü 15.0'dır. Proje CocoaPods entegrasyonu kullanır; `print_bluetooth_thermal` bu nedenle 1.2.1 sürümüne sabitlenmiştir.

Proje kökünde:

```sh
flutter doctor -v
flutter pub get
cd ios
pod install
cd ..
flutter build ios --simulator --debug
flutter devices
flutter run -d <cihaz-kimliği>
```

Fiziksel iPhone için `ios/Runner.xcworkspace` dosyasını Xcode ile açın. Runner > Signing & Capabilities bölümünde Apple Developer takımınızı seçin. Bundle ID `com.filerp.mobile` olarak ayarlanmıştır; hesabınızdaki App ID ile eşleştirin. Takımınızı depoya kaydetmeden kullanmak için `ios/Flutter/Local.xcconfig` dosyasına `DEVELOPMENT_TEAM = TAKIM_KIMLIGI` yazın. Bu dosya Git dışında tutulur. Sertifikalar depoya eklenmez.

İmzasız cihaz derlemesi kontrolü:

```sh
flutter build ios --release --no-codesign
```

## Cihazda kontrol edilecekler

- Giriş, test ortamında şirket/şube seçimi ve API erişimi.
- Barkod kamerası, galeriden fatura görseli ve yazıcı logosu seçimi.
- Uygulama açıkken konum erişimi.
- Gerçek iPhone üzerinde NFC etiket okuma. FeliCa sistem kodları tanımlı olmadığı için ISO 18092 taraması kapalıdır; yeni etiket türleri için ilgili Apple tanımları eklenmelidir.
- iOS uyumlu Bluetooth termal yazıcı ile keşif, bağlantı ve test çıktısı. Android'de çalışan her Bluetooth yazıcının iOS desteği olduğu varsayılmamalıdır.
- PDF önizleme, paylaşma ve yazdırma.

Canlı e-belge gönderimi test amacıyla yapılmaz. APK güncellemesi yalnızca Android'de çalışır; iOS dağıtımı Apple imzalama ve dağıtım akışını kullanır.

Mevcut ERP ve e-belge API'leri HTTP ve doğrudan IP adresleri kullandığı için Info.plist içinde ATS istisnası bulunmaktadır. API'ler HTTPS'e geçirildiğinde bu geniş istisna kaldırılmalıdır.

## Bu ortamda doğrulama

Flutter 3.47.9 ve CocoaPods 1.16.2 kuruldu. Flutter ve CocoaPods komutları terminal PATH ayarında bulunmalıdır. Sistem Ruby 2.6 ile uyumlu CocoaPods bağımlılıkları kullanıldı; CocoaPods başlatıcısı Logger yüklemesini açıkça yapar.

Apple Silicon simülatör desteği için barkod paketi `mobile_scanner: 7.1.4` sürümüne geçirildi. Bu sürüm Apple Vision kullanır ve yerel PDF paketinin `web` bağımlılığıyla uyumludur. Flutter'ın iOS 15 ve UIScene geçişi yalnızca bu kopyaya uygulandı. `flutter test test/authorization_test.dart` ile mevcut 17 test geçti.

Simülatörde çalıştırma (cihaz kimliğini `flutter devices` ile bulun):

```sh
cd FilErpMobile-iOS
flutter run -d <simulator-kimligi>
```

ARM64 derlemesi ve `flutter run --no-resident` başarılı oldu; iPhone 18 Pro / iOS 27.2 simülatöründe giriş ekranı açıldı ve ekran görüntüsüyle doğrulandı. Gerçek kullanıcı girişi yapılmadı. Fiziksel cihazda kamera, NFC, konum ve yazıcı kontrolleri ayrıca yapılmalıdır.

## Kişisel Apple hesabıyla iPhone kurulumu

Kişisel Apple takımıyla deneme için Runner imzalama dosyası `ios/Runner/Runner.personal.entitlements` olarak seçildi. Kişisel Apple takımı NFC Tag Reading yetkisini desteklemediğinden bu sürüm NFC okuma yetkisi içermez. Tam NFC tanımı `ios/Runner/Runner.entitlements` dosyasında korunur; uygun Apple Developer takımına geçildiğinde Runner Build Settings > Code Signing Entitlements alanı o dosyaya döndürülebilir.

Bağlı telefonda bağımsız açılabilen release sürümünü çalıştırmak için, bu klasörde:

```sh
flutter run --release -d <iphone-kimligi> --no-resident
```

Fiziksel cihaz kurulumu: release derlemesi imzalandı ve bir iPhone’a `com.filerp.mobile` olarak kuruldu. İlk açılış için iPhone'da Ayarlar > Genel > VPN ve Aygıt Yönetimi > Geliştirici Uygulaması altında geliştirici profiline güven verilmelidir. Kurulum başarılı olsa da bu onay verilmeden iOS uygulamayı başlatmaz.

Geliştirici profiline güven verildikten sonra fiziksel iPhone üzerinde uygulama başarıyla başlatıldı.
