class SubeDto {
  int? id;
  int? firmaid;
  int? sirketid;

  String? kod;
  String? ad;

  SubeDto();

  SubeDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    kod = json["Kod"];
    ad = json["Ad"];
  }
}
