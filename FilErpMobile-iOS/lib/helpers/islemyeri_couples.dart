class IslemyeriCouples {
  const IslemyeriCouples._();

  static const List<_IslemyeriCouple> _list = [
    _IslemyeriCouple(1, "Referans Kodu"),
    _IslemyeriCouple(2, "Stok Kodu"),
    _IslemyeriCouple(3, "Masraf Merkezi"),
    _IslemyeriCouple(4, "Maliyet"),
  ];

  static List<_IslemyeriCouple> get list => _list;

  static String adByValue(int? val) {
    if (val == null) return '';
    return _list.firstWhere((e) => e.value == val, orElse: () => const _IslemyeriCouple(0, '')).text;
  }
}

class _IslemyeriCouple {
  final int value;
  final String text;
  const _IslemyeriCouple(this.value, this.text);
}