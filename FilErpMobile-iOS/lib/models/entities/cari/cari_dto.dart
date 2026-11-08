import 'cari_extra_fields.dart';
import '../../base_dto.dart';
import '../adres/ulke_dto.dart';
import '../adres/il_dto.dart';
import '../adres/ilce_dto.dart';
import '../plasiyer/plasiyer_dto.dart';
import '../helper/doviz_dto.dart';
import 'carikategori_dto.dart';

class CariDto extends BaseDto {
  final int? Firmaid;
  final int? Sirketid;
  final int? Ulkeid;
  final int? Ilid;
  final int? Ilceid;
  final int? Plasiyerid;
  final int? Dovizid;
  final int? Carikategoriid;
  final int? Kilit;
  final int? Hesaptipi;
  final int? Efaturatip;
  final bool? Ortakkoduvar;
  final bool? Sirketortak;

  final String? Ad;
  final String? Kod;
  final int? Kartturu;
  final int? Firmatipi;
  final String? Vergidairesi;
  final String? Vergino;
  final String? Tckimlik;
  final String? Adres;
  final String? Bolge;
  final String? Kurumsaltel;
  final String? Yetkilimobil;
  final int? Vadegunu;
  final double? Iskontoorani;
  final String? Grupkodu;
  final String? Kod1;
  final String? Kod2;
  final String? Kod3;
  final String? Kod4;
  final String? Kod5;
  final String? Ortakkod;

  final UlkeDto? Ulke;
  final IlDto? Il;
  final IlceDto? Ilce;
  final PlasiyerDto? Plasiyer;
  final DovizDto? Doviz;
  final CarikategoriDto? Carikategori;

  final int? Bankaid;
  final int? Bankasubeid;
  final int? Hesapplaniid;
  final int? Kurfarkigelirhesapplaniid;
  final int? Kurfarkigiderhesapplaniid;
  final int? Baglicariid;
  final int? Komisyoncucariid;
  final String? Hesapno;
  final String? Iban;
  final String? Bankaaciklama;
  final String? Efaturaalias;
  final String? Eirsaliyealias;
  final String? Efaturaiban;
  final String? Kosulkodu;
  final String? Vat;
  final String? Kurumsalfax;
  final String? Kurumsalmobil;
  final String? Kurumsalweb;
  final String? Kurumsalemail;
  final String? Yetkiliunvan;
  final String? Yetkiliad;
  final String? Yetkiliemail;
  final String? Yetkilitel;
  final String? Muhasebeortakkod;
  final bool? Efaturamukkellefi;
  final bool? Eirsaliyemukkellefi;
  final bool? Riskkontroluvar;
  final bool? Plasiyerortak;
  final Map<String, String> selectionLabels;
  CariDto({
    super.Id,
    this.selectionLabels = const {},
    this.Bankaid,
    this.Bankasubeid,
    this.Hesapplaniid,
    this.Kurfarkigelirhesapplaniid,
    this.Kurfarkigiderhesapplaniid,
    this.Baglicariid,
    this.Komisyoncucariid,
    this.Hesapno,
    this.Iban,
    this.Bankaaciklama,
    this.Efaturaalias,
    this.Eirsaliyealias,
    this.Efaturaiban,
    this.Kosulkodu,
    this.Vat,
    this.Kurumsalfax,
    this.Kurumsalmobil,
    this.Kurumsalweb,
    this.Kurumsalemail,
    this.Yetkiliunvan,
    this.Yetkiliad,
    this.Yetkiliemail,
    this.Yetkilitel,
    this.Muhasebeortakkod,
    this.Efaturamukkellefi,
    this.Eirsaliyemukkellefi,
    this.Riskkontroluvar,
    this.Plasiyerortak,
    this.Firmaid,
    this.Sirketid,
    this.Ulkeid,
    this.Ilid,
    this.Ilceid,
    this.Plasiyerid,
    this.Dovizid,
    this.Carikategoriid,
    this.Ad,
    this.Kod,
    this.Kartturu,
    this.Firmatipi,
    this.Vergidairesi,
    this.Vergino,
    this.Tckimlik,
    this.Adres,
    this.Bolge,
    this.Kurumsaltel,
    this.Yetkilimobil,
    this.Vadegunu,
    this.Iskontoorani,
    this.Grupkodu,
    this.Kod1,
    this.Kod2,
    this.Kod3,
    this.Kod4,
    this.Kod5,
    this.Ulke,
    this.Il,
    this.Ilce,
    this.Plasiyer,
    this.Doviz,
    this.Carikategori,
    this.Kilit,
    this.Hesaptipi,
    this.Efaturatip,
    this.Ortakkoduvar,
    this.Ortakkod,
    this.Sirketortak,
  });

  factory CariDto.fromJson(Map<String, dynamic> json) => CariDto(
        Id: cariInt(json['Id']),
        selectionLabels: cariSelectionLabels(json),
        Firmaid: cariInt(json['Firmaid']),
        Sirketid: cariInt(json['Sirketid']),
        Ulkeid: cariInt(json['Ulkeid']),
        Ilid: cariInt(json['Ilid']),
        Ilceid: cariInt(json['Ilceid']),
        Plasiyerid: cariInt(json['Plasiyerid']),
        Dovizid: cariInt(json['Dovizid']),
        Carikategoriid: cariInt(json['Carikategoriid']),
        Kilit: cariInt(json['Kilit']),
        Hesaptipi: cariInt(json['Hesaptipi']),
        Efaturatip: cariInt(json['Efaturatip']),
        Ortakkoduvar: json['Ortakkoduvar'],
        Sirketortak: json['Sirketortak'],
        Ad: json['Ad'],
        Kod: json['Kod'],
        Kartturu: cariInt(json['Kartturu']),
        Firmatipi: cariInt(json['Firmatipi']),
        Vergidairesi: json['Vergidairesi'] ??
            json['VergiDairesi'] ??
            json['vergiDairesi'],
        Vergino: json['Vergino'],
        Tckimlik: json['Tckimlik'],
        Adres: json['Adres'],
        Bolge: json['Bolge'],
        Kurumsaltel: json['Kurumsaltel'],
        Yetkilimobil: json['Yetkilimobil'],
        Vadegunu: cariInt(json['Vadegunu']),
        Iskontoorani: (json['Iskontoorani'] as num?)?.toDouble(),
        Grupkodu: json['Grupkodu'],
        Kod1: json['Kod1'],
        Kod2: json['Kod2'],
        Kod3: json['Kod3'],
        Kod4: json['Kod4'],
        Kod5: json['Kod5'],
        Ortakkod: json['Ortakkod'],
        Ulke: json['Ulke'] is Map
            ? UlkeDto.fromJson(Map<String, dynamic>.from(json['Ulke']))
            : null,
        Il: json['Il'] is Map
            ? IlDto.fromJson(Map<String, dynamic>.from(json['Il']))
            : null,
        Ilce: json['Ilce'] is Map
            ? IlceDto.fromJson(Map<String, dynamic>.from(json['Ilce']))
            : null,
        Plasiyer: json['Plasiyer'] is Map
            ? PlasiyerDto.fromJson(Map<String, dynamic>.from(json['Plasiyer']))
            : null,
        Doviz: json['Doviz'] is Map
            ? DovizDto.fromJson(Map<String, dynamic>.from(json['Doviz']))
            : null,
        Carikategori: json['Carikategori'] is Map
            ? CarikategoriDto.fromJson(
                Map<String, dynamic>.from(json['Carikategori']))
            : null,
        Bankaid: cariInt(json['Bankaid']),
        Bankasubeid: cariInt(json['Bankasubeid']),
        Hesapplaniid: cariInt(json['Hesapplaniid']),
        Kurfarkigelirhesapplaniid: cariInt(json['Kurfarkigelirhesapplaniid']),
        Kurfarkigiderhesapplaniid: cariInt(json['Kurfarkigiderhesapplaniid']),
        Baglicariid: cariInt(json['Baglicariid']),
        Komisyoncucariid: cariInt(json['Komisyoncucariid']),
        Hesapno: json['Hesapno'],
        Iban: json['Iban'],
        Bankaaciklama: json['Bankaaciklama'],
        Efaturaalias: json['Efaturaalias'],
        Eirsaliyealias: json['Eirsaliyealias'],
        Efaturaiban: json['Efaturaiban'],
        Kosulkodu: json['Kosulkodu'],
        Vat: json['Vat'],
        Kurumsalfax: json['Kurumsalfax'],
        Kurumsalmobil: json['Kurumsalmobil'],
        Kurumsalweb: json['Kurumsalweb'],
        Kurumsalemail: json['Kurumsalemail'],
        Yetkiliunvan: json['Yetkiliunvan'],
        Yetkiliad: json['Yetkiliad'],
        Yetkiliemail: json['Yetkiliemail'],
        Yetkilitel: json['Yetkilitel'],
        Muhasebeortakkod: json['Muhasebeortakkod'],
        Efaturamukkellefi: json['Efaturamukkellefi'],
        Eirsaliyemukkellefi: json['Eirsaliyemukkellefi'],
        Riskkontroluvar: json['Riskkontroluvar'],
        Plasiyerortak: json['Plasiyerortak'],
      );

  Map<String, dynamic> toJson(
      {bool includeKod = true, bool includeId = false}) {
    final map = <String, dynamic>{};

    if (includeId && Id != null) map["Id"] = Id;
    if (includeKod && Kod != null) map["Kod"] = Kod;
    if (Ad != null) map["Ad"] = Ad;
    if (Vergidairesi != null) map["Vergidairesi"] = Vergidairesi;
    if (Vergino != null) map["Vergino"] = Vergino;
    if (Tckimlik != null) map["Tckimlik"] = Tckimlik;
    if (Adres != null) map["Adres"] = Adres;
    if (Bolge != null) map["Bolge"] = Bolge;
    if (Kurumsaltel != null) map["Kurumsaltel"] = Kurumsaltel;
    if (Yetkilimobil != null) map["Yetkilimobil"] = Yetkilimobil;
    if (Vadegunu != null) map["Vadegunu"] = Vadegunu;
    if (Iskontoorani != null) map["Iskontoorani"] = Iskontoorani;
    if (Kartturu != null) map["Kartturu"] = Kartturu;
    if (Firmatipi != null) map["Firmatipi"] = Firmatipi;
    if (Ulkeid != null) map["Ulkeid"] = Ulkeid;
    if (Ilid != null) map["Ilid"] = Ilid;
    if (Ilceid != null) map["Ilceid"] = Ilceid;
    if (Plasiyerid != null) map["Plasiyerid"] = Plasiyerid;
    if (Dovizid != null) map["Dovizid"] = Dovizid;
    if (Carikategoriid != null) map["Carikategoriid"] = Carikategoriid;
    if (Grupkodu != null) map["Grupkodu"] = Grupkodu;
    if (Kod1 != null) map["Kod1"] = Kod1;
    if (Kod2 != null) map["Kod2"] = Kod2;
    if (Kod3 != null) map["Kod3"] = Kod3;
    if (Kod4 != null) map["Kod4"] = Kod4;
    if (Kod5 != null) map["Kod5"] = Kod5;
    if (Kilit != null) map["Kilit"] = Kilit;
    if (Hesaptipi != null) map["Hesaptipi"] = Hesaptipi;
    if (Efaturatip != null) map["Efaturatip"] = Efaturatip;
    if (Ortakkoduvar != null) map["Ortakkoduvar"] = Ortakkoduvar;
    if (Ortakkod != null) map["Ortakkod"] = Ortakkod;
    if (Sirketortak != null) map["Sirketortak"] = Sirketortak;

    if (Bankaid != null) map["Bankaid"] = Bankaid;
    if (Bankasubeid != null) map["Bankasubeid"] = Bankasubeid;
    if (Hesapplaniid != null) map["Hesapplaniid"] = Hesapplaniid;
    if (Kurfarkigelirhesapplaniid != null)
      map["Kurfarkigelirhesapplaniid"] = Kurfarkigelirhesapplaniid;
    if (Kurfarkigiderhesapplaniid != null)
      map["Kurfarkigiderhesapplaniid"] = Kurfarkigiderhesapplaniid;
    if (Baglicariid != null) map["Baglicariid"] = Baglicariid;
    if (Komisyoncucariid != null) map["Komisyoncucariid"] = Komisyoncucariid;
    if (Hesapno != null) map["Hesapno"] = Hesapno;
    if (Iban != null) map["Iban"] = Iban;
    if (Bankaaciklama != null) map["Bankaaciklama"] = Bankaaciklama;
    if (Efaturaalias != null) map["Efaturaalias"] = Efaturaalias;
    if (Eirsaliyealias != null) map["Eirsaliyealias"] = Eirsaliyealias;
    if (Efaturaiban != null) map["Efaturaiban"] = Efaturaiban;
    if (Kosulkodu != null) map["Kosulkodu"] = Kosulkodu;
    if (Vat != null) map["Vat"] = Vat;
    if (Kurumsalfax != null) map["Kurumsalfax"] = Kurumsalfax;
    if (Kurumsalmobil != null) map["Kurumsalmobil"] = Kurumsalmobil;
    if (Kurumsalweb != null) map["Kurumsalweb"] = Kurumsalweb;
    if (Kurumsalemail != null) map["Kurumsalemail"] = Kurumsalemail;
    if (Yetkiliunvan != null) map["Yetkiliunvan"] = Yetkiliunvan;
    if (Yetkiliad != null) map["Yetkiliad"] = Yetkiliad;
    if (Yetkiliemail != null) map["Yetkiliemail"] = Yetkiliemail;
    if (Yetkilitel != null) map["Yetkilitel"] = Yetkilitel;
    if (Muhasebeortakkod != null) map["Muhasebeortakkod"] = Muhasebeortakkod;
    if (Efaturamukkellefi != null) map["Efaturamukkellefi"] = Efaturamukkellefi;
    if (Eirsaliyemukkellefi != null)
      map["Eirsaliyemukkellefi"] = Eirsaliyemukkellefi;
    if (Riskkontroluvar != null) map["Riskkontroluvar"] = Riskkontroluvar;
    if (Plasiyerortak != null) map["Plasiyerortak"] = Plasiyerortak;
    return map;
  }
}
