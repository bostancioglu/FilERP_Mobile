import '../firma/firma_dto.dart';
import '../depo/depo_dto.dart';
import '../depo/depoadres_dto.dart';
import '../stok/stok_dto.dart';
import '../stok/stokozelliksabit_dto.dart';
import '../olcubirimi/olcubr_dto.dart';
import '../proje/proje_dto.dart';
import '../cari/referans_dto.dart';
import 'fatura_dto.dart';
import '../helper/istisna_dto.dart';

class FaturahareketDto {
  String? id;

  int? firmaid;
  String? faturaid;
  int? depoid;
  String? depoadresid;
  int? stokid;
  int? stokozelliksabitid;
  int? olcubrid;
  int? olcubr2id;
  int? projeid;
  int? istisnaId;
  int? irsaliyehareketid;
  int? referansid;
  String? stokhareketid;

  double? olcubrcarpim;
  int? belgeturu;
  String? giriscikis;
  DateTime? tarih;
  DateTime? teslimtarihi;

  double? miktar;
  double? miktar2;
  double? dovizfiyat;
  double? fiyat;

  double? malfazlasiiskonto;

  double? iskontoorani1;
  double? iskontotutari1;
  double? doviziskontotutari1;
  double? iskontoorani2;
  double? iskontotutari2;
  double? doviziskontotutari2;
  double? iskontoorani3;
  double? iskontotutari3;
  double? doviziskontotutari3;
  double? iskontoorani4;
  double? iskontotutari4;
  double? doviziskontotutari4;
  double? iskontoorani5;
  double? iskontotutari5;
  double? doviziskontotutari5;
  double? iskontoorani6;
  double? iskontotutari6;
  double? doviziskontotutari6;

  double? tutar;
  double? kdvorani;
  double? tevkifatorani;

  double? bruttutar;
  double? iskontotutar;
  double? malfazlasitutar;
  double? dovizmalfazlasitutar;
  double? aratoplam;
  double? aratoplamiskontolu;
  double? kdvtutar;
  double? tevkifatmatrahi;
  double? tevkifattutar;

  String? aciklama;
  String? stokadiaciklama;
  int? sira;

  String? ortakislemno;

  // Navigation
  FaturaDto? fatura;
  FirmaDto? firma;
  DepoDto? depo;
  DepoadresDto? depoadres;
  StokDto? stok;
  StokozelliksabitDto? stokozelliksabit;
  OlcubrDto? olcubr;
  OlcubrDto? olcubr2;
  ProjeDto? proje;
  ReferansDto? referans;
  IstisnaDto? istisna;

  FaturahareketDto();

  FaturahareketDto copy() {
    return FaturahareketDto()
      ..id = id
      ..firmaid = firmaid
      ..faturaid = faturaid
      ..depoid = depoid
      ..depoadresid = depoadresid
      ..stokid = stokid
      ..stokozelliksabitid = stokozelliksabitid
      ..olcubrid = olcubrid
      ..olcubr2id = olcubr2id
      ..projeid = projeid
      ..istisnaId = istisnaId
      ..irsaliyehareketid = irsaliyehareketid
      ..referansid = referansid
      ..stokhareketid = stokhareketid
      ..olcubrcarpim = olcubrcarpim
      ..belgeturu = belgeturu
      ..giriscikis = giriscikis
      ..tarih = tarih
      ..teslimtarihi = teslimtarihi
      ..miktar = miktar
      ..miktar2 = miktar2
      ..dovizfiyat = dovizfiyat
      ..fiyat = fiyat
      ..malfazlasiiskonto = malfazlasiiskonto
      ..iskontoorani1 = iskontoorani1
      ..iskontotutari1 = iskontotutari1
      ..doviziskontotutari1 = doviziskontotutari1
      ..iskontoorani2 = iskontoorani2
      ..iskontotutari2 = iskontotutari2
      ..doviziskontotutari2 = doviziskontotutari2
      ..iskontoorani3 = iskontoorani3
      ..iskontotutari3 = iskontotutari3
      ..doviziskontotutari3 = doviziskontotutari3
      ..iskontoorani4 = iskontoorani4
      ..iskontotutari4 = iskontotutari4
      ..doviziskontotutari4 = doviziskontotutari4
      ..iskontoorani5 = iskontoorani5
      ..iskontotutari5 = iskontotutari5
      ..doviziskontotutari5 = doviziskontotutari5
      ..iskontoorani6 = iskontoorani6
      ..iskontotutari6 = iskontotutari6
      ..doviziskontotutari6 = doviziskontotutari6
      ..tutar = tutar
      ..kdvorani = kdvorani
      ..tevkifatorani = tevkifatorani
      ..bruttutar = bruttutar
      ..iskontotutar = iskontotutar
      ..malfazlasitutar = malfazlasitutar
      ..dovizmalfazlasitutar = dovizmalfazlasitutar
      ..aratoplam = aratoplam
      ..aratoplamiskontolu = aratoplamiskontolu
      ..kdvtutar = kdvtutar
      ..tevkifatmatrahi = tevkifatmatrahi
      ..tevkifattutar = tevkifattutar
      ..aciklama = aciklama
      ..stokadiaciklama = stokadiaciklama
      ..sira = sira
      ..ortakislemno = ortakislemno
      ..fatura = fatura
      ..firma = firma
      ..depo = depo
      ..depoadres = depoadres
      ..stok = stok
      ..stokozelliksabit = stokozelliksabit
      ..olcubr = olcubr
      ..olcubr2 = olcubr2
      ..proje = proje
      ..referans = referans
      ..istisna = istisna;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      "faturaid": faturaid,
      "depoid": depoid,
      "depoadresid": depoadresid,
      "stokid": stokid,
      "stokozelliksabitid": stokozelliksabitid,
      "olcubrid": olcubrid,
      "olcubr2id": olcubr2id,
      "projeid": projeid,
      "istisnaId": istisnaId,
      "irsaliyehareketid": irsaliyehareketid,
      "referansid": referansid,
      "stokhareketid": stokhareketid,
      "olcubrcarpim": olcubrcarpim,
      "belgeturu": belgeturu,
      "giriscikis": giriscikis,
      "tarih": tarih?.toIso8601String(),
      "teslimtarihi": teslimtarihi?.toIso8601String(),
      "miktar": miktar,
      "miktar2": miktar2,
      "dovizfiyat": dovizfiyat,
      "fiyat": fiyat,
      "malfazlasiiskonto": malfazlasiiskonto,
      "iskontoorani1": iskontoorani1,
      "iskontotutari1": iskontotutari1,
      "doviziskontotutari1": doviziskontotutari1,
      "iskontoorani2": iskontoorani2,
      "iskontotutari2": iskontotutari2,
      "doviziskontotutari2": doviziskontotutari2,
      "iskontoorani3": iskontoorani3,
      "iskontotutari3": iskontotutari3,
      "doviziskontotutari3": doviziskontotutari3,
      "iskontoorani4": iskontoorani4,
      "iskontotutari4": iskontotutari4,
      "doviziskontotutari4": doviziskontotutari4,
      "iskontoorani5": iskontoorani5,
      "iskontotutari5": iskontotutari5,
      "doviziskontotutari5": doviziskontotutari5,
      "iskontoorani6": iskontoorani6,
      "iskontotutari6": iskontotutari6,
      "doviziskontotutari6": doviziskontotutari6,
      "tutar": tutar,
      "kdvorani": kdvorani != null ? kdvorani! / 100 : null,
      "tevkifatorani": tevkifatorani,
      "bruttutar": bruttutar,
      "iskontotutar": iskontotutar,
      "malfazlasitutar": malfazlasitutar,
      "dovizmalfazlasitutar": dovizmalfazlasitutar,
      "aratoplam": aratoplam,
      "aratoplamiskontolu": aratoplamiskontolu,
      "kdvtutar": kdvtutar,
      "tevkifatmatrahi": tevkifatmatrahi,
      "tevkifattutar": tevkifattutar,
      "aciklama": aciklama,
      "stokadiaciklama": stokadiaciklama,
      "sira": sira,
    };
    // id sadece güncelleme (UpdateRowSingle) için gönderilir
    if (id != null) map["id"] = id;
    return map;
  }

  FaturahareketDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"]?.toString();

    firmaid = json["Firmaid"];
    faturaid = json["Faturaid"]?.toString();
    depoid = json["Depoid"];
    depoadresid = json["Depoadresid"]?.toString();
    stokid = json["Stokid"];
    stokozelliksabitid = json["Stokozelliksabitid"];
    olcubrid = json["Olcubrid"];
    olcubr2id = json["Olcubr2id"];
    olcubr2 =
        json["Olcubr2"] != null ? OlcubrDto.fromJson(json["Olcubr2"]) : null;
    projeid = json["Projeid"];
    istisnaId = json["IstisnaId"];
    irsaliyehareketid = json["Irsaliyehareketid"];
    referansid = json["Referansid"];
    stokhareketid = json["Stokhareketid"]?.toString();

    olcubrcarpim = (json["Olcubrcarpim"] as num?)?.toDouble();
    belgeturu = json["Belgeturu"];
    giriscikis = json["Giriscikis"]?.toString();

    tarih = json["Tarih"] != null ? DateTime.parse(json["Tarih"]) : null;
    teslimtarihi = json["Teslimtarihi"] != null
        ? DateTime.parse(json["Teslimtarihi"])
        : null;

    miktar = (json["Miktar"] as num?)?.toDouble();
    miktar2 = (json["Miktar2"] as num?)?.toDouble();
    dovizfiyat = (json["Dovizfiyat"] as num?)?.toDouble();
    fiyat = (json["Fiyat"] as num?)?.toDouble();

    malfazlasiiskonto = (json["Malfazlasiiskonto"] as num?)?.toDouble();

    iskontoorani1 = (json["Iskontoorani1"] as num?)?.toDouble();
    iskontotutari1 = (json["Iskontotutari1"] as num?)?.toDouble();
    doviziskontotutari1 = (json["Doviziskontotutari1"] as num?)?.toDouble();
    iskontoorani2 = (json["Iskontoorani2"] as num?)?.toDouble();
    iskontotutari2 = (json["Iskontotutari2"] as num?)?.toDouble();
    doviziskontotutari2 = (json["Doviziskontotutari2"] as num?)?.toDouble();
    iskontoorani3 = (json["Iskontoorani3"] as num?)?.toDouble();
    iskontotutari3 = (json["Iskontotutari3"] as num?)?.toDouble();
    doviziskontotutari3 = (json["Doviziskontotutari3"] as num?)?.toDouble();
    iskontoorani4 = (json["Iskontoorani4"] as num?)?.toDouble();
    iskontotutari4 = (json["Iskontotutari4"] as num?)?.toDouble();
    doviziskontotutari4 = (json["Doviziskontotutari4"] as num?)?.toDouble();
    iskontoorani5 = (json["Iskontoorani5"] as num?)?.toDouble();
    iskontotutari5 = (json["Iskontotutari5"] as num?)?.toDouble();
    doviziskontotutari5 = (json["Doviziskontotutari5"] as num?)?.toDouble();
    iskontoorani6 = (json["Iskontoorani6"] as num?)?.toDouble();
    iskontotutari6 = (json["Iskontotutari6"] as num?)?.toDouble();
    doviziskontotutari6 = (json["Doviziskontotutari6"] as num?)?.toDouble();

    tutar = (json["Tutar"] as num?)?.toDouble();
    kdvorani = (json["Kdvorani"] as num?)?.toDouble();
    tevkifatorani = ((json["Tevkifatorani"] ??
            json["tevkifatorani"] ??
            json["TevkifatOrani"]) as num?)
        ?.toDouble();

    bruttutar = (json["Bruttutar"] as num?)?.toDouble();
    iskontotutar = (json["Iskontotutar"] as num?)?.toDouble();
    malfazlasitutar = (json["Malfazlasitutar"] as num?)?.toDouble();
    dovizmalfazlasitutar = (json["Dovizmalfazlasitutar"] as num?)?.toDouble();
    aratoplam = (json["Aratoplam"] as num?)?.toDouble();
    aratoplamiskontolu = (json["Aratoplamiskontolu"] as num?)?.toDouble();
    kdvtutar = (json["Kdvtutar"] as num?)?.toDouble();
    tevkifatmatrahi = (json["Tevkifatmatrahi"] as num?)?.toDouble();
    tevkifattutar = (json["Tevkifattutar"] as num?)?.toDouble();

    aciklama = json["Aciklama"];
    stokadiaciklama = json["Stokadiaciklama"];
    sira = json["Sira"];
    ortakislemno = json["Ortakislemno"]?.toString();

    fatura = json["Fatura"] != null ? FaturaDto.fromJson(json["Fatura"]) : null;
    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    depo = json["Depo"] != null ? DepoDto.fromJson(json["Depo"]) : null;
    depoadres = json["Depoadres"] != null
        ? DepoadresDto.fromJson(json["Depoadres"])
        : null;
    stok = json["Stok"] != null ? StokDto.fromJson(json["Stok"]) : null;
    stokozelliksabit = json["Stokozelliksabit"] != null
        ? StokozelliksabitDto.fromJson(json["Stokozelliksabit"])
        : null;
    olcubr = json["Olcubr"] != null ? OlcubrDto.fromJson(json["Olcubr"]) : null;
    proje = json["Proje"] != null ? ProjeDto.fromJson(json["Proje"]) : null;
    referans = json["Referans"] != null
        ? ReferansDto.fromJson(json["Referans"])
        : null;
    istisna =
        json["Istisna"] != null ? IstisnaDto.fromJson(json["Istisna"]) : null;
  }
}
