import 'package:flutter/material.dart';

import '../services/yazici/bluetooth_print_service.dart';
import '../widgets/fis_onizleme_page.dart';
import 'fis_yazdir_helper.dart';

/// Araç yükleme teslim fişi: önce ekranda gösterilir, "Yazdır" denince yazıcıya gönderilir.
/// Yazıcı uzakta / bağlı değilse fiş ekranda kalır; hata mesajı gösterilir ve tekrar denenebilir.
class AracYuklemeFisHelper {
  const AracYuklemeFisHelper._();

  static Future<void> onizleVeYazdir(
    BuildContext context, {
    required String belgeNo,
    required DateTime tarih,
    required String depoAd,
    required String plasiyerAd,
    required List<AracYuklemeSatir> satirlar,
  }) async {
    final svc = BluetoothPrintService.instance;
    final satirGen = await FisYazdirHelper.satirGenisligi();
    final kullaniciAdi = await FisYazdirHelper.kullaniciAdi();

    final metin = svc.buildAracYuklemeFisiMetin(
      belgeNo: belgeNo,
      tarih: tarih,
      depoAd: depoAd,
      plasiyerAd: plasiyerAd,
      satirlar: satirlar,
      satirGenisligi: satirGen,
      kullaniciAdi: kullaniciAdi,
    );
    if (!context.mounted) return;

    await showFisOnizleme(
      context,
      baslik: 'Teslim Fişi',
      satirlar: metin,
      yazdir: () => FisYazdirHelper.baglanVeYazdir(svc.buildAracYuklemeFisi(
        belgeNo: belgeNo,
        tarih: tarih,
        depoAd: depoAd,
        plasiyerAd: plasiyerAd,
        satirlar: satirlar,
        satirGenisligi: satirGen,
        kullaniciAdi: kullaniciAdi,
      )),
    );
  }
}
