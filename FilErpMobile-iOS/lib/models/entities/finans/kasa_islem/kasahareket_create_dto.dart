class KasahareketCreateDto {
  int? islemmasrafid;
  double? masraf;

  int? kasaid;
  int? islemkasaid;
  int? islemcariid;
  int? islembankahesapid;
  int? dovizid;
  int? projeid;
  int? plasiyerid;

  String? belgeseri;
  int? belgeyil;
  String? belgeno;
  String? belgeserino;
  int? belgeturu;
  int? giriscikis; // 1=Giriş 2=Çıkış
  int? islemtipi; // 1=Cari 2=Banka 3=KasaTransfer 4=Muhtelif 5=Tahsilat 6=Ödeme

  double? kur;
  DateTime? doviztarih;
  double? doviztutar;
  double? tutar;
  String? aciklama;
  DateTime? tarih;
  DateTime? evraktarih;
  String? evrakno;

  KasahareketCreateDto();

  Map<String, dynamic> toJson() => {
        'Islemmasrafid': islemmasrafid,
        'Masraf': masraf,
        if (kasaid != null) 'Kasaid': kasaid,
        if (islemkasaid != null) 'Islemkasaid': islemkasaid,
        if (islemcariid != null) 'Islemcariid': islemcariid,
        if (islembankahesapid != null) 'Islembankahesapid': islembankahesapid,
        if (dovizid != null) 'Dovizid': dovizid,
        if (projeid != null) 'Projeid': projeid,
        if (plasiyerid != null) 'Plasiyerid': plasiyerid,
        if (belgeseri != null) 'Belgeseri': belgeseri,
        if (belgeyil != null) 'Belgeyil': belgeyil,
        if (belgeno != null) 'Belgeno': belgeno,
        if (belgeserino != null) 'Belgeserino': belgeserino,
        if (belgeturu != null) 'Belgeturu': belgeturu,
        if (giriscikis != null) 'Giriscikis': giriscikis,
        if (islemtipi != null) 'Islemtipi': islemtipi,
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
