import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:flutter/material.dart';
import 'response.dart';

/// Uygulama genelinde standart geri bildirim servisi.
class UiFeedback {
  static Future<void> showSuccess(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 2),
      bool autoPop = false}) async {
    await _show(context, _ToastType.success, message, duration);
    if (autoPop && context.mounted) Navigator.pop(context, true);
  }

  static Future<void> showError(BuildContext context, String message,
          {Duration duration = const Duration(seconds: 3)}) =>
      _show(context, _ToastType.error, message, duration);

  /// Hata tipine göre otomatik karar — YetkiHatasi ise dialog, diğerleri toast
  static Future<void> showException(BuildContext context, Object e,
      {VoidCallback? onYenile}) async {
    if (e is YetkiHatasi) {
      await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('Yetkisiz İşlem'),
                content: const Text('Bu işlem için yetkiniz yok.'),
                scrollable: true,
                actions: [
                  if (onYenile != null)
                    ErpDialogAction(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onYenile();
                        },
                        child: const Text('Tekrar Dene')),
                  ErpDialogAction(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tamam'))
                ],
              ));
    } else {
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      await showError(context, msg);
    }
  }

  static Future<void> showWarning(BuildContext context, String message,
          {Duration duration = const Duration(seconds: 3)}) =>
      _show(context, _ToastType.warning, message, duration);

  static Future<void> showInfo(BuildContext context, String message,
          {Duration duration = const Duration(seconds: 2)}) =>
      _show(context, _ToastType.info, message, duration);

  /// Silme işlemi sonrası — çöp kutusu ikonu, kırmızı ton
  static Future<void> showDeleted(BuildContext context, String message,
          {Duration duration = const Duration(seconds: 2)}) =>
      _showCustom(context, message, Icons.delete_rounded,
          const Color(0xFFDC2626), duration);

  /// Güncelleme sonrası — kalem ikonu, mavi ton
  static Future<void> showUpdated(BuildContext context, String message,
          {Duration duration = const Duration(seconds: 2)}) =>
      _showCustom(context, message, Icons.edit_rounded, const Color(0xFF2563EB),
          duration);

  /// Yeni kayıt sonrası — belge + check ikonu, yeşil ton
  static Future<void> showSaved(BuildContext context, String message,
          {Duration duration = const Duration(seconds: 2)}) =>
      _showCustom(context, message, Icons.task_alt_rounded,
          const Color(0xFF16A34A), duration);

  /// Portala gönderme sonrası — bulut ikonu, mor ton
  static Future<void> showSent(BuildContext context, String message,
          {Duration duration = const Duration(seconds: 2)}) =>
      _showCustom(context, message, Icons.cloud_done_rounded,
          const Color(0xFF7C3AED), duration);

  static Future<bool> confirm(BuildContext context,
      {required String title,
      required String message,
      String confirmLabel = 'Evet',
      String cancelLabel = 'Vazgeç',
      bool destructive = false}) async {
    final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final scheme = Theme.of(ctx).colorScheme;
          final exiting = title.toLowerCase().contains('çık');
          final accent = destructive ? scheme.error : scheme.primary;
          final foreground = destructive ? scheme.onError : scheme.onPrimary;
          return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                            color:
                                                accent.withValues(alpha: .12),
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        child: Icon(
                                            exiting
                                                ? Icons.logout_rounded
                                                : destructive
                                                    ? Icons
                                                        .delete_outline_rounded
                                                    : Icons.task_alt_rounded,
                                            color: accent,
                                            size: 26))),
                                const SizedBox(height: 18),
                                Text(title,
                                    style: TextStyle(
                                        color: scheme.onSurface,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 10),
                                Text(message,
                                    style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 14,
                                        height: 1.5)),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: FilledButton.styleFrom(
                                        backgroundColor: accent,
                                        foregroundColor: foreground,
                                        minimumSize: const Size.fromHeight(48),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    icon: Icon(
                                        exiting
                                            ? Icons.logout_rounded
                                            : destructive
                                                ? Icons.delete_outline_rounded
                                                : Icons.check_rounded,
                                        size: 19),
                                    label: Text(confirmLabel)),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            scheme.onSurfaceVariant,
                                        side: BorderSide(
                                            color: scheme.outlineVariant),
                                        minimumSize: const Size.fromHeight(46),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    child: Text(cancelLabel)),
                              ])))));
        });
    return result ?? false;
  }

  static OverlayEntry showLoading(BuildContext context, {String? text}) {
    final entry = OverlayEntry(builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return Stack(children: [
        ModalBarrier(
            color: Colors.black.withValues(alpha: .3), dismissible: false),
        Center(
            child: Material(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          if (text != null) ...[
                            const SizedBox(width: 12),
                            Flexible(
                                child: Text(text,
                                    style: TextStyle(
                                        fontSize: 13, color: scheme.onSurface)))
                          ]
                        ])))))
      ]);
    });
    Overlay.of(context).insert(entry);
    return entry;
  }

  static void hideLoading(OverlayEntry entry) => entry.remove();

  static Future<void> _show(BuildContext context, _ToastType type,
      String message, Duration duration) async {
    final cfg = _config(type);
    await _showCustom(context, message, cfg.icon, cfg.color, duration);
  }

  static Future<void> _showCustom(BuildContext context, String message,
      IconData icon, Color color, Duration duration) async {
    OverlayEntry? entry;
    entry = OverlayEntry(
        builder: (_) => _ToastWidget(
            message: message,
            icon: icon,
            accentColor: color,
            onDismiss: () {
              try {
                entry?.remove();
              } catch (_) {}
            },
            duration: duration));
    Overlay.of(context).insert(entry);
    await Future.delayed(duration + const Duration(milliseconds: 350));
    try {
      entry.remove();
    } catch (_) {}
  }

  static _ToastConfig _config(_ToastType t) {
    switch (t) {
      case _ToastType.success:
        return _ToastConfig(
            Icons.check_circle_rounded, const Color(0xFF16A34A));
      case _ToastType.error:
        return _ToastConfig(Icons.cancel_rounded, const Color(0xFFDC2626));
      case _ToastType.warning:
        return _ToastConfig(Icons.warning_rounded, const Color(0xFFD97706));
      case _ToastType.info:
        return _ToastConfig(Icons.info_rounded, const Color(0xFF2563EB));
    }
  }
}

enum _ToastType { success, error, warning, info }

class _ToastConfig {
  final IconData icon;
  final Color color;
  const _ToastConfig(this.icon, this.color);
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onDismiss;
  final Duration duration;
  const _ToastWidget(
      {required this.message,
      required this.icon,
      required this.accentColor,
      required this.onDismiss,
      required this.duration});
  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _accent => Theme.of(context).brightness == Brightness.dark
      ? HSLColor.fromColor(widget.accentColor).withLightness(.76).toColor()
      : widget.accentColor;
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _ctrl.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _scheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.13),
                        blurRadius: 20,
                        offset: const Offset(0, 4))
                  ],
                  border: Border.all(color: _scheme.outlineVariant),
                ),
                child: Row(children: [
                  Container(
                      width: 4,
                      height: 28,
                      decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 12),
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: _accent.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Icon(widget.icon, color: _accent, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(widget.message,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _scheme.onSurface,
                              decoration: TextDecoration.none))),
                  Icon(Icons.close_rounded,
                      size: 16, color: _scheme.onSurfaceVariant),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
