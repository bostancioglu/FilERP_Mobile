import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/yazici/bluetooth_print_service.dart';
import '../services/yazici/yazici_sablon_service.dart';
import '../widgets/fis_onizleme_page.dart';

/// Fişleri önce ekranda gösterip, "Yazdır" denince termal yazıcıya gönderen ortak yardımcı.
class FisYazdirHelper {
  const FisYazdirHelper._();

  /// Yazıcı satır genişliği (Ayarlar > Yazıcı Ayarları > Kağıt Eni).
  static Future<int> satirGenisligi() => YaziciSablonService.instance.getSatirGenisligi();

  /// Oturumdaki kullanıcı adı (fiş altında "Kullanıcı:" satırı için).
  static Future<String?> kullaniciAdi() async =>
      (await SharedPreferences.getInstance()).getString('kullanici_adi');

  /// Yazıcıya bağlanır (gerekirse) ve [bytes]'ı gönderir.
  /// Başarılıysa null, değilse kullanıcıya gösterilecek hata mesajını döndürür.
  static Future<String?> baglanVeYazdir(List<int> bytes) async {
    try {
      final svc = BluetoothPrintService.instance;
      var bagli = await svc.isConnected;
      if (!bagli) {
        final mac = await svc.getSavedMac();
        if (mac == null) {
          return "Kayıtlı yazıcı yok. Ayarlar > Yazıcı Ayarları'ndan bir yazıcı seçin.";
        }
        bagli = await svc.connect(mac);
        if (!bagli) return 'Yazıcıya bağlanılamadı.';
      }
      final ok = await svc.printBytes(bytes);
      return ok ? null : 'Yazdırma başarısız.';
    } catch (e) {
      return 'Yazdırma hatası: $e';
    }
  }

  /// [satirlar] fişini ekranda gösterir; yazdırma kullanıcı "Yazdır"a basınca yapılır.
  /// Yazıcı uzakta / kapalı olsa bile fiş ekranda kalır.
  static Future<void> onizleVeYazdir(
    BuildContext context, {
    required String baslik,
    required List<FisSatir> satirlar,
    required int satirGenisligi,
  }) async {
    if (!context.mounted) return;
    await showFisOnizleme(
      context,
      baslik: baslik,
      satirlar: FisSatir.onizleme(satirlar, satirGenisligi),
      yazdir: () => baglanVeYazdir(BluetoothPrintService.instance.buildSatirlarFisi(satirlar)),
    );
  }
}
