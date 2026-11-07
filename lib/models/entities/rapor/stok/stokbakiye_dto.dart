class StokbakiyeDto {
  int?    stokid;
  String? kod;
  String? ad;
  String? olcubr;
  double? toplamGirismiktar;
  double? toplamCikismiktar;
  double? toplamBakiyemiktar;

  StokbakiyeDto.fromJson(Map<String, dynamic> j) {
    stokid              = j["Stokid"];
    kod                 = j["Kod"];
    ad                  = j["Ad"];
    olcubr              = j["Olcubr"];
    toplamGirismiktar   = (j["ToplamGirismiktar"]  as num?)?.toDouble();
    toplamCikismiktar   = (j["ToplamCikismiktar"]  as num?)?.toDouble();
    toplamBakiyemiktar  = (j["ToplamBakiyemiktar"] as num?)?.toDouble();
  }
}
