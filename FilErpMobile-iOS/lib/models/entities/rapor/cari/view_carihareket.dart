class ViewCarihareket {
  int?      firmaid;
  int?      sirketid;
  int?      subeid;
  String?   carikod;
  String?   cariisim;
  int?      cariid;
  String?   id;
  DateTime? tarih;
  String?   belgeid;
  int?      belgeturu;
  String?   belgeno;
  String?   aciklama;
  DateTime? vadetarih;
  String?   dovizbirim;
  double?   kur;
  String?   bakiyedurum;
  double?   borctutar;
  double?   alacaktutar;
  double?   borcbakiye;
  double?   alacakbakiye;
  double?   dovizborctutar;
  double?   dovizalacaktutar;
  double?   dovizborcbakiye;
  double?   dovizalacakbakiye;
  String?   plasiyerisim;
  int?      projeid;
  String?   projekodu;

  ViewCarihareket.fromJson(Map<String, dynamic> j) {
    firmaid          = j["Firmaid"];
    sirketid         = j["Sirketid"];
    subeid           = j["Subeid"];
    carikod          = j["carikod"];
    cariisim         = j["cariisim"];
    cariid           = j["cariid"];
    id               = j["Id"]?.toString();
    tarih            = j["Tarih"]     != null ? DateTime.parse(j["Tarih"])     : null;
    belgeid          = j["Belgeid"]?.toString();
    belgeturu        = j["Belgeturu"];
    belgeno          = j["Belgeno"];
    aciklama         = j["Aciklama"];
    vadetarih        = j["vadetarih"] != null ? DateTime.parse(j["vadetarih"]) : null;
    dovizbirim       = j["Dovizbirim"];
    kur              = (j["Kur"]              as num?)?.toDouble();
    bakiyedurum      = j["Bakiyedurum"];
    borctutar        = (j["Borctutar"]        as num?)?.toDouble();
    alacaktutar      = (j["Alacaktutar"]      as num?)?.toDouble();
    borcbakiye       = (j["Borcbakiye"]       as num?)?.toDouble();
    alacakbakiye     = (j["Alacakbakiye"]     as num?)?.toDouble();
    dovizborctutar   = (j["Dovizborctutar"]   as num?)?.toDouble();
    dovizalacaktutar = (j["Dovizalacaktutar"] as num?)?.toDouble();
    dovizborcbakiye  = (j["Dovizborcbakiye"]  as num?)?.toDouble();
    dovizalacakbakiye = (j["Dovizalacakbakiye"] as num?)?.toDouble();
    plasiyerisim     = j["Plasiyerisim"];
    projeid          = j["Projeid"];
    projekodu        = j["Projekodu"];
  }
}