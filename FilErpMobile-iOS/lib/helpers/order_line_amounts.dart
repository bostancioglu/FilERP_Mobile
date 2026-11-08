import '../models/entities/siparis/siparishareket_dto.dart';

class OrderLineAmounts {
  static void toLocal(SiparishareketDto k, double previousRate) {
    final tl = tiers(k), fx = tiers(k, foreign: true);
    setTiers(
        k,
        List.generate(
            6, (i) => fx[i] ?? (tl[i] == null ? null : tl[i]! / previousRate)));
    k.iskontotutar = (k.iskontotutar ?? 0) / previousRate;
    k.ekmaliyet = k.dovizekmaliyet ??
        (k.ekmaliyet == null ? null : k.ekmaliyet! / previousRate);
    k.dovizekmaliyet = null;
    setTiers(k, List.filled(6, null), foreign: true);
  }

  static List<double?> tiers(SiparishareketDto k, {bool foreign = false}) =>
      foreign
          ? [
              k.doviziskontotutari1,
              k.doviziskontotutari2,
              k.doviziskontotutari3,
              k.doviziskontotutari4,
              k.doviziskontotutari5,
              k.doviziskontotutari6
            ]
          : [
              k.iskontotutari1,
              k.iskontotutari2,
              k.iskontotutari3,
              k.iskontotutari4,
              k.iskontotutari5,
              k.iskontotutari6
            ];
  static void setTiers(SiparishareketDto k, List<double?> v,
      {bool foreign = false}) {
    if (foreign) {
      k.doviziskontotutari1 = v[0];
      k.doviziskontotutari2 = v[1];
      k.doviziskontotutari3 = v[2];
      k.doviziskontotutari4 = v[3];
      k.doviziskontotutari5 = v[4];
      k.doviziskontotutari6 = v[5];
    } else {
      k.iskontotutari1 = v[0];
      k.iskontotutari2 = v[1];
      k.iskontotutari3 = v[2];
      k.iskontotutari4 = v[3];
      k.iskontotutari5 = v[4];
      k.iskontotutari6 = v[5];
    }
  }

  static SiparishareketDto editor(
      SiparishareketDto source, double rate, bool foreign) {
    final k = source.copy();
    if (!foreign) return k;
    k.fiyat = source.dovizfiyat ?? (source.fiyat ?? 0) / rate;
    k.iskontotutar = (source.iskontotutar ?? 0) / rate;
    final tl = tiers(source), fx = tiers(source, foreign: true);
    setTiers(
        k,
        List.generate(
            6, (i) => fx[i] ?? (tl[i] == null ? null : tl[i]! / rate)));
    k.ekmaliyet = source.dovizekmaliyet ??
        (source.ekmaliyet == null ? null : source.ekmaliyet! / rate);
    return k;
  }

  static void fromEditor(SiparishareketDto k, double rate, bool foreign) {
    final values = tiers(k);
    setTiers(k, foreign ? values : List.filled(6, null), foreign: true);
    if (foreign) {
      setTiers(k, values.map((v) => v == null ? null : v * rate).toList());
      k.iskontotutar = (k.iskontotutar ?? 0) * rate;
      k.dovizekmaliyet = k.ekmaliyet;
      k.ekmaliyet = k.ekmaliyet == null ? null : k.ekmaliyet! * rate;
    } else {
      k.dovizekmaliyet = null;
    }
  }

  static void revalue(SiparishareketDto k, double rate, double previousRate) {
    final tl = tiers(k), fx = tiers(k, foreign: true);
    final next = List<double?>.generate(
        6, (i) => fx[i] ?? (tl[i] == null ? null : tl[i]! / previousRate));
    setTiers(k, next, foreign: true);
    setTiers(k, next.map((v) => v == null ? null : v * rate).toList());
    k.iskontotutar = (k.iskontotutar ?? 0) / previousRate * rate;
    k.dovizekmaliyet ??=
        k.ekmaliyet == null ? null : k.ekmaliyet! / previousRate;
    k.ekmaliyet = k.dovizekmaliyet == null ? null : k.dovizekmaliyet! * rate;
  }
}
