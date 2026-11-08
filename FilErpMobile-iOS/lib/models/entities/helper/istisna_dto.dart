class IstisnaDto {
  int? id;

  String? aciklama;
  String? kod;
  int? tip;

  IstisnaDto();

  IstisnaDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    aciklama = json["Aciklama"];
    kod = json["Kod"];
    tip = json["Tip"];
  }
}
