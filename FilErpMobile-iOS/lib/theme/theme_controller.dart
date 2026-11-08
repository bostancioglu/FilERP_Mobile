import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ErpDesign { classic, modern }

final designNotifier = ValueNotifier<ErpDesign>(ErpDesign.classic);
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

class ThemeController {
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    designNotifier.value = prefs.getString('erp_design') == 'modern'
        ? ErpDesign.modern
        : ErpDesign.classic;
    themeNotifier.value = switch (prefs.getString('erp_brightness')) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light
    };
  }

  static Future<void> setDesign(ErpDesign design) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('erp_design', design.name);
    designNotifier.value = design;
  }

  static Future<void> setMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('erp_brightness', mode.name);
    themeNotifier.value = mode;
  }
}
