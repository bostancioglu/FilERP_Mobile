import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;

/// Anthropic Claude API çağrıları (fatura okuma / genel görüntü anlama).
///
/// GEÇİCİ mobil-taraflı çözüm — bkz. AiSettingsService yorumu. API anahtarı
/// dışarıdan (kullanıcının Ayarlar > Yapay Zekâ ekranına girdiği) parametre
/// olarak alınır, hiçbir yerde sabit kodlanmaz.
class AnthropicService {
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-5';
  static const _testModel = 'claude-haiku-4-5-20251001';

  Map<String, String> _headers(String apiKey) => {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      };

  /// API key'in geçerli olup olmadığını hızlıca test eder.
  /// Başarılıysa null döner, hata varsa kullanıcıya gösterilecek mesajı döner.
  Future<String?> testConnection(String apiKey) async {
    try {
      final res = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers(apiKey),
        body: jsonEncode({
          'model': _testModel,
          'max_tokens': 10,
          'messages': [
            {'role': 'user', 'content': 'ok'}
          ],
        }),
      );
      if (res.statusCode == 200) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      return body['error']?['message']?.toString() ?? 'Bilinmeyen hata (HTTP ${res.statusCode})';
    } catch (e) {
      return 'Bağlantı hatası: $e';
    }
  }

  /// Fatura görselini (PDF veya JPEG/PNG) gönderip yapılandırılmış veri çıkarır.
  /// [bytes]: dosya içeriği, [mediaType]: 'application/pdf' | 'image/jpeg' | 'image/png'.
  /// Dönen [AnthropicExtractResult] ham metni ve (varsa) parse edilmiş JSON'u içerir.
  Future<AnthropicExtractResult> extractInvoice({
    required String apiKey,
    required List<int> bytes,
    required String mediaType,
  }) async {
    final b64 = base64Encode(bytes);
    final contentType = mediaType == 'application/pdf' ? 'document' : 'image';

    const prompt = 'Bu bir alış faturası görseli/belgesi. İçindeki bilgileri SADECE '
        'aşağıdaki JSON şemasına uygun, başka hiçbir açıklama eklemeden döndür:\n'
        '{"faturaNo":"","faturaTarihi":"gg-aa-yyyy","gonderenUnvan":"","gonderenVkn":"",'
        '"aliciUnvan":"","aliciVkn":"","kalemler":[{"ad":"","miktar":0,"birim":"",'
        '"birimFiyat":0,"kdvOrani":0,"tutar":0}],"araToplam":0,"kdvToplam":0,"genelToplam":0}\n'
        'Emin olamadığın alanları boş bırak, uydurma değer yazma.';

    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers(apiKey),
      body: jsonEncode({
        'model': _model,
        'max_tokens': 2000,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': contentType,
                'source': {'type': 'base64', 'media_type': mediaType, 'data': b64},
              },
              {'type': 'text', 'text': prompt},
            ],
          }
        ],
      }),
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final msg = body['error']?['message']?.toString() ?? 'HTTP ${res.statusCode}';
      throw Exception(msg);
    }

    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final blocks = (body['content'] as List?) ?? [];
    final textBlock = blocks.firstWhere(
      (b) => b['type'] == 'text',
      orElse: () => null,
    );
    final rawText = textBlock?['text']?.toString() ?? '';

    // Model çoğunlukla ```json ... ``` bloğu içinde döner — temizle.
    final cleaned = rawText.replaceAll(RegExp(r'^```json\s*|```\s*$', multiLine: true), '').trim();

    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      parsed = null;
    }

    return AnthropicExtractResult(rawText: rawText, data: parsed);
  }
}

class AnthropicExtractResult {
  final String rawText;
  final Map<String, dynamic>? data;
  const AnthropicExtractResult({required this.rawText, this.data});
}
