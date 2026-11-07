import 'services/auth/authorization_session.dart';
import 'widgets/permission_page.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
export 'theme/theme_controller.dart' show themeNotifier;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
//import 'pages/login/login_page.dart';
import 'pages/splash/splash_page.dart';
import 'pages/fatura/Satisfaturasi/satisfatura_detay_page.dart';
import 'config/api_config.dart';
import 'services/offline/offline_service.dart';
import 'services/cache/list_cache_service.dart';

// Tema kontrolcüsü (light / dark)

// Uygulama versiyonu — pubspec.yaml'dan otomatik okunur
String appVersion = "";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await ApiConfig.init();
  await ThemeController.load();
  await AuthorizationSession.instance.restore();
  await OfflineService.instance.init();
  await ListCacheService.instance.init();
  final info = await PackageInfo.fromPlatform();
  appVersion = info.version;
  runApp(const RotakodApp());
}

class RotakodApp extends StatelessWidget {
  const RotakodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([themeNotifier, designNotifier]),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FilERP Mobile',
          themeMode: themeNotifier.value, // Tema buradan değişiyor
          theme: AppTheme.build(Brightness.light, design: designNotifier.value),
          darkTheme:
              AppTheme.build(Brightness.dark, design: designNotifier.value),
          routes: {
            "/satis-fatura-detay": (context) =>
                const PermissionPage(child: SatisFaturaDetayPage()),
          },
          home: const SplashPage(),
        );
      },
    );
  }
}
