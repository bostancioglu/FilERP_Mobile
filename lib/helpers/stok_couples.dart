class ByteStrCouple {
  final int value;
  final String text;

  const ByteStrCouple(this.value, this.text);
}

class StokCouples {
  // =======================
  // KART TÜRÜ
  // =======================
  static const List<ByteStrCouple> kartTurleri = [
    ByteStrCouple(1, "Stok"),
    ByteStrCouple(2, "Demirbaş"),
    ByteStrCouple(3, "Hizmet"),
    ByteStrCouple(4, "Ana İş"),
    ByteStrCouple(5, "Alt İş"),
    ByteStrCouple(6, "Operasyon"),
    ByteStrCouple(7, "Malzeme"),
    ByteStrCouple(8, "Muhtelif"),
    ByteStrCouple(9, "Diğer"),
  ];

  // =======================
  // STOK TÜRÜ
  // =======================
  static const List<ByteStrCouple> stokTurleri = [
    ByteStrCouple(1, "Stok"),
    ByteStrCouple(2, "Ticari Mal"),
    ByteStrCouple(3, "Hizmet"),
    ByteStrCouple(4, "Hammadde"),
    ByteStrCouple(5, "Mamul"),
    ByteStrCouple(6, "Yarı Mamul"),
    ByteStrCouple(7, "Operasyon"),
    ByteStrCouple(8, "Malzeme"),
    ByteStrCouple(9, "Yan Ürün"),
    ByteStrCouple(10, "Fason"),
    ByteStrCouple(11, "Demirbaş"),
    ByteStrCouple(12, "Muhtelif"),
    ByteStrCouple(80, "Yedek Parça"),
    ByteStrCouple(99, "Diğer"),
  ];

  // =======================
  // TAKİP ŞEKLİ
  // =======================
  static const List<ByteStrCouple> takipSekilleri = [
    ByteStrCouple(1, "Serbest"),
    ByteStrCouple(2, "Alınır / Satılır"),
    ByteStrCouple(3, "Sadece Alınabilir"),
    ByteStrCouple(4, "Sadece Satılabilir"),
    ByteStrCouple(5, "Sadece Üretimde Kullanılır"),
    ByteStrCouple(9, "Pasif"),
  ];

  static String? captionOf(int? value, List<ByteStrCouple> list) {
    if (value == null) return null;
    final found = list.where((e) => e.value == value);
    return found.isEmpty ? null : found.first.text;
  }
}
