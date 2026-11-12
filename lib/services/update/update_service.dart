import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// ─── Sunucudan çekilecek version.json formatı ────────────────────────────────
///
///  {
///    "versionCode": 46,
///    "versionName": "1.0.046",
///    "downloadUrl": "https://...",
///    "releaseNotes": "• Yeni özellikler\n• Hata düzeltmeleri"
///  }
///
/// ─────────────────────────────────────────────────────────────────────────────
class UpdateInfo {
  final int    versionCode;
  final String versionName;
  final String downloadUrl;
  final String releaseNotes;

  UpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> j) => UpdateInfo(
    versionCode:  j['versionCode']  as int,
    versionName:  j['versionName']  as String,
    downloadUrl:  j['downloadUrl']  as String,
    releaseNotes: j['releaseNotes'] as String? ?? '',
  );
}

/// ─── UpdateService ────────────────────────────────────────────────────────────
///
/// Kullanım:
///   await UpdateService.instance.checkForUpdate()
///   await UpdateService.instance.downloadAndInstall(info)
///
/// ⚠️  _versionJsonUrl sabitini kendi sunucunuza göre ayarlayın.
///     GitHub örneği:
///       https://raw.githubusercontent.com/KULLANICI/REPO/main/version.json
/// ─────────────────────────────────────────────────────────────────────────────
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// Versiyon bilgisinin bulunduğu JSON URL — buraya kendi URL'nizi yazın
  static const _versionJsonUrl =
      'https://filerp.com/apk/version.json';

  /// İndirme ilerlemesi: null = boşta, 0.0–1.0 = indiriyor
  final ValueNotifier<double?> downloadProgress = ValueNotifier(null);

  /// Giriş akışından tetiklenen otomatik güncelleme bayrağı.
  /// Ayarlar sayfası açıldığında bu dolu ise indirmeyi otomatik başlatır.
  UpdateInfo? pendingAutoInstall;

  // ─── SSL bypass'lı HTTP client ───────────────────────────────────────────
  /// Kendi sunucumuzdan indirdiğimiz için sertifika doğrulamasını atlıyoruz.
  http.Client _buildClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    return IOClient(ioClient);
  }

  // ─── Güncelleme Kontrolü ─────────────────────────────────────────────────
  /// Güncelleme varsa [UpdateInfo] döner, yoksa null.
  Future<UpdateInfo?> checkForUpdate() async {
    // APK güncellemesi masaüstü ve iOS üzerinde uygulanmaz.
    if (!Platform.isAndroid) return null;
    final pkgInfo     = await PackageInfo.fromPlatform();
    final currentCode = int.tryParse(pkgInfo.buildNumber) ?? 0;

    final client = _buildClient();
    final resp   = await client
        .get(Uri.parse(_versionJsonUrl))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception('Sunucuya erişilemedi (HTTP ${resp.statusCode})');
    }

    final data       = jsonDecode(resp.body) as Map<String, dynamic>;
    final remoteCode = data['versionCode'] as int;

    if (remoteCode > currentCode) return UpdateInfo.fromJson(data);
    return null; // Zaten güncel
  }

  // ─── İndir & Kur ─────────────────────────────────────────────────────────
  Future<void> downloadAndInstall(UpdateInfo info) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('APK güncellemesi yalnızca Android üzerinde kullanılabilir.');
    }
    downloadProgress.value = 0.0;

    try {
      final dir      = await getTemporaryDirectory();
      // Sunucu .zip olarak servis ediyorsa bile kaydedilen dosya .apk olmalı
      final filePath = '${dir.path}/filerp_${info.versionName}.apk';
      final file     = File(filePath);

      // Eski yarım dosya varsa sil
      if (await file.exists()) await file.delete();

      final client   = _buildClient();
      final request  = http.Request('GET', Uri.parse(info.downloadUrl));
      final response = await client.send(request);
      final total    = response.contentLength ?? 0;
      var   received = 0;

      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) downloadProgress.value = received / total;
      }
      await sink.close();
      client.close();

      downloadProgress.value = null;

      // Android 8+ — bilinmeyen kaynaklardan yükleme izni kontrolü
      if (Platform.isAndroid) {
        var status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          // Kullanıcıyı Ayarlar sayfasına gönder
          await Permission.requestInstallPackages.request();
          status = await Permission.requestInstallPackages.status;
          if (!status.isGranted) {
            throw Exception(
              'Kurulum izni verilmedi.\n'
              'Ayarlar → Uygulamalar → FilERP → '
              'Bilinmeyen uygulamaları yükle → Açık yapın.',
            );
          }
        }
      }

      // Android'in yerleşik paket yükleyicisini aç
      final result = await OpenFile.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        throw Exception('Yükleyici açılamadı: ${result.message}');
      }
    } catch (e) {
      downloadProgress.value = null;
      rethrow;
    }
  }
}
