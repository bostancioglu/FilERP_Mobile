class StokcariCreateDto {
  int? stokid;
  int? cariid;
  int? olcubrid;
  int? cariolcubrid;
  int? dovizid;
  bool? aktif;
  String? kod;
  String? ad;
  double? minimumsiparismiktari;
  double? minimumpartimiktari;
  int? teslimgun;
  int? nakliyegun;
  double? listefiyat;
  String? barkod;

  Map<String, dynamic> toJson() => {
        'Stokid': stokid,
        'Cariid': cariid,
        'Olcubrid': olcubrid,
        'Cariolcubrid': cariolcubrid,
        'Dovizid': dovizid,
        'Aktif': aktif,
        'Kod': kod,
        'Ad': ad,
        'Minimumsiparismiktari': minimumsiparismiktari,
        'Minimumpartimiktari': minimumpartimiktari,
        'Teslimgun': teslimgun,
        'Nakliyegun': nakliyegun,
        'Listefiyat': listefiyat,
        'Barkod': barkod,
      };
}
