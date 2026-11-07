class TasimafaziCouples {
  const TasimafaziCouples._();

  static const List<_TasimafaziCouple> _list = [
    _TasimafaziCouple(0, "Boş"),
    _TasimafaziCouple(1, "Deniz Yolu"),
    _TasimafaziCouple(2, "Demir Yolu"),
    _TasimafaziCouple(3, "Kara Yolu"),
    _TasimafaziCouple(4, "Hava Yolu"),
    _TasimafaziCouple(5, "Posta"),
    _TasimafaziCouple(6, "Çok Araçlı"),
    _TasimafaziCouple(7, "Sabit Taşıma Tesisleri"),
    _TasimafaziCouple(8, "İç Su Taşımacılığı"),
  ];

  static List<_TasimafaziCouple> get list => _list;

  static String adByValue(int? val) {
    if (val == null) return '';
    return _list.firstWhere((e) => e.value == val, orElse: () => const _TasimafaziCouple(0, '')).text;
  }
}

class _TasimafaziCouple {
  final int value;
  final String text;
  const _TasimafaziCouple(this.value, this.text);
}