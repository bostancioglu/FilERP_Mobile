import 'package:flutter/material.dart';

/// Visible, touch-friendly actions for the app's standard alert dialogs.
class ErpDialogAction extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool secondary;
  const ErpDialogAction(
      {super.key,
      required this.onPressed,
      required this.child,
      this.style,
      this.secondary = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = child is Text
        ? ((child as Text).data ?? '').replaceAll('İ', 'I').toLowerCase().trim()
        : '';
    final isSecondary = secondary ||
        const [
          'vazgeç',
          'iptal',
          'kapat',
          'hayır',
          'geri',
          'sonra',
          'daha sonra'
        ].contains(label);
    final destructive = label.contains('sil') && !label.contains('tahsil');
    final accent = destructive ? scheme.error : scheme.primary;
    final foreground = destructive ? scheme.onError : scheme.onPrimary;
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final buttonStyle = (style ?? const ButtonStyle()).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(96, 44)),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
      shape: WidgetStatePropertyAll(shape),
      foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: .38)
              : isSecondary
                  ? scheme.onSurfaceVariant
                  : foreground),
      backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: .12)
              : isSecondary
                  ? scheme.surface
                  : accent),
      side: WidgetStatePropertyAll(BorderSide(
          color: isSecondary ? scheme.outlineVariant : Colors.transparent)),
    );
    // Text widgets sometimes carry old hardcoded action colors. Use the button's
    // contrast color without changing other typography or non-text children.
    final content = child is Text && (child as Text).data != null
        ? Text((child as Text).data!,
            style: (child as Text).style?.copyWith(
                color: isSecondary ? scheme.onSurfaceVariant : foreground),
            textAlign: TextAlign.center)
        : child;
    return isSecondary
        ? OutlinedButton(
            onPressed: onPressed, style: buttonStyle, child: content)
        : FilledButton(
            onPressed: onPressed, style: buttonStyle, child: content);
  }
}
