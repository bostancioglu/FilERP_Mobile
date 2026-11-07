class SirketDto {
  int? id;
  int? firmaid;

  String? kod;
  String? ad;

  SirketDto();

  SirketDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    firmaid = json["Firmaid"];
    kod = json["Kod"];
    ad = json["Ad"];
  }
}
