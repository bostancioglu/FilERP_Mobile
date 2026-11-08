class OncelikCouples {
  const OncelikCouples._();

  static const List<_OncelikCouple> _list = [
    _OncelikCouple(1, "Çok Acil"),
    _OncelikCouple(2, "Acil"),
    _OncelikCouple(3, "En Kısa Zamanda"),
    _OncelikCouple(4, "Planlı"),
    _OncelikCouple(5, "Diğer"),
  ];

  static List<_OncelikCouple> get list => _list;

  static String adByValue(int? val) {
    if (val == null) return '';
    return _list.firstWhere((e) => e.value == val, orElse: () => const _OncelikCouple(0, '')).text;
  }
}

class _OncelikCouple {
  final int value;
  final String text;
  const _OncelikCouple(this.value, this.text);
}