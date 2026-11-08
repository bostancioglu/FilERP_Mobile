class BankaIslemtipiCouples {
  const BankaIslemtipiCouples._();

  static const List<_BankaCouple> _list = [
    _BankaCouple(1, 'Havale / EFT'),
    _BankaCouple(2, 'Hesap Virman'),
    _BankaCouple(3, 'Banka Virman'),
    _BankaCouple(4, 'Devir'),
    _BankaCouple(5, 'Muhtelif'),
    _BankaCouple(6, 'Tahsilat'),
    _BankaCouple(7, 'Ödeme'),
    _BankaCouple(8, 'Masraf'),
  ];

  static List<_BankaCouple> get list => _list;

  static String adByValue(int? val) {
    if (val == null) return '';
    return _list
        .firstWhere((e) => e.value == val,
            orElse: () => const _BankaCouple(0, ''))
        .text;
  }
}

class BankaHesaptipiCouples {
  const BankaHesaptipiCouples._();

  static const List<_BankaCouple> _list = [
    _BankaCouple(1, 'Vadesiz Mevduat'),
    _BankaCouple(2, 'Vadeli Mevduat'),
    _BankaCouple(3, 'Spot Kredi'),
    _BankaCouple(4, 'Teminat Senedi'),
    _BankaCouple(5, 'Tahsilat Senetleri'),
    _BankaCouple(6, 'Rotatif'),
    _BankaCouple(7, 'Nakit Kredi (Spot)'),
    _BankaCouple(8, 'İskonto'),
    _BankaCouple(9, 'TM Teminat Mektubu'),
    _BankaCouple(10, 'Harici Garanti'),
    _BankaCouple(11, 'İthalat Akreditifi'),
    _BankaCouple(12, 'Kabul ve Aval'),
    _BankaCouple(13, 'Uzun/Orta Vadeli Kredi'),
    _BankaCouple(14, 'Repo'),
    _BankaCouple(15, 'Teminat Çeki'),
    _BankaCouple(16, 'Tahsil Çekleri'),
    _BankaCouple(17, 'Taksitli Kredi'),
    _BankaCouple(18, 'Kredi Kartı'),
    _BankaCouple(19, 'Borç Çekleri'),
    _BankaCouple(20, 'Borç Senetleri'),
    _BankaCouple(21, 'Firma Kredi Kartı'),
    _BankaCouple(22, 'Fon Hesabı'),
  ];

  static List<_BankaCouple> get list => _list;

  static String adByValue(int? val) {
    if (val == null) return '';
    return _list
        .firstWhere((e) => e.value == val,
            orElse: () => const _BankaCouple(0, ''))
        .text;
  }
}

// Muhasebe hesap planı tur değerleri — hem kasa hem banka tanım sayfalarında kullanılır.
class HesapplaniTuruCouples {
  const HesapplaniTuruCouples._();

  static const List<_BankaCouple> _list = [
    _BankaCouple(1, 'Bilanço Ana'),
    _BankaCouple(2, 'Bilanço Grup'),
    _BankaCouple(3, 'Ana'),
    _BankaCouple(4, 'Grup'),
    _BankaCouple(5, 'Muavin'),
  ];

  static String adByValue(int? val) {
    if (val == null) return '?';
    return _list
        .firstWhere((e) => e.value == val,
            orElse: () => const _BankaCouple(0, '?'))
        .text;
  }
}

class _BankaCouple {
  final int value;
  final String text;
  const _BankaCouple(this.value, this.text);
}
