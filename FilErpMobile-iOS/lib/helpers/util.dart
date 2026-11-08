import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

// ===================JSON GOSTER (opsiyonel) ============//
class JsonUtil {
  /// true => Gönder
  /// false => İptal
  static Future<bool> showJsonPreview(
    BuildContext context,
    Map<String, dynamic> json, {
    String title = "📤 Gönderilen JSON",
  }) async {
    final prettyJson = const JsonEncoder.withIndent('  ').convert(json);

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: SelectableText(
                    prettyJson,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              actions: [
                ErpDialogAction(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("İptal"),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Gönder"),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
