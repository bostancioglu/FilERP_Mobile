import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../models/entities/adres/ulke_dto.dart';
import '../../models/entities/adres/il_dto.dart';
import '../../models/entities/adres/ilce_dto.dart';

class AdresService {
  Future<List<UlkeDto>> getUlkeler(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Adres/Ulke/All"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    final body = json.decode(res.body);
    return (body["Data"] as List)
        .map((e) => UlkeDto.fromJson(e))
        .toList();
  }

Future<List<IlDto>> getIller(String token, int ulkeId) async {
  final res = await http.get(
    Uri.parse("${ApiConfig.baseUrl}/Adres/Il/GetByUlkeId/$ulkeId"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );



  if (res.statusCode != 200) {
    throw Exception("İl servisi hata verdi");
  }

  final body = json.decode(res.body);


  if (body["Data"] == null) {
    return [];
  }

  if (body["Data"] is! List) {
    throw Exception("İl Data List değil");
  }

  return (body["Data"] as List)
      .map((e) => IlDto.fromJson(e))
      .toList();
}


  Future<List<IlceDto>> getIlceler(String token, int ilId) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Adres/Ilce/GetByIlId/$ilId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final body = json.decode(res.body);
    if (body["Data"] == null) return [];
    if (body["Data"] is! List) return [];

    return (body["Data"] as List)
        .map((e) => IlceDto.fromJson(e))
        .toList();

  }
}
