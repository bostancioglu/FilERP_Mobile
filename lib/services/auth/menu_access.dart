import 'authorization_session.dart';
import 'backend_authorization_catalog.dart';

class MenuAccess {
  static String normalize(String text) => text
      .replaceAll('İ', 'i')
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u');

  static List<int> modules(String label, {String parent = ''}) {
    final s = normalize(label), context = normalize('$parent $label');
    if (s.contains('ayar') ||
        s.contains('yazici') ||
        s == 'tema' ||
        s == 'nfc' ||
        s == 'cikis') return [-1];
    if (s == 'fatura') return [301, 302];
    if (s == 'irsaliye') return [501, 502];
    if (s == 'siparis') return [401, 402];
    if (s == 'teklif') return [601, 602];
    if (s == 'finans')
      return [
        ...modules('Kasa'),
        ...modules('Banka'),
        ...modules('Çek'),
        ...modules('Senet'),
        1025,
      ];
    if (s == 'depo') return [801];
    if (s.contains('arac yukl') || s == 'dat' || s.contains('transfer'))
      return [801];
    if (s.contains('ambar')) return [1301];
    if (s.contains('konum')) return [3];
    if (s.contains('plasiyer') || s.contains('gunluk ozet'))
      return [5101, 5103];
    if (s.contains('z rapor')) return [5031, 5101];
    if (s.contains('rapor merkezi') || s == 'raporlama' || s == 'raporlar')
      return reportModules;
    if (s.contains('cek') && s.contains('senet'))
      return [5032, 5050, 5051, 5058];
    if (s == 'cek')
      return [
        1005,
        1006,
        1007,
        1009,
        1010,
        1011,
        1012,
        1013,
        1014,
        5032,
        5033,
        5034,
        5035,
        5036,
        5037,
        5038,
        5050
      ];
    if (s == 'senet')
      return [
        1015,
        1016,
        1017,
        1018,
        1019,
        1020,
        1021,
        1022,
        1023,
        5051,
        5052,
        5053,
        5054,
        5055,
        5056,
        5057,
        5058
      ];
    if (context.contains('cek') || context.contains('senet')) {
      final senet = context.contains('senet'), borc = context.contains('borc');
      if (s.contains('rapor') || normalize(parent).contains('rapor')) {
        if (borc) {
          if (s.contains('raporlari'))
            return [senet ? 5058 : 5050, senet ? 5057 : 5038];
          return [
            s.contains('odenecek')
                ? (senet ? 5057 : 5038)
                : (senet ? 5058 : 5050)
          ];
        }
        final base = senet ? 5051 : 5032;
        if (s.contains('raporlari')) return List.generate(6, (i) => base + i);
        if (s.contains('portfoy')) return [base + 1];
        if (s.contains('protesto') || s.contains('karsiliksiz'))
          return [base + 2];
        if (s.contains('tahsil')) return [base + 3];
        if (s.contains('teminat')) return [base + 4];
        if (s.contains('ciro') || s.contains('verilen')) return [base + 5];
        return [base];
      }
      if (s.contains('ciro')) return [senet ? 1016 : 1006];
      if (s.contains('portfoyden')) return [senet ? 1020 : 1011];
      if (s.contains('tahsil')) return [senet ? 1017 : 1007];
      if (s.contains('protesto')) return [senet ? 1018 : 1009];
      if (s.contains('iade'))
        return [senet ? (borc ? 1023 : 1019) : (borc ? 1014 : 1010)];
      if (s.contains('odeme')) return [senet ? 1022 : 1013];
      return [senet ? (borc ? 1021 : 1015) : (borc ? 1012 : 1005)];
    }
    if (s.contains('cari')) {
      if (s.contains('borc') || s.contains('alacak') || s.contains('bakiye'))
        return [6001];
      if (s.contains('ekstre') || s.contains('hareket')) return [6000];
      if (s.contains('vade')) return [202];
      return [201];
    }
    if (s.contains('stok')) {
      if (s.contains('hareket')) return [5001];
      if (s.contains('bakiye') || s.contains('durum')) return [5002, 6002];
      return [101];
    }
    if (s.contains('fatura')) {
      if (s.contains('detay')) return [5044, 5047];
      if (s.contains('icmal')) return [5045, 5048];
      return [s.contains('alis') ? 302 : 301];
    }
    if (s.contains('irsaliye')) return [s.contains('alis') ? 502 : 501];
    if (s.contains('siparis')) return [s.contains('alis') ? 402 : 401];
    if (s.contains('teklif')) return [s.contains('alis') ? 602 : 601];
    if (s.contains('tahsilat')) return [1025];
    if (s.contains('kasa') || normalize(parent) == 'kasa') {
      if (s.contains('rapor') || s.contains('genel durum')) return [5031];
      if (s == 'kasa') return [1001, 1003, 5031];
      return [s.contains('tanim') ? 1001 : 1003];
    }
    if (s.contains('banka') || normalize(parent) == 'banka') {
      if (s.contains('rapor') || s.contains('genel durum')) return [5030];
      if (s == 'banka') return [1002, 1004, 5030];
      return [s.contains('tanim') ? 1002 : 1004];
    }
    return []; // Unmapped business menus are hidden until mapped explicitly.
  }

  static List<int> get reportModules => [
        ...sharedModuleIds.values.where((id) => id >= 5000),
        3,
      ];
  static bool visible(String label, {String parent = ''}) =>
      AuthorizationSession.instance.any(modules(label, parent: parent));
  static bool readable(String label, {String parent = ''}) =>
      AuthorizationSession.instance
          .any(modules(label, parent: parent), Access.read);
}
