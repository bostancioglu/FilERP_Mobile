import 'package:flutter/material.dart';

class YetkiHatasiWidget extends StatelessWidget {
  final String? mesaj;
  final VoidCallback? onYenile;
  const YetkiHatasiWidget({super.key, this.mesaj, this.onYenile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.lock_outline_rounded,
                          color: scheme.onErrorContainer, size: 22)),
                  const SizedBox(height: 12),
                  Text('Yetkisiz İşlem',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface)),
                  const SizedBox(height: 6),
                  Text(mesaj ?? 'Bu işlem için yetkiniz yok.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  if (onYenile != null) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                        onPressed: onYenile,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Tekrar Dene'))
                  ],
                ]))));
  }
}
