import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import '../proje/proje_dto.dart';
import '../cari/referans_dto.dart';
import '../dosya/dosyabelge_dto.dart';
import 'talephareket_dto.dart';

class TalepDto {
  String? id; // Guid → String

  int? firmaid;
  int? sirketid;
  int? subeid;
  int? kullaniciid;
  int? projeid;
  int? referansid;

  String? belgeserino;
  int? belgeyil;
  String? belgeseri;
  String? belgeno;

  DateTime? tarih;
  DateTime? istenentarih;
  DateTime? teslimtarihi;

  int? belgeturu;
  String? aciklama;

  bool? onayagonderildi;
  int? onaydurum;
  int? oncelik;
  int? teslimattipi;
  bool? onaylanabilir;
  bool? onaykaldirilabilir;

  int? localerpentegrasyondurum;
  int? localerpdenkilitli;
  int? belgedurum;

  // Navigation
  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;
  ProjeDto? proje;
  ReferansDto? referans;

  List<TalephareketDto>? talephareket;
  List<DosyabelgeDto>? belge;

  TalepDto();

  TalepDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"]?.toString();

    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    subeid = json["Subeid"];
    kullaniciid = json["Kullaniciid"];
    projeid = json["Projeid"];
    referansid = json["Referansid"];

    belgeserino = json["Belgeserino"];
    belgeyil = json["Belgeyil"];
    belgeseri = json["Belgeseri"];
    belgeno = json["Belgeno"];

    tarih = json["Tarih"] != null ? DateTime.parse(json["Tarih"]) : null;
    istenentarih =
        json["Istenentarih"] != null ? DateTime.parse(json["Istenentarih"]) : null;
    teslimtarihi =
        json["Teslimtarihi"] != null ? DateTime.parse(json["Teslimtarihi"]) : null;

    belgeturu = json["Belgeturu"];
    aciklama = json["Aciklama"];

    onayagonderildi = json["Onayagonderildi"];
    onaydurum = json["Onaydurum"];
    oncelik = json["Oncelik"];
    teslimattipi = json["Teslimattipi"];
    onaylanabilir = json["Onaylanabilir"];
    onaykaldirilabilir = json["Onaykaldirilabilir"];

    localerpentegrasyondurum = json["Localerpentegrasyondurum"];
    localerpdenkilitli = json["Localerpdenkilitli"];
    belgedurum = json["Belgedurum"];

    firma =
        json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket =
        json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    sube =
        json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null;
    proje =
        json["Proje"] != null ? ProjeDto.fromJson(json["Proje"]) : null;
    referans = json["Referans"] != null
        ? ReferansDto.fromJson(json["Referans"])
        : null;

    talephareket = (json["Talephareket"] as List?)
        ?.map((e) => TalephareketDto.fromJson(e))
        .toList();

    belge = (json["Belge"] as List?)
        ?.map((e) => DosyabelgeDto.fromJson(e))
        .toList();
  }
}
