class LoginResponse {
  final dynamic errors;
  final LoginData? data;

  LoginResponse({this.errors, this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      errors: json["errors"],
      data: json["data"] != null ? LoginData.fromJson(json["data"]) : null,
    );
  }
}

class LoginData {
  final String token;
  final List<SirketModel> sirketler;

  LoginData({required this.token, required this.sirketler});

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      token: json["token"],
      sirketler: json["sirketler"] != null
          ? (json["sirketler"] as List)
              .map((e) => SirketModel.fromJson(e))
              .toList()
          : [],
    );
  }
}

class SirketModel {
  final String sirketKodu;
  final String sirketAdi;
  final List<SubeModel> subeler;

  SirketModel({
    required this.sirketKodu,
    required this.sirketAdi,
    required this.subeler,
  });

  factory SirketModel.fromJson(Map<String, dynamic> json) {
    return SirketModel(
      sirketKodu: json["sirketKodu"],
      sirketAdi: json["sirketAdi"],
      subeler: json["subeler"] != null
          ? (json["subeler"] as List)
              .map((e) => SubeModel.fromJson(e))
              .toList()
          : [],
    );
  }
}

class SubeModel {
  final String subeKodu;
  final String subeAdi;

  SubeModel({
    required this.subeKodu,
    required this.subeAdi,
  });

  factory SubeModel.fromJson(Map<String, dynamic> json) {
    return SubeModel(
      subeKodu: json["subeKodu"],
      subeAdi: json["subeAdi"],
    );
  }
}
