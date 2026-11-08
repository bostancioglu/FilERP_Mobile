import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/yazici/yazici_sablon.dart';
import 'fis_satir.dart';
import 'yazici_sablon_service.dart';

export 'fis_satir.dart';
export 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart'
    show BluetoothInfo;

// ─── Kağıt genişliği ──────────────────────────────────────────────────────────
// 58mm kağıt → 32 karakter
// 80mm kağıt → 42 karakter   (bu satırı değiştirin)
const int _kWidth = 32;

class BluetoothPrintService {
  BluetoothPrintService._();
  static final BluetoothPrintService instance = BluetoothPrintService._();

  static const _kMac  = 'bt_printer_mac';
  static const _kName = 'bt_printer_name';

  // ── Kayıtlı yazıcı ─────────────────────────────────────────────────────────

  Future<String?> getSavedMac() async =>
      (await SharedPreferences.getInstance()).getString(_kMac);
  Future<String?> getSavedName() async =>
      (await SharedPreferences.getInstance()).getString(_kName);

  Future<void> savePrinter(String mac, String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kMac, mac);
    await p.setString(_kName, name);
  }

  Future<void> clearPrinter() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kMac);
    await p.remove(_kName);
  }

  // ── Bluetooth bağlantı ─────────────────────────────────────────────────────

  Future<List<BluetoothInfo>> getPairedDevices() async {
    try { return await PrintBluetoothThermal.pairedBluetooths; }
    catch (_) { return []; }
  }

  Future<bool> connect(String mac) async {
    try { return await PrintBluetoothThermal.connect(macPrinterAddress: mac); }
    catch (_) { return false; }
  }

  Future<bool> get isConnected async {
    try { return await PrintBluetoothThermal.connectionStatus; }
    catch (_) { return false; }
  }

  Future<bool> disconnect() async {
    try { return await PrintBluetoothThermal.disconnect; }
    catch (_) { return false; }
  }

  // ── Yazdırma ───────────────────────────────────────────────────────────────

  Future<bool> printBytes(List<int> bytes) async {
    try { return await PrintBluetoothThermal.writeBytes(bytes); }
    catch (_) { return false; }
  }

  Future<bool> printTest({String printerName = ''}) async =>
      printBytes(_buildTestReceipt(printerName: printerName));

  /// Şablon ile yazdır
  Future<bool> printWithTemplate({
    required YaziciSablon sablon,
    required String stokAd,
    required String stokKod,
    required String barkod,
    required String olcuBirimi,
    required int adet,
    int kagitEniMm = 80,
    int? satirGenisligi, // null → kagitEniMm'den otomatik hesapla
  }) async {
    // Font A (12x24): 58mm→32 karakter, 80mm→48 karakter
    final kw = satirGenisligi ?? (kagitEniMm >= 80 ? 48 : 32);
    final data = {
      'stokKodu':    stokKod,
      'stokAdi':     stokAd,
      'barkodNo':    barkod,
      'olcuBirimi':  olcuBirimi,
      'tarih': () {
        final n = DateTime.now();
        return '${_p2(n.day)}.${_p2(n.month)}.${n.year}  ${_p2(n.hour)}:${_p2(n.minute)}';
      }(),
    };

    // Logo satırı varsa önceden yükle (async bitmap dönüşümü)
    List<int>? logoBytes;
    final logoSatir = sablon.satirlar.where((s) => s.tip == SatirTipi.logo).firstOrNull;
    if (logoSatir != null) {
      try {
        logoBytes = await _buildLogoEscBytes(kagitEniMm, logoSatir.logoBoyu);
      } catch (_) {
        logoBytes = null; // logo yüklenemezse sessizce atla
      }
    }

    return printBytes(_renderTemplate(sablon, data, adet, kw, logoBytes: logoBytes));
  }

  List<int> _renderTemplate(
      YaziciSablon sablon, Map<String, String> data, int adet, int kw,
      {List<int>? logoBytes}) {
    final b = <int>[];
    // Kod sayfası + barkod ayarları
    b.addAll([0x1B, 0x74, 0x0D]);
    b.addAll([0x1D, 0x68, 0x50]); // barkod yükseklik
    b.addAll([0x1D, 0x77, 0x02]); // barkod genişlik
    b.addAll([0x1D, 0x48, 0x02]); // HRI alt

    for (int i = 0; i < adet; i++) {
      for (final satir in sablon.satirlar) {
        b.addAll(_renderSatir(satir, data, kw, logoBytes: logoBytes));
      }
      b.addAll([0x1B, 0x64, 0x03]);
      b.addAll(i < adet - 1 ? [0x1D, 0x56, 0x01] : [0x1D, 0x56, 0x00]);
    }
    return b;
  }

  List<int> _renderSatir(SablonSatir satir, Map<String, String> data, int kw,
      {List<int>? logoBytes}) {
    final b = <int>[];

    switch (satir.tip) {
      case SatirTipi.logo:
        if (logoBytes != null && logoBytes.isNotEmpty) {
          _setHizalama(b, satir.hizalama);
          b.addAll(logoBytes);
          b.add(0x0A);
          _setHizalama(b, Hizalama.sol);
        }
        return b;

      case SatirTipi.ayirici:
        final kar = satir.ayiriciKar.isNotEmpty ? satir.ayiriciKar[0] : '-';
        b.addAll(List.filled(kw, kar.codeUnitAt(0)));
        b.add(0x0A);
        return b;

      case SatirTipi.bosluk:
        b.add(0x0A);
        return b;

      case SatirTipi.barkod:
        final barStr = data['barkodNo'] ?? '';
        if (barStr.isEmpty) return b;
        _setHizalama(b, Hizalama.orta);
        final bytes = barStr.codeUnits
            .where((c) => c >= 0x20 && c <= 0x7E)
            .toList();
        if (bytes.isNotEmpty) {
          b.addAll([0x1D, 0x6B, 0x49, bytes.length]);
          b.addAll(bytes);
          b.add(0x0A);
        }
        _setHizalama(b, Hizalama.sol);
        return b;

      case SatirTipi.alan:
      case SatirTipi.metin:
        String icerik = '';
        if (satir.tip == SatirTipi.alan) {
          icerik = data[satir.alanKodu?.name ?? ''] ?? '';
        } else {
          icerik = satir.staticMetin ?? '';
        }
        // Uzun metni sar
        if (satir.boy == YaziBoyutu.buyuk && icerik.length > kw ~/ 2) {
          icerik = icerik.substring(0, kw ~/ 2);
        } else if (satir.boy == YaziBoyutu.normal && icerik.length > kw) {
          icerik = icerik.substring(0, kw);
        }

        _setHizalama(b, satir.hizalama);
        if (satir.kalin)           b.addAll([0x1B, 0x45, 0x01]);
        if (satir.boy == YaziBoyutu.buyuk) b.addAll([0x1D, 0x21, 0x11]);

        b.addAll(_cp857(icerik));
        b.add(0x0A);

        if (satir.boy == YaziBoyutu.buyuk) b.addAll([0x1D, 0x21, 0x00]);
        if (satir.kalin)           b.addAll([0x1B, 0x45, 0x00]);
        _setHizalama(b, Hizalama.sol);
        return b;
    }
  }

  // ── Logo → ESC/POS Raster Bitmap ──────────────────────────────────────────
  // FilERP logosunu PNG'den okur, 1-bit siyah/beyaz bitmap'e dönüştürür,
  // GS v 0 (raster bit image) komutu olarak döner.

  Future<List<int>> _buildLogoEscBytes(int paperWidthMm, LogoBoyu logoBoyu) async {
    // Kağıt genişliği + logo boyutuna göre piksel genişliği
    final targetW = paperWidthMm >= 80 ? logoBoyu.px80mm() : logoBoyu.px58mm();

    // Custom logo varsa onu kullan, yoksa varsayılan FilERP logosu
    ui.Codec codec;
    final customPath = await YaziciSablonService.instance.getCustomLogoPath();
    if (customPath != null) {
      final bytes = await File(customPath).readAsBytes();
      codec = await ui.instantiateImageCodec(bytes, targetWidth: targetW);
    } else {
      final byteData = await rootBundle.load('assets/images/logo_filerp.png');
      codec = await ui.instantiateImageCodec(
          byteData.buffer.asUint8List(), targetWidth: targetW);
    }
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final w = image.width;
    final h = image.height;

    final pixelData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (pixelData == null) return [];

    // Her satır için byte sayısı (ceil(w/8))
    final bytesPerRow = (w + 7) ~/ 8;
    final bitmapData = <int>[];

    for (int y = 0; y < h; y++) {
      for (int xByte = 0; xByte < bytesPerRow; xByte++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final x = xByte * 8 + bit;
          if (x < w) {
            final offset = (y * w + x) * 4;
            final r = pixelData.getUint8(offset);
            final g = pixelData.getUint8(offset + 1);
            final bl = pixelData.getUint8(offset + 2);
            final a  = pixelData.getUint8(offset + 3);
            // Saydam pikselleri beyaz zemine bileştir
            final rr = ((r * a + 255 * (255 - a)) ~/ 255);
            final gg = ((g * a + 255 * (255 - a)) ~/ 255);
            final bb = ((bl * a + 255 * (255 - a)) ~/ 255);
            // Gri değer: < 128 → siyah (yazdır)
            final gray = (0.299 * rr + 0.587 * gg + 0.114 * bb).round();
            if (gray < 128) byte |= (1 << (7 - bit));
          }
        }
        bitmapData.add(byte);
      }
    }

    // GS v 0: 1D 76 30 <mode> <xL> <xH> <yL> <yH> <data>
    final result = <int>[
      0x1D, 0x76, 0x30, 0x00,          // GS v 0, normal boyut
      bytesPerRow & 0xFF,               // xL
      (bytesPerRow >> 8) & 0xFF,        // xH
      h & 0xFF,                         // yL
      (h >> 8) & 0xFF,                  // yH
    ];
    result.addAll(bitmapData);
    return result;
  }

  void _setHizalama(List<int> b, Hizalama h) {
    switch (h) {
      case Hizalama.sol:  b.addAll([0x1B, 0x61, 0x00]);
      case Hizalama.orta: b.addAll([0x1B, 0x61, 0x01]);
      case Hizalama.sag:  b.addAll([0x1B, 0x61, 0x02]);
    }
  }

  /// Barkod etiketi yazdır (Code128 + stok bilgisi)
  Future<bool> printBarkodLabel({
    required String stokAd,
    required String stokKod,
    required String barkod,
    required String olcuBirimi,
    required int adet,
  }) async =>
      printBytes(_buildBarkodLabel(
        stokAd: stokAd,
        stokKod: stokKod,
        barkod: barkod,
        olcuBirimi: olcuBirimi,
        adet: adet,
      ));

  /// Karakter haritası — hangi byte hangi karakteri basıyor
  Future<bool> printCharMap() async =>
      printBytes(_buildCharMap());

  /// Kod sayfası tarama — hangi ESC t değeri PC857 açıyor?
  Future<bool> printCodePageScan() async =>
      printBytes(_buildCodePageScan());

  // ═══════════════════════════════════════════════════════════════════════════
  // ESC/POS BUILDER — Türkçe PC857
  //
  // NOT: ESC t (kod sayfası seçimi) GÖNDERILMIYOR.
  // Yazıcı HPRT programında zaten PC857 ayarlı; ESC t bazı firmware versiyonlarında
  // farklı kod sayfası numarası kullanır ve ayarı bozar.
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Barkod Etiketi Builder ─────────────────────────────────────────────────

  List<int> _buildBarkodLabel({
    required String stokAd,
    required String stokKod,
    required String barkod,
    required String olcuBirimi,
    required int adet,
  }) {
    final b = <int>[];

    // Kod sayfası: t13 (Türkçe)
    b.addAll([0x1B, 0x74, 0x0D]);

    // Barkod görünüm ayarları
    b.addAll([0x1D, 0x68, 0x50]); // GS h 80  — barkod yüksekliği (dot)
    b.addAll([0x1D, 0x77, 0x02]); // GS w 2   — barkod genişlik çarpanı
    b.addAll([0x1D, 0x48, 0x02]); // GS H 2   — HRI (metin) alt tarafta
    b.addAll([0x1D, 0x66, 0x00]); // GS f 0   — HRI font A

    for (int i = 0; i < adet; i++) {
      // ── Stok kodu (merkez, bold) ──
      _center(b);
      _bold(b, true);
      // Stok kodu ASCII olmalı (barkod yazıcı güvenliği için)
      b.addAll(_toAsciiBytes(stokKod));
      _nl(b);
      _bold(b, false);

      // ── Stok adı (sol, Türkçe CP857) ──
      _left(b);
      final adTrunc = stokAd.length > _kWidth
          ? stokAd.substring(0, _kWidth)
          : stokAd;
      _txt(b, adTrunc);
      _nl(b);

      b.addAll(List.filled(_kWidth, 0x2D)); // ----
      b.add(0x0A);

      // ── CODE128 barkod ──
      _center(b);
      final barkodBytes = barkod.codeUnits
          .where((c) => c >= 0x20 && c <= 0x7E)
          .toList();
      if (barkodBytes.isNotEmpty) {
        b.addAll([0x1D, 0x6B, 0x49]); // GS k 73 = Code128
        b.add(barkodBytes.length);
        b.addAll(barkodBytes);
        b.add(0x0A);
      }

      // ── Ölçü birimi ──
      if (olcuBirimi.isNotEmpty) {
        _left(b);
        b.addAll(List.filled(_kWidth, 0x2D));
        b.add(0x0A);
        _txt(b, olcuBirimi);
        _nl(b);
      }

      // ── Kesim ──
      b.addAll([0x1B, 0x64, 0x03]); // 3 satır besle
      if (i < adet - 1) {
        b.addAll([0x1D, 0x56, 0x01]); // kısmi kes (arada)
      } else {
        b.addAll([0x1D, 0x56, 0x00]); // tam kes (son)
      }
    }

    return b;
  }

  /// Türkçe karakterleri ASCII'ye düşür (barkod veri güvenliği)
  List<int> _toAsciiBytes(String s) => s.runes.map((r) {
    switch (r) {
      case 0x00E7: return 0x63; // ç→c
      case 0x00C7: return 0x43; // Ç→C
      case 0x011F: return 0x67; // ğ→g
      case 0x011E: return 0x47; // Ğ→G
      case 0x0131: return 0x69; // ı→i
      case 0x0130: return 0x49; // İ→I
      case 0x00F6: return 0x6F; // ö→o
      case 0x00D6: return 0x4F; // Ö→O
      case 0x015F: return 0x73; // ş→s
      case 0x015E: return 0x53; // Ş→S
      case 0x00FC: return 0x75; // ü→u
      case 0x00DC: return 0x55; // Ü→U
      default: return r < 0x80 ? r : 0x3F;
    }
  }).toList();

  // ── Test Fişi Builder ──────────────────────────────────────────────────────

  List<int> _buildTestReceipt({String printerName = ''}) {
    final b = <int>[];
    final now = DateTime.now();

    // ESC t 13 (0x0D) = PC857 Turkish
    // Test fiş taramasında t13 satırında ğ/ş/ı/İ doğrulandı (2026-06-05)
    // ESC @ gönderilmiyor (fabrika CP852'ye sıfırlar)
    _esc(b, [0x1B, 0x74, 0x0D]);

    // ── Başlık ──
    _center(b);
    _bold(b, true); _size(b, big: true);
    _txt(b, 'FilERP'); _nl(b);
    _size(b, big: false);
    _txt(b, 'Satış Fişi - Örnek'); _nl(b);
    _bold(b, false);
    _divider(b, '=');

    // ── Kasa bilgisi ──
    _left(b);
    _txt(b, 'Tarih   : ${_p2(now.day)}.${_p2(now.month)}.${now.year}'); _nl(b);
    _txt(b, 'Saat    : ${_p2(now.hour)}:${_p2(now.minute)}:${_p2(now.second)}'); _nl(b);
    _txt(b, 'Şube    : Merkez Şube');      _nl(b);
    _txt(b, 'Kasiyer : Ahmet Yılmaz');     _nl(b);
    if (printerName.isNotEmpty) {
      final pn = printerName.length > 20
          ? printerName.substring(0, 20) : printerName;
      _txt(b, 'Yazıcı  : $pn'); _nl(b);
    }
    _divider(b, '-');

    // ── Ürün listesi ──
    _bold(b, true);
    _txt(b, 'Ürün Listesi'); _nl(b);
    _bold(b, false);
    _divider(b, '-');

    _urun(b, 'Kağıt Havlu 3\'lü',       1,  45.00);
    _urun(b, 'Doğal Maden Suyu 1L',     3,  12.50);
    _urun(b, 'Şeker 1 Kg',              2,  28.00);
    _urun(b, 'Çay 500gr Özel Karışım',  1,  65.00);
    _urun(b, 'Süt 1L Günlük Taze',      4,  18.00);
    _urun(b, 'Yoğurt 500gr',            2,  22.00);
    _urun(b, 'Ekmek Tam Buğday',        3,   8.50);
    _urun(b, 'Peynir Beyaz 250gr',      1,  54.00);
    _urun(b, 'Zeytin Sele 200gr',       1,  38.50);
    _divider(b, '-');

    // ── Toplamlar ──
    const ara   = 45.0 + 37.5 + 56.0 + 65.0 + 72.0 + 44.0 + 25.5 + 54.0 + 38.5;
    const kdv   = ara * 0.08;
    const genel = ara + kdv;
    const nakit = 500.0;
    const ustu  = nakit - genel;

    _satir(b, 'Ara Toplam', _fiyat(ara));
    _satir(b, 'KDV (%8)',   _fiyat(kdv));
    _divider(b, '-');
    _bold(b, true);
    _satir(b, 'GENEL TOPLAM', _fiyat(genel));
    _bold(b, false);
    _divider(b, '=');

    // ── Ödeme ──
    _satir(b, 'Nakit',     _fiyat(nakit));
    _satir(b, 'Para Üstü', _fiyat(ustu));
    _divider(b, '=');

    // ── Teşekkür ──
    _center(b);
    _bold(b, true);
    _txt(b, 'TEŞEKKÜR EDERİZ'); _nl(b);
    _bold(b, false);
    _txt(b, 'Yeni alışverişlerinizde'); _nl(b);
    _txt(b, 'görüşmek üzere!');         _nl(b);
    _divider(b, '=');

    _esc(b, [0x1B, 0x64, 0x05]); // 5 satır besle
    _esc(b, [0x1D, 0x56, 0x00]); // tam kesim
    return b;
  }

  /// Karakter haritası: 0x80–0xFF arası tüm byte'ları 8'erli gruplarla basar.
  /// ESC @ GÖNDERILMEZ — aktif kod sayfası ne ise onu gösterir.
  List<int> _buildCharMap() {
    final b = <int>[];
    // ESC t 13 aktif — t13 kod sayfasının tam tablosunu gösterir
    b.addAll([0x1B, 0x74, 0x0D]);

    _center(b);
    _bold(b, true);
    _txt(b, 'KARAKTER HARITASI'); _nl(b);
    _bold(b, false);
    _txt(b, 'ESC t 13 (PC857) tablosu'); _nl(b);
    _divider(b, '=');
    _left(b);

    // Her satırda 8 karakter, etiketi ile birlikte
    for (int start = 0x80; start <= 0xF8; start += 8) {
      // Hex etiket: "80: "
      final label = '${start.toRadixString(16).toUpperCase()}: ';
      b.addAll(label.codeUnits);

      // Karakterleri aralarında boşluk bırakarak yaz
      for (int code = start; code < start + 8 && code <= 0xFF; code++) {
        b.add(code);
        b.add(0x20); // boşluk
      }
      b.add(0x0A);
    }

    _divider(b, '=');
    _bold(b, true);
    _txt(b, 'DOGRULANMIS (t13):'); _nl(b);
    _bold(b, false);
    _txt(b, 'A6=G(breve)  A7=g(breve)'); _nl(b);
    _txt(b, '9F=s(cedilla) 8D=i(nokt)'); _nl(b);
    _txt(b, '98=I(nokta)   80=C  87=c'); _nl(b);
    _divider(b, '-');
    _bold(b, true);
    _txt(b, 'ARANAN: S-cedilla (buyuk S)'); _nl(b);
    _bold(b, false);
    _txt(b, 'DE satirinda hangi karakter?'); _nl(b);
    _txt(b, 'S-cedilla baska satirda mi?'); _nl(b);
    _divider(b, '=');

    _esc(b, [0x1B, 0x64, 0x04]);
    _esc(b, [0x1D, 0x56, 0x00]);
    return b;
  }

  /// ESC t 0..19 arasını tek tek dener, her satırda Ğ ğ ş ı İ Ş test eder.
  /// Hangi satırda "G g s i I S" gibi Türkçe karakter görünürse
  /// o satırdaki ESC t değeri PC857'dir.
  List<int> _buildCodePageScan() {
    final b = <int>[];
    // ESC @ YOK

    _center(b);
    _bold(b, true);
    b.addAll('KOD SAYFASI TARAMA'.codeUnits); _nl(b);
    _bold(b, false);
    b.addAll('ESC t 0-19 test'.codeUnits); _nl(b);
    b.addAll(List.filled(_kWidth, 0x3D)); _nl(b);

    _left(b);
    _bold(b, true);
    b.addAll('Beklenen sonuc:'.codeUnits); _nl(b);
    _bold(b, false);
    // PC857 byte değerlerini ASCII'de ne olması gerektiğini göster
    b.addAll('G(0xA6) g(0xA7) s(0x9F)'.codeUnits); _nl(b);
    b.addAll('i(0x8D) I(0x98) S(0xDE)'.codeUnits); _nl(b);
    b.addAll(List.filled(_kWidth, 0x2D)); _nl(b);

    // Test byte'ları: PC857'de Ğ ğ ş ı İ Ş olan konumlar
    const testBytes = [0xA6, 0xA7, 0x9F, 0x8D, 0x98, 0xDE];

    for (int cp = 0; cp <= 19; cp++) {
      b.addAll([0x1B, 0x74, cp]); // ESC t <değer>
      final label = 't${cp.toString().padLeft(2, '0')}: ';
      b.addAll(label.codeUnits);
      b.addAll(testBytes);
      b.add(0x20); // boşluk
      // Referans olarak mevcut char map'te gördüklerimizi de ekle
      b.addAll([0xAD, 0xB8]); // Bilinen Ş ş konumları
      _nl(b);
    }

    b.addAll(List.filled(_kWidth, 0x3D)); _nl(b);
    b.addAll('Dogru Turkce goren satirin'.codeUnits); _nl(b);
    b.addAll('numarasini bildirin!'.codeUnits); _nl(b);
    b.addAll(List.filled(_kWidth, 0x3D)); _nl(b);

    _esc(b, [0x1B, 0x64, 0x04]);
    _esc(b, [0x1D, 0x56, 0x00]);
    return b;
  }

  // ── Dışarıdan kullanım ─────────────────────────────────────────────────────

  List<int> buildSatisFisi({
    required String belgeno,
    required String cariAd,
    required String kasiyerAd,
    required String subeAd,
    required List<FisKalem> kalemler,
    required double toplamTutar,
    required double kdv,
    double? nakit,
    double? krediKarti,
  }) {
    final b = <int>[];
    final now = DateTime.now();

    // ESC t 13 = PC857 Turkish (ESC @ YOK)
    _esc(b, [0x1B, 0x74, 0x0D]);

    _center(b);
    _bold(b, true); _size(b, big: true);
    _txt(b, 'FilERP'); _nl(b);
    _size(b, big: false);
    _txt(b, 'Satış Fişi'); _nl(b);
    _bold(b, false);
    _divider(b, '=');

    _left(b);
    _txt(b, 'Belge No : $belgeno'); _nl(b);
    _txt(b, 'Tarih    : ${_p2(now.day)}.${_p2(now.month)}.${now.year}'); _nl(b);
    _txt(b, 'Saat     : ${_p2(now.hour)}:${_p2(now.minute)}:${_p2(now.second)}'); _nl(b);
    _txt(b, 'Şube     : $subeAd');   _nl(b);
    _txt(b, 'Kasiyer  : $kasiyerAd'); _nl(b);
    if (cariAd.isNotEmpty) { _txt(b, 'Cari     : $cariAd'); _nl(b); }
    _divider(b, '-');

    _bold(b, true); _txt(b, 'Ürün'); _nl(b); _bold(b, false);
    _divider(b, '-');

    for (final k in kalemler) {
      _urun(b, k.ad, k.miktar.toInt(), k.birimFiyat, miktar: k.miktar);
    }

    _divider(b, '-');
    _satir(b, 'Ara Toplam', _fiyat(toplamTutar - kdv));
    _satir(b, 'KDV',        _fiyat(kdv));
    _divider(b, '-');
    _bold(b, true);
    _satir(b, 'TOPLAM', _fiyat(toplamTutar));
    _bold(b, false);
    _divider(b, '=');

    if (nakit != null && nakit > 0) {
      _satir(b, 'Nakit', _fiyat(nakit));
      if (nakit > toplamTutar) _satir(b, 'Para Üstü', _fiyat(nakit - toplamTutar));
    }
    if (krediKarti != null && krediKarti > 0) {
      _satir(b, 'Kredi Kartı', _fiyat(krediKarti));
    }
    _divider(b, '=');
    _center(b);
    _bold(b, true); _txt(b, 'TEŞEKKÜR EDERİZ'); _nl(b); _bold(b, false);
    _divider(b, '=');

    _esc(b, [0x1B, 0x64, 0x05]);
    _esc(b, [0x1D, 0x56, 0x00]);
    return b;
  }

  /// Z Raporu (kasa tahsilat/ödeme özeti) fişi.
  /// [satirGenisligi]: Yazıcı Ayarları > Kağıt Eni'nden hesaplanan karakter
  /// genişliği (58mm→32, 80mm→48 vb.). Verilmezse varsayılan (32) kullanılır.
  List<int> buildZRaporuFisi({
    required String kasaAd,
    required DateTime tarih1,
    required DateTime tarih2,
    required double toplamTahsilat,
    required double toplamOdeme,
    List<ZRaporuSatir> satirlar = const [],
    int? satirGenisligi,
    String? kullaniciAdi,
  }) {
    final kw = satirGenisligi ?? _kWidth;
    final b = <int>[];
    final now = DateTime.now();

    _esc(b, [0x1B, 0x74, 0x0D]);

    _center(b);
    _bold(b, true); _size(b, big: true);
    _txt(b, 'FilERP'); _nl(b);
    _size(b, big: false);
    _txt(b, 'Z RAPORU'); _nl(b);
    _bold(b, false);
    _divider(b, '=', width: kw);

    _left(b);
    _txt(b, 'Kasa    : $kasaAd'); _nl(b);
    _txt(b, 'Aralık  : ${_p2(tarih1.day)}.${_p2(tarih1.month)}.${tarih1.year} - ${_p2(tarih2.day)}.${_p2(tarih2.month)}.${tarih2.year}'); _nl(b);
    _txt(b, 'Basım   : ${_p2(now.day)}.${_p2(now.month)}.${now.year} ${_p2(now.hour)}:${_p2(now.minute)}'); _nl(b);
    if (kullaniciAdi != null && kullaniciAdi.isNotEmpty) {
      _txt(b, 'Kullanıcı: $kullaniciAdi'); _nl(b);
    }
    _divider(b, '-', width: kw);

    if (satirlar.isNotEmpty) {
      _bold(b, true); _txt(b, 'İşlemler'); _nl(b); _bold(b, false);
      _divider(b, '-', width: kw);
      for (var i = 0; i < satirlar.length; i++) {
        final s = satirlar[i];
        _txt(b, '${_p2(s.tarih.day)}.${_p2(s.tarih.month)}.${s.tarih.year}  ${s.yon}'); _nl(b);
        final adTrunc = s.aciklama.length > kw ? s.aciklama.substring(0, kw) : s.aciklama;
        if (adTrunc.isNotEmpty) { _txt(b, adTrunc); _nl(b); }
        _satir(b, s.yon == 'TAHSİL' ? '  Tahsilat' : '  Ödeme', _fiyat(s.tutar), width: kw);
        if (i < satirlar.length - 1) _divider(b, '-', width: kw);
      }
      _divider(b, '=', width: kw);
    }

    _bold(b, true);
    _satir(b, 'Toplam Tahsilat', _fiyat(toplamTahsilat), width: kw);
    _satir(b, 'Toplam Ödeme', _fiyat(toplamOdeme), width: kw);
    _divider(b, '-', width: kw);
    _satir(b, 'Net', _fiyat(toplamTahsilat - toplamOdeme), width: kw);
    _bold(b, false);
    _divider(b, '=', width: kw);

    _esc(b, [0x1B, 0x64, 0x05]);
    _esc(b, [0x1D, 0x56, 0x00]);
    return b;
  }

  /// Malzeme Ambar Durum Raporu fişi.
  /// [satirGenisligi]: Yazıcı Ayarları > Kağıt Eni'nden hesaplanan karakter
  /// genişliği (58mm→32, 80mm→48 vb.). Verilmezse varsayılan (32) kullanılır.
  List<int> buildAmbarDurumFisi({
    required String depoAd,
    required DateTime tarih1,
    required DateTime tarih2,
    required List<AmbarDurumSatir> satirlar,
    int? satirGenisligi,
    String? kullaniciAdi,
  }) {
    final kw = satirGenisligi ?? _kWidth;
    final b = <int>[];
    final now = DateTime.now();

    // ESC t 13 = PC857 Turkish (ESC @ YOK)
    _esc(b, [0x1B, 0x74, 0x0D]);

    _center(b);
    _bold(b, true); _size(b, big: true);
    _txt(b, 'FilERP'); _nl(b);
    _size(b, big: false);
    _txt(b, 'Malzeme Ambar Durum Raporu'); _nl(b);
    _bold(b, false);
    _divider(b, '=', width: kw);

    _left(b);
    _txt(b, 'Depo    : $depoAd'); _nl(b);
    _txt(b, 'Aralık  : ${_p2(tarih1.day)}.${_p2(tarih1.month)}.${tarih1.year} - ${_p2(tarih2.day)}.${_p2(tarih2.month)}.${tarih2.year}'); _nl(b);
    _txt(b, 'Basım   : ${_p2(now.day)}.${_p2(now.month)}.${now.year} ${_p2(now.hour)}:${_p2(now.minute)}'); _nl(b);
    if (kullaniciAdi != null && kullaniciAdi.isNotEmpty) {
      _txt(b, 'Kullanıcı: $kullaniciAdi'); _nl(b);
    }
    _divider(b, '-', width: kw);

    _bold(b, true); _txt(b, 'Malzeme'); _nl(b); _bold(b, false);
    _divider(b, '-', width: kw);

    for (var i = 0; i < satirlar.length; i++) {
      final s = satirlar[i];
      final name = s.ad.length > kw ? s.ad.substring(0, kw) : s.ad;
      _txt(b, name); _nl(b);
      final satir = 'G:${_miktar(s.giris)}  C:${_miktar(s.cikis)}  K:${_miktar(s.kalan)} ${s.olcubr}';
      _txt(b, satir); _nl(b);
      if (i < satirlar.length - 1) _divider(b, '-', width: kw);
    }

    _divider(b, '=', width: kw);
    _bold(b, true);
    _satir(b, 'Toplam Giriş', _miktar(satirlar.fold(0.0, (s, e) => s + e.giris)), width: kw);
    _satir(b, 'Toplam Çıkış', _miktar(satirlar.fold(0.0, (s, e) => s + e.cikis)), width: kw);
    _bold(b, false);
    _divider(b, '=', width: kw);

    _esc(b, [0x1B, 0x64, 0x05]);
    _esc(b, [0x1D, 0x56, 0x00]);
    return b;
  }

  /// Araç Yükleme teslim fişi — "şu ürünler şu depoya şu plasiyerde teslim
  /// edildi" bilgisini basar.
  /// [satirGenisligi]: Yazıcı Ayarları > Kağıt Eni'nden hesaplanan karakter
  /// genişliği (58mm→32, 80mm→48 vb.). Verilmezse varsayılan (32) kullanılır.
  List<int> buildAracYuklemeFisi({
    required String belgeNo,
    required DateTime tarih,
    required String depoAd,
    required String plasiyerAd,
    required List<AracYuklemeSatir> satirlar,
    int? satirGenisligi,
    String? kullaniciAdi,
  }) {
    final kw = satirGenisligi ?? _kWidth;
    final b = <int>[];
    final now = DateTime.now();

    _esc(b, [0x1B, 0x74, 0x0D]);

    _center(b);
    _bold(b, true); _size(b, big: true);
    _txt(b, 'FilERP'); _nl(b);
    _size(b, big: false);
    _txt(b, 'ARAÇ YÜKLEME TESLİM FİŞİ'); _nl(b);
    _bold(b, false);
    _divider(b, '=', width: kw);

    _left(b);
    _txt(b, 'Belge No : $belgeNo'); _nl(b);
    _txt(b, 'Tarih    : ${_p2(tarih.day)}.${_p2(tarih.month)}.${tarih.year}'); _nl(b);
    _txt(b, 'Depo     : $depoAd'); _nl(b);
    _txt(b, 'Plasiyer : $plasiyerAd'); _nl(b);
    _txt(b, 'Basım    : ${_p2(now.day)}.${_p2(now.month)}.${now.year} ${_p2(now.hour)}:${_p2(now.minute)}'); _nl(b);
    if (kullaniciAdi != null && kullaniciAdi.isNotEmpty) {
      _txt(b, 'Kullanıcı: $kullaniciAdi'); _nl(b);
    }
    _divider(b, '-', width: kw);

    _bold(b, true); _txt(b, 'Ürünler'); _nl(b); _bold(b, false);
    _divider(b, '-', width: kw);

    for (var i = 0; i < satirlar.length; i++) {
      final s = satirlar[i];
      final name = s.ad.length > kw ? s.ad.substring(0, kw) : s.ad;
      _txt(b, name); _nl(b);
      _satir(b, '  Miktar', '${_miktar(s.miktar)} ${s.olcubr}', width: kw);
      if (i < satirlar.length - 1) _divider(b, '-', width: kw);
    }

    _divider(b, '=', width: kw);
    _bold(b, true);
    _satir(b, 'Toplam Kalem', '${satirlar.length}', width: kw);
    _bold(b, false);
    _divider(b, '=', width: kw);

    _esc(b, [0x1B, 0x64, 0x05]);
    _esc(b, [0x1D, 0x56, 0x00]);
    return b;
  }

  /// [buildAracYuklemeFisi] ile AYNI içeriğin düz metin hali — ekranda önizleme için.
  /// (Yazıcıdan çıkan fişle birebir aynı satırlar; yazıcı bağlı olmasa da üretilebilir.)
  List<String> buildAracYuklemeFisiMetin({
    required String belgeNo,
    required DateTime tarih,
    required String depoAd,
    required String plasiyerAd,
    required List<AracYuklemeSatir> satirlar,
    int? satirGenisligi,
    String? kullaniciAdi,
  }) {
    final kw = satirGenisligi ?? _kWidth;
    final now = DateTime.now();
    String ortala(String s) => s.length >= kw ? s : '${' ' * ((kw - s.length) ~/ 2)}$s';
    String cizgi(String ch) => ch * kw;
    String satir(String l, String r) {
      final pad = kw - l.length - r.length;
      return l + (' ' * (pad > 1 ? pad : 1)) + r;
    }

    final l = <String>[
      ortala('FilERP'),
      ortala('ARAÇ YÜKLEME TESLİM FİŞİ'),
      cizgi('='),
      'Belge No : $belgeNo',
      'Tarih    : ${_p2(tarih.day)}.${_p2(tarih.month)}.${tarih.year}',
      'Depo     : $depoAd',
      'Plasiyer : $plasiyerAd',
      'Basım    : ${_p2(now.day)}.${_p2(now.month)}.${now.year} ${_p2(now.hour)}:${_p2(now.minute)}',
      if (kullaniciAdi != null && kullaniciAdi.isNotEmpty) 'Kullanıcı: $kullaniciAdi',
      cizgi('-'),
      'Ürünler',
      cizgi('-'),
    ];
    for (var i = 0; i < satirlar.length; i++) {
      final s = satirlar[i];
      l.add(s.ad.length > kw ? s.ad.substring(0, kw) : s.ad);
      l.add(satir('  Miktar', '${_miktar(s.miktar)} ${s.olcubr}'));
      if (i < satirlar.length - 1) l.add(cizgi('-'));
    }
    l
      ..add(cizgi('='))
      ..add(satir('Toplam Kalem', '${satirlar.length}'))
      ..add(cizgi('='));
    return l;
  }

  /// Hazır [FisSatir] listesini yazdırır (rapor fişleri için genel amaçlı).
  /// Satırlar çağıran tarafta kağıt genişliğine göre ([FisBicim]) hazırlanır.
  List<int> buildSatirlarFisi(List<FisSatir> satirlar) {
    final b = <int>[];
    _esc(b, [0x1B, 0x74, 0x0D]);
    for (final s in satirlar) {
      if (s.ortali) {
        _center(b);
      } else {
        _left(b);
      }
      _bold(b, s.kalin);
      _size(b, big: s.buyuk);
      _txt(b, s.metin);
      _nl(b);
    }
    _size(b, big: false);
    _bold(b, false);
    _left(b);
    _esc(b, [0x1B, 0x64, 0x05]);
    _esc(b, [0x1D, 0x56, 0x00]);
    return b;
  }

  /// Satış Faturası fişi.
  /// [satirGenisligi]: Yazıcı Ayarları > Kağıt Eni'nden hesaplanan karakter
  /// genişliği (58mm→32, 80mm→48 vb.). Verilmezse varsayılan (32) kullanılır.
  List<int> buildFaturaFisi({
    required String belgeNo,
    required DateTime tarih,
    required String cariAd,
    String? plasiyerAd,
    required List<FaturaFisKalem> kalemler,
    required double araToplam,
    required double kdvToplam,
    required double genelToplam,
    int? satirGenisligi,
    String? kullaniciAdi,
  }) {
    final kw = satirGenisligi ?? _kWidth;
    final b = <int>[];
    final now = DateTime.now();

    _esc(b, [0x1B, 0x74, 0x0D]);

    _center(b);
    _bold(b, true); _size(b, big: true);
    _txt(b, 'FilERP'); _nl(b);
    _size(b, big: false);
    _txt(b, 'SATIŞ FATURASI'); _nl(b);
    _bold(b, false);
    _divider(b, '=', width: kw);

    _left(b);
    _txt(b, 'Belge No : $belgeNo'); _nl(b);
    _txt(b, 'Tarih    : ${_p2(tarih.day)}.${_p2(tarih.month)}.${tarih.year}'); _nl(b);
    _txt(b, 'Cari     : $cariAd'); _nl(b);
    if (plasiyerAd != null && plasiyerAd.isNotEmpty) {
      _txt(b, 'Plasiyer : $plasiyerAd'); _nl(b);
    }
    _txt(b, 'Basım    : ${_p2(now.day)}.${_p2(now.month)}.${now.year} ${_p2(now.hour)}:${_p2(now.minute)}'); _nl(b);
    if (kullaniciAdi != null && kullaniciAdi.isNotEmpty) {
      _txt(b, 'Kullanıcı: $kullaniciAdi'); _nl(b);
    }
    _divider(b, '-', width: kw);

    _bold(b, true); _txt(b, 'Ürünler'); _nl(b); _bold(b, false);
    _divider(b, '-', width: kw);

    for (var i = 0; i < kalemler.length; i++) {
      final k = kalemler[i];
      final name = k.ad.length > kw ? k.ad.substring(0, kw) : k.ad;
      _txt(b, name); _nl(b);
      final sol = '  ${_miktar(k.miktar)} x ${_fiyat(k.birimFiyat)}';
      final sag = '${_fiyat(k.miktar * k.birimFiyat)} TL';
      final pad = kw - sol.length - sag.length;
      _txt(b, sol + (' ' * (pad > 1 ? pad : 1)) + sag); _nl(b);
      if (i < kalemler.length - 1) _divider(b, '-', width: kw);
    }

    _divider(b, '=', width: kw);
    _satir(b, 'Ara Toplam', _fiyat(araToplam), width: kw);
    _satir(b, 'KDV', _fiyat(kdvToplam), width: kw);
    _divider(b, '-', width: kw);
    _bold(b, true);
    _satir(b, 'GENEL TOPLAM', _fiyat(genelToplam), width: kw);
    _bold(b, false);
    _divider(b, '=', width: kw);

    _esc(b, [0x1B, 0x64, 0x05]);
    _esc(b, [0x1D, 0x56, 0x00]);
    return b;
  }

  /// Satış İrsaliyesi fişi.
  /// [satirGenisligi]: Yazıcı Ayarları > Kağıt Eni'nden hesaplanan karakter
  /// genişliği (58mm→32, 80mm→48 vb.). Verilmezse varsayılan (32) kullanılır.
  List<int> buildIrsaliyeFisi({
    required String belgeNo,
    required DateTime tarih,
    required String cariAd,
    String? plasiyerAd,
    required List<IrsaliyeFisKalem> kalemler,
    int? satirGenisligi,
    String? kullaniciAdi,
  }) {
    final kw = satirGenisligi ?? _kWidth;
    final b = <int>[];
    final now = DateTime.now();

    _esc(b, [0x1B, 0x74, 0x0D]);

    _center(b);
    _bold(b, true); _size(b, big: true);
    _txt(b, 'FilERP'); _nl(b);
    _size(b, big: false);
    _txt(b, 'SATIŞ İRSALİYESİ'); _nl(b);
    _bold(b, false);
    _divider(b, '=', width: kw);

    _left(b);
    _txt(b, 'Belge No : $belgeNo'); _nl(b);
    _txt(b, 'Tarih    : ${_p2(tarih.day)}.${_p2(tarih.month)}.${tarih.year}'); _nl(b);
    _txt(b, 'Cari     : $cariAd'); _nl(b);
    if (plasiyerAd != null && plasiyerAd.isNotEmpty) {
      _txt(b, 'Plasiyer : $plasiyerAd'); _nl(b);
    }
    _txt(b, 'Basım    : ${_p2(now.day)}.${_p2(now.month)}.${now.year} ${_p2(now.hour)}:${_p2(now.minute)}'); _nl(b);
    if (kullaniciAdi != null && kullaniciAdi.isNotEmpty) {
      _txt(b, 'Kullanıcı: $kullaniciAdi'); _nl(b);
    }
    _divider(b, '-', width: kw);

    _bold(b, true); _txt(b, 'Ürünler'); _nl(b); _bold(b, false);
    _divider(b, '-', width: kw);

    for (var i = 0; i < kalemler.length; i++) {
      final k = kalemler[i];
      final name = k.ad.length > kw ? k.ad.substring(0, kw) : k.ad;
      _txt(b, name); _nl(b);
      _satir(b, '  Miktar', '${_miktar(k.miktar)} ${k.olcubr}', width: kw);
      if (i < kalemler.length - 1) _divider(b, '-', width: kw);
    }

    _divider(b, '=', width: kw);
    _bold(b, true);
    _satir(b, 'Toplam Kalem', '${kalemler.length}', width: kw);
    _bold(b, false);
    _divider(b, '=', width: kw);

    _esc(b, [0x1B, 0x64, 0x05]);
    _esc(b, [0x1D, 0x56, 0x00]);
    return b;
  }

  String _miktar(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    var ip = parts[0];
    if (ip.length > 3) {
      ip = '${ip.substring(0, ip.length - 3)}.${ip.substring(ip.length - 3)}';
    }
    return '$ip,${parts[1]}';
  }

  // ── ESC/POS düşük seviye ───────────────────────────────────────────────────

  void _esc(List<int> b, List<int> cmd) => b.addAll(cmd);
  void _nl(List<int> b)  => b.add(0x0A);
  void _center(List<int> b) => b.addAll([0x1B, 0x61, 0x01]);
  void _left(List<int> b)   => b.addAll([0x1B, 0x61, 0x00]);
  void _bold(List<int> b, bool on) => b.addAll([0x1B, 0x45, on ? 0x01 : 0x00]);
  void _size(List<int> b, {required bool big}) =>
      b.addAll([0x1D, 0x21, big ? 0x11 : 0x00]);

  void _divider(List<int> b, String ch, {int? width}) {
    b.addAll(List.filled(width ?? _kWidth, ch.codeUnitAt(0)));
    b.add(0x0A);
  }

  void _txt(List<int> b, String text) => b.addAll(_cp857(text));

  void _urun(List<int> b, String ad, int adet, double fiyat, {double? miktar}) {
    final qty   = miktar ?? adet.toDouble();
    final total = qty * fiyat;
    final name  = ad.length > _kWidth ? ad.substring(0, _kWidth) : ad;
    _txt(b, name); _nl(b);

    final left  = '  $adet Ad x ${_fiyat(fiyat)}';
    final right = '${_fiyat(total)} TL';
    final pad   = _kWidth - left.length - right.length;
    _txt(b, left + (' ' * (pad > 1 ? pad : 1)) + right);
    _nl(b);
  }

  void _satir(List<int> b, String label, String value, {int? width}) {
    final kw  = width ?? _kWidth;
    final pad = kw - label.length - value.length;
    _txt(b, label + (' ' * (pad > 1 ? pad : 1)) + value);
    _nl(b);
  }

  String _p2(int v) => v.toString().padLeft(2, '0');

  String _fiyat(double v) {
    final s     = v.toStringAsFixed(2);
    final parts = s.split('.');
    var   ip    = parts[0];
    if (ip.length > 3) {
      ip = '${ip.substring(0, ip.length - 3)}.${ip.substring(ip.length - 3)}';
    }
    return '$ip,${parts[1]}';
  }

  // ── Karakter dönüşüm tablosu — PC857 (ESC t 13) ─────────────────────────
  //
  // Doğrulama tarihi: 2026-06-05 (kod sayfası tarama testi)
  //
  //  ESC t 13 (0x0D) = PC857 Turkish ile test edildi:
  //  ✅ DOĞRULANDI: ğ=0xA7  ş=0x9F  ı=0x8D  İ=0x98
  //  ✅ ORTAK (CP852∩PC857): Ç=0x80  ü=0x81  ç=0x87  ö=0x94  Ö=0x99  Ü=0x9A
  //  ✅ DOĞRULANDI: Ş=0xAD  ş=0x9F  (0xAD t13+t18+fabrika modda ortak)

  List<int> _cp857(String text) {
    final out = <int>[];
    for (final r in text.runes) {
      switch (r) {
        case 0x00C7: out.add(0x80); break; // Ç ✅
        case 0x00FC: out.add(0x81); break; // ü ✅
        case 0x00E7: out.add(0x87); break; // ç ✅
        case 0x00F6: out.add(0x94); break; // ö ✅
        case 0x00D6: out.add(0x99); break; // Ö ✅
        case 0x00DC: out.add(0x9A); break; // Ü ✅
        case 0x011F: out.add(0xA7); break; // ğ ✅ t13 scan
        case 0x015F: out.add(0x9F); break; // ş ✅ t13: 0x9F
        case 0x0131: out.add(0x8D); break; // ı ✅ t13: 0x8D
        case 0x0130: out.add(0x98); break; // İ ✅ t13: 0x98
        case 0x011E: out.add(0xA6); break; // Ğ ✅ t13: 0xA6
        // Ş: t13'te yok → t18'e geç (0xB8=Ş), sonra t13'e dön
        case 0x015E:
          out.addAll([0x1B, 0x74, 0x12]); // ESC t 18 (CP852: 0xB8=Ş)
          out.add(0xB8);
          out.addAll([0x1B, 0x74, 0x0D]); // ESC t 13'e geri dön
          break;
        default:
          out.add(r < 0x80 ? r : 0x3F);
      }
    }
    return out;
  }
}

/// Z Raporu satırı (buildZRaporuFisi için)
class ZRaporuSatir {
  final DateTime tarih;
  final String yon; // 'TAHSİL' | 'ÖDEME'
  final String aciklama;
  final double tutar;
  const ZRaporuSatir({required this.tarih, required this.yon, required this.aciklama, required this.tutar});
}

/// Fiş kalemi (buildSatisFisi için)
class FisKalem {
  final String ad;
  final double miktar;
  final double birimFiyat;
  const FisKalem({required this.ad, required this.miktar, required this.birimFiyat});
}

/// Fatura fiş kalemi (buildFaturaFisi için)
class FaturaFisKalem {
  final String ad;
  final double miktar;
  final double birimFiyat;
  const FaturaFisKalem({required this.ad, required this.miktar, required this.birimFiyat});
}

/// İrsaliye fiş kalemi (buildIrsaliyeFisi için)
class IrsaliyeFisKalem {
  final String ad;
  final double miktar;
  final String olcubr;
  const IrsaliyeFisKalem({required this.ad, required this.miktar, required this.olcubr});
}

/// Araç yükleme fiş satırı (buildAracYuklemeFisi için)
class AracYuklemeSatir {
  final String ad;
  final double miktar;
  final String olcubr;
  const AracYuklemeSatir({required this.ad, required this.miktar, required this.olcubr});
}

/// Malzeme ambar durum satırı (buildAmbarDurumFisi için)
class AmbarDurumSatir {
  final String ad;
  final double giris;
  final double cikis;
  final double kalan;
  final String olcubr;
  const AmbarDurumSatir({required this.ad, required this.giris, required this.cikis, required this.kalan, required this.olcubr});
}
