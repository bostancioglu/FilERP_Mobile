import 'package:http/http.dart' as http;
import 'dart:convert';

mixin ApiErrorParser {
  String parseApiError(http.Response res) {
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      // Errors array varsa birleştir
      final errors = body["Errors"];
      if (errors is List && errors.isNotEmpty) {
        return errors.join(", ");
      }
      return body["Message"]?.toString() ??
             body["message"]?.toString() ??
             body["error"]?.toString()   ??
             "İşlem sırasında hata oluştu (${res.statusCode})";
    } catch (_) {
      return "İşlem sırasında hata oluştu (${res.statusCode})";
    }
  }
}