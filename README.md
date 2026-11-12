# rotakod

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Windows masaüstü / Windows Server

Windows bilgisayarda Flutter ve Visual Studio **Desktop development with C++** iş yükü (MSVC, CMake, Windows SDK) kurulu olmalıdır. Android Studio tek başına Windows EXE derlemez.

```powershell
flutter doctor -v
powershell -ExecutionPolicy Bypass -File .\build_windows.ps1
```

ZIP `.artifacts/windows/` klasöründe oluşur. ZIP'in tamamını sunucuya kopyalayıp ayıklayın ve `FilERP.exe` dosyasını açın. DLL'ler ve `data/` klasörü EXE ile birlikte kalmalıdır. Hedef sunucuda Flutter veya Visual Studio gerekmez; Microsoft Visual C++ Redistributable x64 gerekir: https://aka.ms/vs/17/release/vc_redist.x64.exe

Windows Server üzerinde Desktop Experience ve kullanıcı masaüstü/RDP oturumu gereklidir; Server Core veya Windows servisi olarak çalıştırma hedeflenmez. Belirli sunucu sürümü ve ekran sürücüsüyle çalışırlık sunucuda test edilmelidir. Bu Mac'te Windows yerel derlemesi veya sunucu testi yapılmadı.

Geliştirme sırasında doğrudan açmak için `flutter run -d windows` kullanın. Dashboard için admin yetkili hesabınızla yeniden giriş yapın. Windows üzerinde APK güncellemesi çalıştırılmaz.
