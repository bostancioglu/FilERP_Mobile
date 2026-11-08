import 'package:FilERP/widgets/corporate_menu_icon.dart';
import '../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../theme/theme_controller.dart';

class TemaSecimPage extends StatelessWidget {
  const TemaSecimPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar:
            ErpPageAppBar(context: context, title: const Text('Tema Seçimi')),
        body: AnimatedBuilder(
            animation: Listenable.merge([designNotifier, themeNotifier]),
            builder: (context, _) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final design in ErpDesign.values)
                      Card(
                          clipBehavior: Clip.antiAlias,
                          child: RadioListTile<ErpDesign>(
                            key: ValueKey('design-${design.name}'),
                            value: design,
                            groupValue: designNotifier.value,
                            onChanged: (value) {
                              if (value != null)
                                ThemeController.setDesign(value);
                            },
                            title: Text(design == ErpDesign.classic
                                ? 'FilERP Klasik'
                                : 'FilERP Modern'),
                            subtitle: Padding(
                                padding:
                                    const EdgeInsets.only(top: 12, bottom: 8),
                                child: Container(
                                  height: 76,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: design == ErpDesign.classic
                                          ? const Color(0xFFF4F6FA)
                                          : const Color(0xFF14213D),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Row(children: [
                                    for (final color
                                        in (design == ErpDesign.classic
                                            ? [
                                                const Color(0xFFCC1626),
                                                const Color(0xFFCC1626),
                                                const Color(0xFFCC1626)
                                              ]
                                            : [
                                                const Color(0xFF2563EB),
                                                const Color(0xFF16A34A),
                                                const Color(0xFFF59E0B)
                                              ]))
                                      Expanded(
                                          child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4),
                                              decoration: BoxDecoration(
                                                  color: color,
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              child: const CorporateMenuIcon(
                                                  'Tema',
                                                  size: 26,
                                                  onColoredSurface: true))),
                                  ]),
                                )),
                          )),
                    const SizedBox(height: 20),
                    const Text('Görünüm',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    for (final mode in ThemeMode.values)
                      RadioListTile<ThemeMode>(
                          value: mode,
                          groupValue: themeNotifier.value,
                          title: Text(switch (mode) {
                            ThemeMode.system => 'Sistem',
                            ThemeMode.light => 'Açık',
                            ThemeMode.dark => 'Koyu'
                          }),
                          onChanged: (value) {
                            if (value != null) ThemeController.setMode(value);
                          }),
                  ],
                )),
      );
}
