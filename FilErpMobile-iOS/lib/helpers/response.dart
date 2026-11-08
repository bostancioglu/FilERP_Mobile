import 'dart:convert';
import 'package:http/http.dart' as http;

// Yetki hatası için özel exception
class YetkiHatasi implements Exception {
  final String mesaj;
  const YetkiHatasi([this.mesaj = "Bu işlemi yapmaya yetkiniz bulunmamaktadır."]);
  @override
  String toString() => mesaj;
}

/// API'den gelen hata mesajını çözer
String parseApiError(http.Response res) {
  // Yetki hataları — özel exception fırlat
  if (res.statusCode == 401 || res.statusCode == 403) {
    throw const YetkiHatasi();
  }

  try {
    final body = utf8.decode(res.bodyBytes);
    final json = jsonDecode(body);

    if (json is Map && json["Errors"] is List) {
      final errors = json["Errors"] as List;
      if (errors.isNotEmpty) return errors.join("\n");
    }

    if (json is Map && json["Message"] != null) {
      return json["Message"].toString();
    }
  } catch (e) {
    if (e is YetkiHatasi) rethrow;
  }

  return "İşlem sırasında hata oluştu";
}