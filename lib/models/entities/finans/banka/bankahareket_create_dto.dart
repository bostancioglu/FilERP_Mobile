class BankahareketCreateDto {
  int? islemmasrafid;
  double? faiz;
  double? faizdoviz;
  double? kkdf;
  double? kkdfdoviz;
  double? ceza;
  double? cezadoviz;

  int? bankahesapid;
  int? islemcariid;
  int? islembankahesapid;
  int? dovizid;
  int? projeid;
  int? plasiyerid;

  bool? originalflag;
  String? belgeseri;
  int? belgeyil;
  String? belgeno;
  String? belgeserino;
  int? belgeturu;
  int? giriscikis;
  int? islemtipi;

  double? kur;
  DateTime? doviztarih;
  double? doviztutar;
  double? tutar;
  double? komisyon;
  double? dovizkomisyon;
  double? bsmv;
  double? dovizbsmv;
  double? digerucretler;
  double? dovizdigerucretler;
  String? aciklama;
  DateTime? tarih;
  DateTime? evraktarih;
  DateTime? valortarihi;
  String? evrakno;

  BankahareketCreateDto();

  Map<String, dynamic> toJson() => {
        'Islemmasrafid': islemmasrafid,
        'Faiz': faiz,
        'Faizdoviz': faizdoviz,
        'Kkdf': kkdf,
        'Kkdfdoviz': kkdfdoviz,
        'Ceza': ceza,
        'Cezadoviz': cezadoviz,
        if (bankahesapid != null) 'Bankahesapid': bankahesapid,
        if (islemcariid != null) 'Islemcariid': islemcariid,
        if (islembankahesapid != null) 'Islembankahesapid': islembankahesapid,
        if (dovizid != null) 'Dovizid': dovizid,
        if (projeid != null) 'Projeid': projeid,
        if (plasiyerid != null) 'Plasiyerid': plasiyerid,
        if (originalflag != null) 'Originalflag': originalflag,
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
        if (komisyon != null) 'Komisyon': komisyon,
        if (dovizkomisyon != null) 'Dovizkomisyon': dovizkomisyon,
        if (bsmv != null) 'Bsmv': bsmv,
        if (dovizbsmv != null) 'Dovizbsmv': dovizbsmv,
        if (digerucretler != null) 'Digerucretler': digerucretler,
        if (dovizdigerucretler != null)
          'Dovizdigerucretler': dovizdigerucretler,
        if (aciklama != null && aciklama!.isNotEmpty) 'Aciklama': aciklama,
        if (tarih != null) 'Tarih': tarih!.toIso8601String(),
        if (evraktarih != null) 'Evraktarih': evraktarih!.toIso8601String(),
        if (valortarihi != null) 'Valortarihi': valortarihi!.toIso8601String(),
        if (evrakno != null && evrakno!.isNotEmpty) 'Evrakno': evrakno,
      };
}
