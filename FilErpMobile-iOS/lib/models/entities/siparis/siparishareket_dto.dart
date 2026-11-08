import '../firma/firma_dto.dart';
import '../depo/depo_dto.dart';
import '../stok/stok_dto.dart';
import '../stok/stokozelliksabit_dto.dart';
import '../olcubirimi/olcubr_dto.dart';
import '../proje/proje_dto.dart';
import '../helper/istisna_dto.dart';
import '../cari/referans_dto.dart';
import '../irsaliye/irsaliyehareket_dto.dart';
import '../fatura/faturahareket_dto.dart';
import '../teklif/teklifhareket_dto.dart';
import 'siparis_dto.dart';

class SiparishareketDto {
  String? id;

  // Referans alanlar
  int? firmaid;
  String? siparisid;
  int? depoid;
  int? stokid;
  int? stokozelliksabitid;
  int? olcubrid;
  int? olcubr2id;
  int? projeid;
  int? istisnaId;
  int? teklifhareketid;
  int? baglantisiparishareketid;
  int? referansid;

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
  int? onaydurum;
  bool? baglantikullan;
  bool? acikkapali;
  String? kapanisnedeni;
  int? sira;

  // Hesaplanan alanlar
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

  // Dart'ta ekstra
  double? tevkifatmatrahi;
  double? aratoplamiskontolu;

  // Navigation
  SiparisDto? siparis;
  FirmaDto? firma;
  DepoDto? depo;
  StokDto? stok;
  StokozelliksabitDto? stokozelliksabit;
  OlcubrDto? olcubr;
  ProjeDto? proje;
  IstisnaDto? istisna;
  ReferansDto? referans;
  SiparishareketDto? baglantisiparishareket;
  List<IrsaliyehareketDto>? irsaliyehareket;
  List<FaturahareketDto>? faturahareket;
  TeklifhareketDto? teklifhareket;

  String? stokadiaciklama;
  OlcubrDto? olcubr2;
  double? ekmaliyet;
  double? dovizekmaliyet;
  SiparishareketDto();

  SiparishareketDto copy() => SiparishareketDto()
    ..id = id
    ..firmaid = firmaid
    ..siparisid = siparisid
    ..depoid = depoid
    ..stokid = stokid
    ..stokozelliksabitid = stokozelliksabitid
    ..olcubrid = olcubrid
    ..olcubr2id = olcubr2id
    ..projeid = projeid
    ..istisnaId = istisnaId
    ..teklifhareketid = teklifhareketid
    ..baglantisiparishareketid = baglantisiparishareketid
    ..referansid = referansid
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
    ..onaydurum = onaydurum
    ..baglantikullan = baglantikullan
    ..acikkapali = acikkapali
    ..kapanisnedeni = kapanisnedeni
    ..sira = sira
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
    ..tevkifatmatrahi = tevkifatmatrahi
    ..aratoplamiskontolu = aratoplamiskontolu
    ..siparis = siparis
    ..firma = firma
    ..depo = depo
    ..stok = stok
    ..stokozelliksabit = stokozelliksabit
    ..olcubr = olcubr
    ..proje = proje
    ..istisna = istisna
    ..referans = referans
    ..baglantisiparishareket = baglantisiparishareket
    ..irsaliyehareket = irsaliyehareket
    ..faturahareket = faturahareket
    ..teklifhareket = teklifhareket
    ..stokadiaciklama = stokadiaciklama
    ..olcubr2 = olcubr2
    ..ekmaliyet = ekmaliyet
    ..dovizekmaliyet = dovizekmaliyet;

  SiparishareketDto.fromJson(Map<String, dynamic> json) {
    olcubr2id = json["Olcubr2id"];
    olcubr2 =
        json["Olcubr2"] == null ? null : OlcubrDto.fromJson(json["Olcubr2"]);
    stokadiaciklama = json["Stokadiaciklama"];
    ekmaliyet = (json["Ekmaliyet"] as num?)?.toDouble();
    dovizekmaliyet = (json["Dovizekmaliyet"] as num?)?.toDouble();
    id = json["Id"]?.toString();

    firmaid = json["Firmaid"];
    siparisid = json["Siparisid"]?.toString();
    depoid = json["Depoid"];
    stokid = json["Stokid"];
    stokozelliksabitid = json["Stokozelliksabitid"];
    olcubrid = json["Olcubrid"];
    projeid = json["Projeid"];
    istisnaId = json["IstisnaId"];
    teklifhareketid = json["Teklifhareketid"];
    baglantisiparishareketid = json["Baglantisiparishareketid"];
    referansid = json["Referansid"];

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
    onaydurum = json["Onaydurum"];
    baglantikullan = json["Baglantikullan"];
    acikkapali = json["Acikkapali"];
    kapanisnedeni = json["Kapanisnedeni"];
    sira = json["Sira"];

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

    // Siparis navigation parse edilmiyor (circular reference riski)
    // siparis = json["Siparis"] != null ? SiparisDto.fromJson(json["Siparis"]) : null;
    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    depo = json["Depo"] != null ? DepoDto.fromJson(json["Depo"]) : null;
    stok = json["Stok"] != null ? StokDto.fromJson(json["Stok"]) : null;
    stokozelliksabit = json["Stokozelliksabit"] != null
        ? StokozelliksabitDto.fromJson(json["Stokozelliksabit"])
        : null;
    olcubr = json["Olcubr"] != null ? OlcubrDto.fromJson(json["Olcubr"]) : null;
    proje = json["Proje"] != null ? ProjeDto.fromJson(json["Proje"]) : null;
    istisna =
        json["Istisna"] != null ? IstisnaDto.fromJson(json["Istisna"]) : null;
    referans = json["Referans"] != null
        ? ReferansDto.fromJson(json["Referans"])
        : null;

    baglantisiparishareket = json["Baglantisiparishareket"] != null
        ? SiparishareketDto.fromJson(json["Baglantisiparishareket"])
        : null;

    // Döngüsel referans önlemi: irsaliyehareket parse edilmiyor
    // irsaliyehareket = (json["Irsaliyehareket"] as List?)
    //     ?.where((e) => e != null)
    //     .map((e) => IrsaliyehareketDto.fromJson(e as Map<String, dynamic>))
    //     .toList();
    faturahareket = (json["Faturahareket"] as List?)
        ?.where((e) => e != null)
        .map((e) => FaturahareketDto.fromJson(e as Map<String, dynamic>))
        .toList();
    // Döngüsel referans önlemi: teklifhareket parse edilmiyor
    // teklifhareket = json["Teklifhareket"] != null
    //     ? TeklifhareketDto.fromJson(json["Teklifhareket"]) : null;
  }
}
