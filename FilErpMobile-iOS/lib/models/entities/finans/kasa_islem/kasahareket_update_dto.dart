class KasahareketUpdateDto {
  int? islemmasrafid;
  double? masraf;

  String? id; // Guid
  int? kasaid;
  int? dovizid;
  int? islemcariid;
  int? islemkasaid;
  int? islembankahesapid;
  int? projeid;
  int? plasiyerid;

  double? kur;
  DateTime? doviztarih;
  double? doviztutar;
  double? tutar;
  String? aciklama;
  DateTime? tarih;
  DateTime? evraktarih;
  String? evrakno;

  KasahareketUpdateDto();

  Map<String, dynamic> toJson() => {
        'Islemmasrafid': islemmasrafid,
        'Masraf': masraf,
        if (id != null) 'Id': id,
        if (kasaid != null) 'Kasaid': kasaid,
        if (dovizid != null) 'Dovizid': dovizid,
        if (islemcariid != null) 'Islemcariid': islemcariid,
        if (islemkasaid != null) 'Islemkasaid': islemkasaid,
        if (islembankahesapid != null) 'Islembankahesapid': islembankahesapid,
        if (projeid != null) 'Projeid': projeid,
        if (plasiyerid != null) 'Plasiyerid': plasiyerid,
        if (kur != null) 'Kur': kur,
        if (doviztarih != null) 'Doviztarih': doviztarih!.toIso8601String(),
        if (doviztutar != null) 'Doviztutar': doviztutar,
        if (tutar != null) 'Tutar': tutar,
        if (aciklama != null && aciklama!.isNotEmpty) 'Aciklama': aciklama,
        if (tarih != null) 'Tarih': tarih!.toIso8601String(),
        if (evraktarih != null) 'Evraktarih': evraktarih!.toIso8601String(),
        if (evrakno != null && evrakno!.isNotEmpty) 'Evrakno': evrakno,
      };
}
