/// Çek modülü sabitleri — C# BelgeDurumCouple / EvrakDurumCouple / EvrakYeriCouple / CiroTuruCouple enum'larına birebir karşılık gelir.
class BelgeDurumCouples {
  const BelgeDurumCouples._();

  static const List<_CekCouple> _list = [
    _CekCouple(0, 'Taslak'),
    _CekCouple(1, 'Tamamlandı'),
  ];

  static List<_CekCouple> get list => _list;

  static String adByValue(int? val) {
    if (val == null) return '';
    return _list.firstWhere((e) => e.value == val, orElse: () => const _CekCouple(0, '')).text;
  }
}

class EvrakDurumCouples {
  const EvrakDurumCouples._();

  static const List<_CekCouple> _list = [
    _CekCouple(1, 'Beklemede'),
    _CekCouple(2, 'Ödendi'),
    _CekCouple(3, 'Ertelendi'),
    _CekCouple(4, 'Karşılıksız'),
    _CekCouple(5, 'İade'),
    _CekCouple(6, 'Kısmi Ödeme'),
  ];

  static List<_CekCouple> get list => _list;

  static String adByValue(int? val) {
    if (val == null) return '';
    return _list.firstWhere((e) => e.value == val, orElse: () => const _CekCouple(0, '')).text;
  }
}

class EvrakYeriCouples {
  const EvrakYeriCouples._();

  static const List<_CekCouple> _list = [
    _CekCouple(1, 'Portföy'),
    _CekCouple(2, 'Tahsil'),
    _CekCouple(3, 'Teminat'),
    _CekCouple(4, 'Ciro'),
    _CekCouple(5, 'İade'),
    _CekCouple(6, 'Avukat'),
  ];

  static List<_CekCouple> get list => _list;

  static String adByValue(int? val) {
    if (val == null) return '';
    return _list.firstWhere((e) => e.value == val, orElse: () => const _CekCouple(0, '')).text;
  }
}

class CiroTuruCouples {
  const CiroTuruCouples._();

  static const List<_CekCouple> _list = [
    _CekCouple(1, 'Cariye'),
    _CekCouple(2, 'Bankaya Tahsile'),
    _CekCouple(3, 'Bankaya Teminata'),
  ];

  static List<_CekCouple> get list => _list;

  static String adByValue(int? val) {
    if (val == null) return '';
    return _list.firstWhere((e) => e.value == val, orElse: () => const _CekCouple(0, '')).text;
  }
}

/// Portföyden tahsil bordrosunda tahsilin gideceği yer — C# KasaBankaCouple enum'una birebir karşılık gelir.
class TahsilyeriCouples {
  const TahsilyeriCouples._();

  static const List<_CekCouple> _list = [
    _CekCouple(1, 'Kasa'),
    _CekCouple(2, 'Banka'),
  ];

  static List<_CekCouple> get list => _list;

  static String adByValue(int? val) {
    if (val == null) return '';
    return _list.firstWhere((e) => e.value == val, orElse: () => const _CekCouple(0, '')).text;
  }
}

class _CekCouple {
  final int value;
  final String text;
  const _CekCouple(this.value, this.text);
}
