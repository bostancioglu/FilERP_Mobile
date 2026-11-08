/// Tahsilat şekli — C# TahsilattipiCouple enum'una karşılık gelir (Nakit=1, Banka=2, Kredikarti=3).
class TahsilattipiCouples {
  const TahsilattipiCouples._();

  static const List<_TahsilatCouple> _list = [
    _TahsilatCouple(1, 'Nakit'),
    _TahsilatCouple(2, 'Banka'),
    _TahsilatCouple(3, 'Kredi Kartı'),
  ];

  static List<_TahsilatCouple> get list => _list;

  static String adByValue(int? val) {
    if (val == null) return '';
    return _list.firstWhere((e) => e.value == val, orElse: () => const _TahsilatCouple(0, '')).text;
  }
}

class _TahsilatCouple {
  final int value;
  final String text;
  const _TahsilatCouple(this.value, this.text);
}
