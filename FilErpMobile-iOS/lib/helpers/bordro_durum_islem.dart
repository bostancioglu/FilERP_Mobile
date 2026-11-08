import 'package:flutter/material.dart';
import '../services/auth/authorized_http.dart' as http;
import '../services/auth/authorization_session.dart';
import '../services/auth/backend_authorization_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'response.dart';
import 'ui_feedback.dart';

/// Çek/Senet bordro listelerinde karta dokununca açılan "Belgeyi Tamamla / Taslağa Al" işlemi.
/// [prefix]: API controller adı (Cekalinan, Cekalinanciro, Senetverilenodeme ...).
class BordroDurumIslem {
  const BordroDurumIslem._();

  static Future<void> goster(
    BuildContext context, {
    required String prefix,
    required String id,
    required bool taslak,
    required String baslik,
    required VoidCallback yenile,
  }) async {
    final module = controllerModuleIds[prefix.toLowerCase()];
    if (module == null ||
        !AuthorizationSession.instance.can(module, Access.create)) return;
    final tamamla = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(baslik,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          ListTile(
            leading: Icon(
                taslak ? Icons.check_circle_outline : Icons.edit_note_rounded,
                color: taslak ? Colors.green : Colors.orange),
            title: Text(taslak ? 'Belgeyi Tamamla' : 'Taslağa Al'),
            onTap: () => Navigator.pop(ctx, taslak),
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Vazgeç'),
            onTap: () => Navigator.pop(ctx),
          ),
        ]),
      ),
    );
    if (tamamla == null || !context.mounted) return;

    final onay = await UiFeedback.confirm(context,
        title: tamamla ? 'Belgeyi Tamamla' : 'Taslağa Al',
        message: tamamla
            ? 'Belge tamamlanacak (cari/kasa hareketleri oluşacak). Emin misiniz?'
            : 'Belge taslağa alınacak. Emin misiniz?',
        confirmLabel: tamamla ? 'Tamamla' : 'Taslağa Al');
    if (!onay || !context.mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final res = await http.put(
        Uri.parse(
            '${ApiConfig.baseUrl}/$prefix/${tamamla ? 'Complete' : 'BacktoDraft'}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception(parseApiError(res));
      }
      if (!context.mounted) return;
      tamamla
          ? UiFeedback.showUpdated(context, 'Belge tamamlandı')
          : UiFeedback.showWarning(context, 'Belge taslağa alındı');
      yenile();
    } catch (e) {
      if (context.mounted) UiFeedback.showException(context, e);
    }
  }
}
