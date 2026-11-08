import 'cari_dto.dart';
import 'cari_extra_fields.dart';
import '../../base_dto.dart';
import '../adres/ulke_dto.dart';
import '../adres/il_dto.dart';
import '../adres/ilce_dto.dart';
import '../plasiyer/plasiyer_dto.dart';
import '../helper/doviz_dto.dart';
import 'carikategori_dto.dart';

class CariDtoFull extends BaseDto {
  final String? Kod;
  final String? Ad;
  final String? Vergidairesi;
  final String? Vergino;
  final String? Tckimlik;
  final String? Adres;
  final String? Bolge;
  final String? Kurumsaltel;
  final String? Yetkilimobil;

  final int? Kartturu;
  final int? Ulkeid;
  final int? Ilid;
  final int? Ilceid;
  final int? Plasiyerid;
  final int? Dovizid;
  final int? Carikategoriid;
  final int? Firmatipi;
  final int? Efaturatip;

  final int? Hesaptipi;
  final int? Kilit;
  final bool? Ortakkoduvar;
  final bool? Sirketortak;

  final int? Vadegunu;
  final double? Iskontoorani;

  final String? Grupkodu;
  final String? Kod1;
  final String? Kod2;
  final String? Kod3;
  final String? Kod4;
  final String? Kod5;

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
  final String? Ortakkod;
  final String? Muhasebeortakkod;
  final bool? Efaturamukkellefi;
  final bool? Eirsaliyemukkellefi;
  final bool? Riskkontroluvar;
  final bool? Plasiyerortak;
  final Map<String, String> selectionLabels;
  CariDtoFull({
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
    this.Ortakkod,
    this.Muhasebeortakkod,
    this.Efaturamukkellefi,
    this.Eirsaliyemukkellefi,
    this.Riskkontroluvar,
    this.Plasiyerortak,
    this.Kod,
    this.Ad,
    this.Vergidairesi,
    this.Vergino,
    this.Tckimlik,
    this.Adres,
    this.Bolge,
    this.Kurumsaltel,
    this.Yetkilimobil,
    this.Kartturu,
    this.Ulkeid,
    this.Ilid,
    this.Ilceid,
    this.Plasiyerid,
    this.Dovizid,
    this.Carikategoriid,
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
    this.Firmatipi,
    this.Efaturatip,
    this.Hesaptipi,
    this.Kilit,
    this.Ortakkoduvar,
    this.Sirketortak,
  });

  factory CariDtoFull.fromJson(Map<String, dynamic> json) => CariDtoFull(
        Id: cariInt(json['Id']),
        selectionLabels: cariSelectionLabels(json),
        Kod: json['Kod'],
        Ad: json['Ad'],
        Vergidairesi: json['Vergidairesi'] ??
            json['VergiDairesi'] ??
            json['vergiDairesi'],
        Vergino: json['Vergino'],
        Tckimlik: json['Tckimlik'],
        Adres: json['Adres'],
        Bolge: json['Bolge'],
        Kurumsaltel: json['Kurumsaltel'],
        Yetkilimobil: json['Yetkilimobil'],
        Kartturu: cariInt(json['Kartturu']),
        Ulkeid: cariInt(json['Ulkeid']),
        Ilid: cariInt(json['Ilid']),
        Ilceid: cariInt(json['Ilceid']),
        Plasiyerid: cariInt(json['Plasiyerid']),
        Dovizid: cariInt(json['Dovizid']),
        Carikategoriid: cariInt(json['Carikategoriid']),
        Firmatipi: cariInt(json['Firmatipi']),
        Efaturatip: cariInt(json['Efaturatip']),
        Hesaptipi: cariInt(json['Hesaptipi']),
        Kilit: cariInt(json['Kilit']),
        Ortakkoduvar: json['Ortakkoduvar'],
        Sirketortak: json['Sirketortak'],
        Vadegunu: cariInt(json['Vadegunu']),
        Iskontoorani: (json['Iskontoorani'] as num?)?.toDouble(),
        Grupkodu: json['Grupkodu'],
        Kod1: json['Kod1'],
        Kod2: json['Kod2'],
        Kod3: json['Kod3'],
        Kod4: json['Kod4'],
        Kod5: json['Kod5'],
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
        Ortakkod: json['Ortakkod'],
        Muhasebeortakkod: json['Muhasebeortakkod'],
        Efaturamukkellefi: json['Efaturamukkellefi'],
        Eirsaliyemukkellefi: json['Eirsaliyemukkellefi'],
        Riskkontroluvar: json['Riskkontroluvar'],
        Plasiyerortak: json['Plasiyerortak'],
      );

  Map<String, dynamic> toJson() {
    return {
      "Bankaid": Bankaid,
      "Bankasubeid": Bankasubeid,
      "Hesapplaniid": Hesapplaniid,
      "Kurfarkigelirhesapplaniid": Kurfarkigelirhesapplaniid,
      "Kurfarkigiderhesapplaniid": Kurfarkigiderhesapplaniid,
      "Baglicariid": Baglicariid,
      "Komisyoncucariid": Komisyoncucariid,
      "Hesapno": Hesapno,
      "Iban": Iban,
      "Bankaaciklama": Bankaaciklama,
      "Efaturaalias": Efaturaalias,
      "Eirsaliyealias": Eirsaliyealias,
      "Efaturaiban": Efaturaiban,
      "Kosulkodu": Kosulkodu,
      "Vat": Vat,
      "Kurumsalfax": Kurumsalfax,
      "Kurumsalmobil": Kurumsalmobil,
      "Kurumsalweb": Kurumsalweb,
      "Kurumsalemail": Kurumsalemail,
      "Yetkiliunvan": Yetkiliunvan,
      "Yetkiliad": Yetkiliad,
      "Yetkiliemail": Yetkiliemail,
      "Yetkilitel": Yetkilitel,
      "Ortakkod": Ortakkod,
      "Muhasebeortakkod": Muhasebeortakkod,
      "Efaturamukkellefi": Efaturamukkellefi,
      "Eirsaliyemukkellefi": Eirsaliyemukkellefi,
      "Riskkontroluvar": Riskkontroluvar,
      "Plasiyerortak": Plasiyerortak,
      "Kod": Kod,
      "Ad": Ad,
      "Vergidairesi": Vergidairesi,
      "Vergino": Vergino,
      "Tckimlik": Tckimlik,
      "Adres": Adres,
      "Bolge": Bolge,
      "Kurumsaltel": Kurumsaltel,
      "Yetkilimobil": Yetkilimobil,
      "Kartturu": Kartturu,
      "Ulkeid": Ulkeid,
      "Ilid": Ilid,
      "Ilceid": Ilceid,
      "Plasiyerid": Plasiyerid,
      "Dovizid": Dovizid,
      "Carikategoriid": Carikategoriid,
      "Vadegunu": Vadegunu,
      "Iskontoorani": Iskontoorani,
      "Grupkodu": Grupkodu,
      "Kod1": Kod1,
      "Kod2": Kod2,
      "Kod3": Kod3,
      "Kod4": Kod4,
      "Kod5": Kod5,
      "Firmatipi": Firmatipi,
      "Efaturatip": Efaturatip,
      "Hesaptipi": Hesaptipi,
      "Kilit": Kilit,
      "Ortakkoduvar": Ortakkoduvar,
      "Sirketortak": Sirketortak,
    };
  }

  CariDto toEditDto() => CariDto(
        Id: Id,
        selectionLabels: selectionLabels,
        Kod: Kod,
        Ad: Ad,
        Vergidairesi: Vergidairesi,
        Vergino: Vergino,
        Tckimlik: Tckimlik,
        Adres: Adres,
        Bolge: Bolge,
        Kurumsaltel: Kurumsaltel,
        Yetkilimobil: Yetkilimobil,
        Kartturu: Kartturu,
        Ulkeid: Ulkeid,
        Ilid: Ilid,
        Ilceid: Ilceid,
        Plasiyerid: Plasiyerid,
        Dovizid: Dovizid,
        Carikategoriid: Carikategoriid,
        Firmatipi: Firmatipi,
        Efaturatip: Efaturatip,
        Hesaptipi: Hesaptipi,
        Kilit: Kilit,
        Ortakkoduvar: Ortakkoduvar,
        Sirketortak: Sirketortak,
        Vadegunu: Vadegunu,
        Iskontoorani: Iskontoorani,
        Grupkodu: Grupkodu,
        Kod1: Kod1,
        Kod2: Kod2,
        Kod3: Kod3,
        Kod4: Kod4,
        Kod5: Kod5,
        Ulke: Ulke,
        Il: Il,
        Ilce: Ilce,
        Plasiyer: Plasiyer,
        Doviz: Doviz,
        Carikategori: Carikategori,
        Bankaid: Bankaid,
        Bankasubeid: Bankasubeid,
        Hesapplaniid: Hesapplaniid,
        Kurfarkigelirhesapplaniid: Kurfarkigelirhesapplaniid,
        Kurfarkigiderhesapplaniid: Kurfarkigiderhesapplaniid,
        Baglicariid: Baglicariid,
        Komisyoncucariid: Komisyoncucariid,
        Hesapno: Hesapno,
        Iban: Iban,
        Bankaaciklama: Bankaaciklama,
        Efaturaalias: Efaturaalias,
        Eirsaliyealias: Eirsaliyealias,
        Efaturaiban: Efaturaiban,
        Kosulkodu: Kosulkodu,
        Vat: Vat,
        Kurumsalfax: Kurumsalfax,
        Kurumsalmobil: Kurumsalmobil,
        Kurumsalweb: Kurumsalweb,
        Kurumsalemail: Kurumsalemail,
        Yetkiliunvan: Yetkiliunvan,
        Yetkiliad: Yetkiliad,
        Yetkiliemail: Yetkiliemail,
        Yetkilitel: Yetkilitel,
        Ortakkod: Ortakkod,
        Muhasebeortakkod: Muhasebeortakkod,
        Efaturamukkellefi: Efaturamukkellefi,
        Eirsaliyemukkellefi: Eirsaliyemukkellefi,
        Riskkontroluvar: Riskkontroluvar,
        Plasiyerortak: Plasiyerortak,
      );
}
