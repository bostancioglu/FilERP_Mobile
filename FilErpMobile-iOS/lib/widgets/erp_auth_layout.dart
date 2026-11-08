import 'package:flutter/material.dart';

class ErpAuthLayout extends StatelessWidget {
  static ThemeData themeFor(BuildContext context) {
    final base = Theme.of(context);
    final dark = base.brightness == Brightness.dark;
    final scheme = dark
        ? base.colorScheme.copyWith(
            primary: const Color(0xFFEE3445),
            onPrimary: Colors.white,
            surface: const Color(0xFF111113),
            onSurface: const Color(0xFFF4F4F5),
            onSurfaceVariant: const Color(0xFF96969F),
            surfaceContainerLow: const Color(0xFF19191D),
            surfaceContainerHighest: const Color(0xFF242429),
            outlineVariant: const Color(0xFF2B2B31),
          )
        : base.colorScheme.copyWith(
            primary: const Color(0xFFEE3445), onPrimary: Colors.white);
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF080809) : base.scaffoldBackgroundColor,
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: dark ? const Color(0xFF19191D) : scheme.surfaceContainerLow,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.outlineVariant)),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      )),
      bottomSheetTheme:
          base.bottomSheetTheme.copyWith(backgroundColor: scheme.surface),
      dialogTheme: base.dialogTheme.copyWith(backgroundColor: scheme.surface),
    );
  }

  final Widget child;
  final Widget? footer;
  final VoidCallback? onBrandLongPress;
  const ErpAuthLayout(
      {super.key, required this.child, this.footer, this.onBrandLongPress});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
          child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - 56)
                              .clamp(0, double.infinity)),
                      child: Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 380),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  GestureDetector(
                                      key: const ValueKey('auth-brand'),
                                      onLongPress: onBrandLongPress,
                                      behavior: HitTestBehavior.opaque,
                                      child: Row(children: [
                                        Container(
                                            width: 64,
                                            height: 64,
                                            padding: const EdgeInsets.all(1),
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                border: Border.all(
                                                    color:
                                                        scheme.outlineVariant)),
                                            child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(17),
                                                child: Image.asset(
                                                    'assets/images/logo_filerp.png'))),
                                        const SizedBox(width: 14),
                                        Expanded(
                                            child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .baseline,
                                                    textBaseline:
                                                        TextBaseline.alphabetic,
                                                    children: [
                                                      Text('FilERP',
                                                          style: TextStyle(
                                                              fontSize: 36,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              letterSpacing:
                                                                  -1.5,
                                                              color: scheme
                                                                  .onSurface)),
                                                      const SizedBox(width: 10),
                                                      Text('Mobile',
                                                          style: TextStyle(
                                                              fontSize: 22,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: scheme
                                                                  .onSurfaceVariant)),
                                                    ]))),
                                      ])),
                                  const SizedBox(height: 36),
                                  child,
                                  if (footer != null) ...[
                                    const SizedBox(height: 24),
                                    footer!
                                  ],
                                ])),
                      ),
                    ),
                  ))),
    );
  }
}
