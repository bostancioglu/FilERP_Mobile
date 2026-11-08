import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;

import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../models/entities/stok/stokcari_create_dto.dart';

class StokcariService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Cari'nin bu malzeme için kullandığı kod/barkod eşleşmesini kaydeder —
  /// bir sonraki "Fatura Tara" (veya XML/e-Fatura) işleminde bu Stokcari
  /// kaydı sayesinde satır otomatik eşleşir.
  Future<void> create(String token, StokcariCreateDto dto) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Stokcari'),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(parseApiError(res));
    }
  }
}
