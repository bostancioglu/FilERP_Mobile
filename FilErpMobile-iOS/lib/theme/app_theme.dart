import 'package:flutter/material.dart';
import 'theme_controller.dart';

class ErpDesignStyle extends ThemeExtension<ErpDesignStyle> {
  final ErpDesign design;
  const ErpDesignStyle(this.design);
  @override
  ErpDesignStyle copyWith({ErpDesign? design}) =>
      ErpDesignStyle(design ?? this.design);
  @override
  ErpDesignStyle lerp(covariant ErpDesignStyle? other, double t) =>
      t < .5 ? this : other ?? this;
  static bool modern(BuildContext context) =>
      Theme.of(context).extension<ErpDesignStyle>()?.design == ErpDesign.modern;
}

/// FilERP Mobile ortak renkleri ve bileşen stilleri.
class AppTheme {
  static const brand = Color(0xFFCC1626);
  static const ink = Color(0xFF17243B);
  static const background = Color(0xFFF4F6FA);

  static ThemeData build(Brightness brightness,
      {ErpDesign design = ErpDesign.classic}) {
    final modern = design == ErpDesign.modern;
    final accent = modern ? const Color(0xFF3949AB) : brand;
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      primary: modern
          ? (dark ? const Color(0xFFB5BFFF) : accent)
          : (dark ? const Color(0xFFFF8790) : brand),
      surface: dark ? const Color(0xFF182337) : Colors.white,
      onSurface: dark ? const Color(0xFFE8EDF5) : ink,
    ).copyWith(
      surfaceContainerLow: dark ? const Color(0xFF202E43) : background,
      surfaceContainerHighest:
          dark ? const Color(0xFF29384D) : const Color(0xFFE9EDF3),
      outlineVariant: dark ? const Color(0xFF344258) : const Color(0xFFE0E5ED),
      onSurfaceVariant:
          dark ? const Color(0xFFAEBBD0) : const Color(0xFF66758A),
    );
    final styled = modern
        ? scheme.copyWith(
            surface: dark ? const Color(0xFF1B2233) : Colors.white,
            onSurface: dark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
            onSurfaceVariant:
                dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            outlineVariant:
                dark ? const Color(0xFF2A3347) : const Color(0xFFE5E7EB),
          )
        : scheme;
    if (modern) return _modern(brightness, styled);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    return ThemeData(
      extensions: const [ErpDesignStyle(ErpDesign.classic)],
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF101827) : background,
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            color: scheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700),
      ),
      cardTheme:
          CardThemeData(elevation: 0, color: scheme.surface, shape: shape),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: dark ? const Color(0xFF202E43) : background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.primary, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              shape: shape, minimumSize: const Size(48, 50))),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: shape,
        minimumSize: const Size(48, 50),
      )),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: shape,
      ),
      dialogTheme: DialogThemeData(
          backgroundColor: scheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: scheme.surface,
          showDragHandle: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
      dividerTheme: DividerThemeData(
          color: scheme.outlineVariant.withValues(alpha: 0.5), space: 1),
      snackBarTheme:
          SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: shape),
    );
  }

  static ThemeData _modern(Brightness brightness, ColorScheme scheme) {
    final dark = brightness == Brightness.dark;
    final base = build(brightness);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final fieldShape = OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant));
    return base.copyWith(
      extensions: const [ErpDesignStyle(ErpDesign.modern)],
      colorScheme: scheme,
      textTheme: base.textTheme
          .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      scaffoldBackgroundColor:
          dark ? const Color(0xFF0F1420) : const Color(0xFFF4F6FB),
      appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          titleTextStyle: TextStyle(
              fontFamily: 'Roboto',
              color: scheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
      cardTheme:
          CardThemeData(color: scheme.surface, elevation: 0, shape: shape),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
          fillColor: dark ? const Color(0xFF202A3E) : Colors.white,
          border: fieldShape,
          enabledBorder: fieldShape,
          focusedBorder: fieldShape.copyWith(
              borderSide: BorderSide(color: scheme.primary, width: 1.5))),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              shape: shape,
              minimumSize: const Size(48, 48))),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              elevation: 0,
              shape: shape,
              minimumSize: const Size(48, 48))),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
          backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary),
      dialogTheme: base.dialogTheme
          .copyWith(backgroundColor: scheme.surface, shape: shape),
      bottomSheetTheme:
          base.bottomSheetTheme.copyWith(backgroundColor: scheme.surface),
      dividerTheme: base.dividerTheme.copyWith(color: scheme.outlineVariant),
    );
  }
}
