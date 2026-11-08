class GiriscikisCouples {
  const GiriscikisCouples._();

  static const List<_GiriscikisCouple> _list = [
    _GiriscikisCouple(1, "Giriş"),
    _GiriscikisCouple(2, "Çıkış"),
  ];

  static List<_GiriscikisCouple> get list => _list;

  static String adByValue(int? val) {
    if (val == null) return '';
    return _list.firstWhere((e) => e.value == val, orElse: () => const _GiriscikisCouple(0, '')).text;
  }
}

class _GiriscikisCouple {
  final int value;
  final String text;
  const _GiriscikisCouple(this.value, this.text);
}