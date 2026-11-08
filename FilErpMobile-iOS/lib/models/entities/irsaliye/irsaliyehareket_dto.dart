import '../firma/firma_dto.dart';
import '../depo/depo_dto.dart';
import '../depo/depoadres_dto.dart';
import '../stok/stok_dto.dart';
import '../stok/stokozelliksabit_dto.dart';
import '../olcubirimi/olcubr_dto.dart';
import '../proje/proje_dto.dart';
import '../cari/referans_dto.dart';
import '../helper/istisna_dto.dart';
import '../fatura/faturahareket_dto.dart';
import '../siparis/siparishareket_dto.dart';
import '../stok/stokhareket_dto.dart';
import '../yukleme/yuklemeplanihareket_dto.dart';
import 'irsaliye_dto.dart';
import '../uretim/uretimpartitakip_rec_dto.dart';

class IrsaliyehareketDto {
  String? id;

  // Referans alanlar
  int? firmaid;
  String? irsaliyeid;
  int? depoid;
  String? depoadresid;
  int? stokid;
  int? stokozelliksabitid;
  int? olcubrid;
  int? olcubr2id;
  int? projeid;
  int? istisnaId;
  int? siparishareketid;
  int? referansid;
  String? stokhareketid;
  int? yuklemeplanihareketid;

  // Temel alanlar
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
  double? iskontoorani2;
  double? iskontotutari2;
  double? iskontoorani3;
  double? iskontotutari3;
  double? iskontoorani4;
  double? iskontotutari4;
  double? iskontoorani5;
  double? iskontotutari5;
  double? iskontoorani6;
  double? iskontotutari6;

  double? doviziskontotutari1;
  double? doviziskontotutari2;
  double? doviziskontotutari3;
  double? doviziskontotutari4;
  double? doviziskontotutari5;
  double? doviziskontotutari6;

  double? kdvorani;
  double? tevkifatorani;
  String? aciklama;
  String? stokadiaciklama;
  int? sira;
  double? faturalandirilmismiktar;

  // Hesaplanan alanlar (C# non-nullable decimal → ?? 0 ile işlenir)
  double? bruttutar;
  double? malfazlasitutar;
  double? iskontotutar;
  double? aratoplam;
  double? geneliskontotutar;
  double? sonaratoplam;
  double? kdvmatrahi;
  double? kdvtutar;
  double? netaratoplam;
  double? geneltoplam;
  double? tevkifattutar;
  double? songeneltoplam;
  double? tutar;
  double? kur;

  // Dart'ta ekstra tuttuğumuz alanlar (hesaplama için)
  double? aratoplamiskontolu;
  double? tevkifatmatrahi;

  // Navigation
  IrsaliyeDto? irsaliye;
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
  List<FaturahareketDto>? faturahareket;
  SiparishareketDto? siparishareket;
  StokhareketDto? stokhareket;
  YuklemeplanihareketDto? yuklemeplanihareket;
  List<UretimpartitakipRecDto>? uretimpartitakip;

  IrsaliyehareketDto();

  IrsaliyehareketDto copy() => IrsaliyehareketDto()
    ..id = id
    ..firmaid = firmaid
    ..irsaliyeid = irsaliyeid
    ..depoid = depoid
    ..depoadresid = depoadresid
    ..stokid = stokid
    ..stokozelliksabitid = stokozelliksabitid
    ..olcubrid = olcubrid
    ..olcubr2id = olcubr2id
    ..projeid = projeid
    ..istisnaId = istisnaId
    ..siparishareketid = siparishareketid
    ..referansid = referansid
    ..stokhareketid = stokhareketid
    ..yuklemeplanihareketid = yuklemeplanihareketid
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
    ..iskontoorani2 = iskontoorani2
    ..iskontotutari2 = iskontotutari2
    ..iskontoorani3 = iskontoorani3
    ..iskontotutari3 = iskontotutari3
    ..iskontoorani4 = iskontoorani4
    ..iskontotutari4 = iskontotutari4
    ..iskontoorani5 = iskontoorani5
    ..iskontotutari5 = iskontotutari5
    ..iskontoorani6 = iskontoorani6
    ..iskontotutari6 = iskontotutari6
    ..doviziskontotutari1 = doviziskontotutari1
    ..doviziskontotutari2 = doviziskontotutari2
    ..doviziskontotutari3 = doviziskontotutari3
    ..doviziskontotutari4 = doviziskontotutari4
    ..doviziskontotutari5 = doviziskontotutari5
    ..doviziskontotutari6 = doviziskontotutari6
    ..kdvorani = kdvorani
    ..tevkifatorani = tevkifatorani
    ..aciklama = aciklama
    ..stokadiaciklama = stokadiaciklama
    ..sira = sira
    ..faturalandirilmismiktar = faturalandirilmismiktar
    ..bruttutar = bruttutar
    ..malfazlasitutar = malfazlasitutar
    ..iskontotutar = iskontotutar
    ..aratoplam = aratoplam
    ..geneliskontotutar = geneliskontotutar
    ..sonaratoplam = sonaratoplam
    ..kdvmatrahi = kdvmatrahi
    ..kdvtutar = kdvtutar
    ..netaratoplam = netaratoplam
    ..geneltoplam = geneltoplam
    ..tevkifattutar = tevkifattutar
    ..songeneltoplam = songeneltoplam
    ..tutar = tutar
    ..kur = kur
    ..aratoplamiskontolu = aratoplamiskontolu
    ..tevkifatmatrahi = tevkifatmatrahi
    ..irsaliye = irsaliye
    ..firma = firma
    ..depo = depo
    ..depoadres = depoadres
    ..stok = stok
    ..stokozelliksabit = stokozelliksabit
    ..olcubr = olcubr
    ..olcubr2 = olcubr2
    ..proje = proje
    ..referans = referans
    ..istisna = istisna
    ..faturahareket = faturahareket
    ..siparishareket = siparishareket
    ..stokhareket = stokhareket
    ..yuklemeplanihareket = yuklemeplanihareket
    ..uretimpartitakip = uretimpartitakip;

  Map<String, dynamic> toInsertJson(String documentId) => <String, dynamic>{
        "irsaliyeid": documentId,
        "stokid": stokid,
        "depoid": depoid,
        "depoadresid": depoadresid,
        "olcubrid": olcubrid,
        "olcubrcarpim": olcubrcarpim,
        "olcubr2id": olcubr2id,
        "istisnaId": istisnaId,
        "stokadiaciklama": stokadiaciklama,
        "projeid": projeid,
        "miktar": miktar,
        "miktar2": miktar2,
        "fiyat": fiyat ?? 0,
        "dovizfiyat": dovizfiyat,
        "kdvorani": (kdvorani ?? 0) / 100,
        "tevkifatorani": tevkifatorani ?? 0,
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
        "malfazlasiiskonto": malfazlasiiskonto,
        "malfazlasitutar": malfazlasitutar ?? 0,
        "bruttutar": bruttutar ?? 0,
        "aratoplam": aratoplam ?? bruttutar ?? 0,
        "sonaratoplam": sonaratoplam ?? bruttutar ?? 0,
        "kdvmatrahi": kdvmatrahi ?? bruttutar ?? 0,
        "kdvtutar": kdvtutar ?? 0,
        "netaratoplam": netaratoplam ?? bruttutar ?? 0,
        "geneltoplam": geneltoplam ?? tutar ?? 0,
        "tevkifattutar": tevkifattutar ?? 0,
        "songeneltoplam": songeneltoplam ?? tutar ?? 0,
        "tutar": tutar ?? 0,
        "kur": kur ?? 1,
        "aciklama": aciklama,
        "teslimtarihi": teslimtarihi?.toIso8601String(),
        "stokozelliksabitid": stokozelliksabitid,
      };

  IrsaliyehareketDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"]?.toString();

    firmaid = json["Firmaid"];
    irsaliyeid = json["Irsaliyeid"]?.toString();
    depoid = json["Depoid"];
    depoadresid = json["Depoadresid"]?.toString();
    stokid = json["Stokid"];
    stokozelliksabitid = json["Stokozelliksabitid"];
    olcubrid = json["Olcubrid"];
    olcubr2id = json["Olcubr2id"];
    olcubr2 =
        json["Olcubr2"] != null ? OlcubrDto.fromJson(json["Olcubr2"]) : null;
    stokadiaciklama = json["Stokadiaciklama"];
    projeid = json["Projeid"];
    istisnaId = json["IstisnaId"];
    siparishareketid = json["Siparishareketid"];
    referansid = json["Referansid"];
    stokhareketid = json["Stokhareketid"]?.toString();
    yuklemeplanihareketid = json["Yuklemeplanihareketid"];

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
    iskontoorani2 = (json["Iskontoorani2"] as num?)?.toDouble();
    iskontotutari2 = (json["Iskontotutari2"] as num?)?.toDouble();
    iskontoorani3 = (json["Iskontoorani3"] as num?)?.toDouble();
    iskontotutari3 = (json["Iskontotutari3"] as num?)?.toDouble();
    iskontoorani4 = (json["Iskontoorani4"] as num?)?.toDouble();
    iskontotutari4 = (json["Iskontotutari4"] as num?)?.toDouble();
    iskontoorani5 = (json["Iskontoorani5"] as num?)?.toDouble();
    iskontotutari5 = (json["Iskontotutari5"] as num?)?.toDouble();
    iskontoorani6 = (json["Iskontoorani6"] as num?)?.toDouble();
    iskontotutari6 = (json["Iskontotutari6"] as num?)?.toDouble();

    doviziskontotutari1 = (json["Doviziskontotutari1"] as num?)?.toDouble();
    doviziskontotutari2 = (json["Doviziskontotutari2"] as num?)?.toDouble();
    doviziskontotutari3 = (json["Doviziskontotutari3"] as num?)?.toDouble();
    doviziskontotutari4 = (json["Doviziskontotutari4"] as num?)?.toDouble();
    doviziskontotutari5 = (json["Doviziskontotutari5"] as num?)?.toDouble();
    doviziskontotutari6 = (json["Doviziskontotutari6"] as num?)?.toDouble();

    kdvorani = (json["Kdvorani"] as num?)?.toDouble();
    tevkifatorani = (json["Tevkifatorani"] as num?)?.toDouble();
    aciklama = json["Aciklama"];
    sira = json["Sira"];
    faturalandirilmismiktar =
        (json["Faturalandirilmismiktar"] as num?)?.toDouble();

    bruttutar = (json["Bruttutar"] as num?)?.toDouble();
    malfazlasitutar = (json["Malfazlasitutar"] as num?)?.toDouble();
    iskontotutar = (json["Iskontotutar"] as num?)?.toDouble();
    aratoplam = (json["Aratoplam"] as num?)?.toDouble();
    geneliskontotutar = (json["Geneliskontotutar"] as num?)?.toDouble();
    sonaratoplam = (json["Sonaratoplam"] as num?)?.toDouble();
    kdvmatrahi = (json["Kdvmatrahi"] as num?)?.toDouble();
    kdvtutar = (json["Kdvtutar"] as num?)?.toDouble();
    netaratoplam = (json["Netaratoplam"] as num?)?.toDouble();
    geneltoplam = (json["Geneltoplam"] as num?)?.toDouble();
    tevkifattutar = (json["Tevkifattutar"] as num?)?.toDouble();
    songeneltoplam = (json["Songeneltoplam"] as num?)?.toDouble();
    tutar = (json["Tutar"] as num?)?.toDouble();
    kur = (json["Kur"] as num?)?.toDouble();

    irsaliye = json["Irsaliye"] != null
        ? IrsaliyeDto.fromJson(json["Irsaliye"])
        : null;
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

    faturahareket = (json["Faturahareket"] as List?)
        ?.where((e) => e != null)
        .map((e) => FaturahareketDto.fromJson(e as Map<String, dynamic>))
        .toList();
    // Döngüsel referans önlemi: siparishareket parse edilmiyor
    // siparishareket = json["Siparishareket"] != null
    //     ? SiparishareketDto.fromJson(json["Siparishareket"]) : null;
    stokhareket = json["Stokhareket"] != null
        ? StokhareketDto.fromJson(json["Stokhareket"])
        : null;
    yuklemeplanihareket = json["Yuklemeplanihareket"] != null
        ? YuklemeplanihareketDto.fromJson(json["Yuklemeplanihareket"])
        : null;
    uretimpartitakip = (json["Uretimpartitakip"] as List?)
        ?.where((e) => e != null)
        .map((e) => UretimpartitakipRecDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
