import 'package:FilERP/widgets/corporate_menu_icon.dart';
import '../services/auth/menu_access.dart';
import '../services/auth/authorization_session.dart';
import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

class ErpModuleMenu extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final ErpDesign design;
  const ErpModuleMenu(
      {super.key,
      required this.title,
      required this.items,
      required this.design});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final modern = design == ErpDesign.modern;
    return Dialog(
      backgroundColor: scheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      constraints: const BoxConstraints(maxWidth: 440),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
          color: modern ? const Color(0xFF14213D) : scheme.surface,
          child: Row(children: [
            CorporateMenuIcon(title, size: 27, onColoredSurface: modern),
            const SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: modern ? Colors.white : scheme.onSurface))),
            IconButton(
                tooltip: 'Menüyü Kapat',
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded,
                    size: 21,
                    color: modern ? Colors.white70 : scheme.onSurfaceVariant)),
          ]),
        ),
        Flexible(
            child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final item in items.where((item) =>
                item is! ErpModuleMenuTile ||
                AuthorizationSession.instance.any(item.requiredModules ??
                    MenuAccess.modules(item.title, parent: title))))
              Padding(padding: const EdgeInsets.only(top: 8), child: item)
          ]),
        )),
      ]),
    );
  }
}

class ErpModuleMenuTile extends StatelessWidget {
  final String title;
  final String? asset;
  final IconData? icon;
  final VoidCallback onTap;
  final ErpDesign design;
  final List<int>? requiredModules;
  const ErpModuleMenuTile(
      {super.key,
      required this.title,
      this.asset,
      this.icon,
      this.requiredModules,
      required this.onTap,
      required this.design});

  IconData get _icon {
    if (icon != null) return icon!;
    if (title.contains('Fatura')) return Icons.receipt_long_outlined;
    if (title.contains('İrsaliye')) return Icons.local_shipping_outlined;
    if (title.contains('Sipariş')) return Icons.shopping_bag_outlined;
    if (title.contains('Teklif')) return Icons.request_quote_outlined;
    if (title.contains('Banka')) return Icons.account_balance_outlined;
    if (title.contains('Kasa') || title.contains('Tahsilat'))
      return Icons.payments_outlined;
    if (title.contains('Rapor')) return Icons.insights_rounded;
    if (title.contains('Çek') || title.contains('Senet'))
      return Icons.article_outlined;
    return Icons.inventory_2_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final modern = design == ErpDesign.modern;
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF0EA5A4),
      Color(0xFF7C3AED),
      Color(0xFF0891B2)
    ];
    final accent = modern
        ? colors[title.contains('Alış')
            ? 1
            : title.contains('Satış')
                ? 0
                : title.codeUnits.fold<int>(0, (sum, c) => sum + c) %
                    colors.length]
        : scheme.primary;
    return Material(
      color: modern
          ? scheme.surfaceContainerLow
          : scheme.primary.withValues(alpha: .045),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .6))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(13)),
                  child: CorporateMenuIcon(title, size: 34, fallback: _icon)),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface))),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  size: 18, color: modern ? accent : scheme.onSurfaceVariant),
            ]),
          )),
    );
  }
}
