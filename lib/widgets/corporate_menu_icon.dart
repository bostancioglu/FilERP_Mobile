import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Ana menü, alt menü ve hızlı erişim için ortak FilERP ikonları.
class CorporateMenuIcon extends StatelessWidget {
  final String label;
  final double size;
  final bool onColoredSurface;
  final IconData fallback;
  const CorporateMenuIcon(this.label,
      {super.key,
      this.size = 28,
      this.onColoredSurface = false,
      this.fallback = Icons.grid_view_outlined});

  static String? resolve(String label) {
    final text = label
        .replaceAll('İ', 'i')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u');
    if (text.contains('arac yukl')) return 'arac-yukleme';
    if (text.contains('bluetooth')) return 'bluetooth';
    if (text.contains('kagit') || text.contains('genisli')) return 'olcu';
    if (text == 'dat' || text.contains('transfer')) return 'transfer';
    if (text.contains('sablon')) return 'sablon';
    if (text.contains('yazici') || text.contains('yazdir')) return 'yazici';
    if (text.contains('tema') || text.contains('gorunum')) return 'tema';
    if (text.contains('cevrimdisi') || text.contains('offline'))
      return 'cevrimdisi';
    if (text.contains('baglanti')) return 'baglanti';
    if (text.contains('proje')) return 'proje';
    if (text.contains('barkod')) return 'barkod';
    if (text.contains('kuyruk') || text.contains('bilinmeyen islem'))
      return 'kuyruk';
    if (text.contains('guncel') ||
        text.contains('surum') ||
        text.contains('versiyon')) return 'guncelleme';
    if (text.contains('konum') || text.contains('harita')) return 'konum';
    if (text == 'ana sayfa') return 'ana-sayfa';
    if (text == 'nfc') return 'nfc';
    if (text.contains('cikis')) return 'cikis';
    if (text.contains('kullanici') || text.contains('profil'))
      return 'kullanici';
    if (text.contains('portal')) return 'portal';
    if (text.contains('e-belge') ||
        text.contains('e-fatura') ||
        text.contains('e-irsaliye')) return 'e-belge';
    if (text.contains('tahsilat') || text.contains('odeme')) return 'tahsilat';
    if (text.contains('fatura')) return 'fatura';
    if (text.contains('irsaliye')) return 'irsaliye';
    if (text.contains('siparis')) return 'siparis';
    if (text.contains('teklif')) return 'teklif';
    if (text.contains('cek') || text.contains('senet')) return 'cek-senet';
    if (text.contains('kasa')) return 'kasa';
    if (text.contains('banka')) return 'banka';
    if (text.contains('finans')) return 'finans';
    if (text.contains('depo') ||
        text.contains('ambar') ||
        text.contains('transfer') ||
        text.contains('arac yukl')) return 'depo';
    if (text.contains('stok')) return 'stok';
    if (text.contains('cari')) return 'cari';
    if (text.contains('rapor') ||
        text.contains('ekstre') ||
        text.contains('ozet')) return 'raporlar';
    if (text.contains('ayar') || text == 'genel') return 'ayarlar';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final name = resolve(label);
    if (name == null)
      return Icon(fallback,
          size: size,
          color: onColoredSurface
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface);
    final mode = onColoredSurface
        ? 'white'
        : Theme.of(context).brightness == Brightness.dark
            ? 'dark'
            : 'light';
    return SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          'assets/icons/corporate/$mode/$name.svg',
          width: size,
          height: size,
          excludeFromSemantics: true,
        ));
  }
}
