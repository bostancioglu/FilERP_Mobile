import 'package:FilERP/theme/theme_controller.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/pages/ayarlar/ayarlar_page.dart';
import 'package:FilERP/services/cache/list_cache_service.dart';
import 'package:FilERP/services/offline/offline_service.dart';
import 'report_center_screens_test.dart' as previews;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  setUpAll(() async {
    cache = await Directory.systemTemp.createTemp('settings_theme_');
    Hive.init(cache.path);
    await ListCacheService.instance.init();
    SharedPreferences.setMockInitialValues({'offline_mode': false});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (call) async => call.method == 'check' ? ['none'] : null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        (_) async => null);
    await OfflineService.instance.init();
    PackageInfo.setMockInitialValues(
        appName: 'FilERP Mobile',
        packageName: 'com.filerp.rotakod',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '');
    for (final e in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  tearDownAll(() async {
    OfflineService.instance.dispose();
    await Hive.close();
    await cache.delete(recursive: true);
  });
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final populated in [false, true]) {
        testWidgets(
            'settings ${design.name}_${brightness.name} ${populated ? 'populated' : 'empty'}',
            (tester) async {
          SharedPreferences.setMockInitialValues(
              {'token_final': 'preview', 'offline_mode': false});
          await tester.runAsync(() async {
            final box = Hive.box<String>('offline_queue');
            await box.clear();
            await Hive.box<String>('barcode_scan_history').clear();
            if (populated) {
              await box.put(
                  'error',
                  jsonEncode(OfflineQueueItem(
                          localId: 'error',
                          type: 'dat_full',
                          payload: {'Belgeno': 'DAT000001'},
                          createdAt: DateTime.now(),
                          status: 'error',
                          errorMessage: 'Bağlantı kesildi')
                      .toJson()));
            }
          });
          OfflineService.instance.pendingCount.value = populated ? 1 : 0;
          OfflineService.instance.isOnline.value = false;
          OfflineService.instance.offlineMode.value = false;
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          final key = GlobalKey();
          final requests = <http.Request>[];
          await http.runWithClient(() async {
            await tester.runAsync(() async {
              await tester.pumpWidget(RepaintBoundary(
                  key: key,
                  child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.build(brightness, design: design),
                      home: const AyarlarPage())));
              await Future<void>.delayed(const Duration(milliseconds: 500));
            });
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await previews.captureReport(tester, key,
                'settings_general_${design.name}_${brightness.name}');
            await tester.tap(find.byType(Switch).first);
            await tester.pumpAndSettle();
            expect(
                (await SharedPreferences.getInstance()).getBool('offline_mode'),
                isTrue);
            await tester.tap(find.text('Varsayılan Depo'));
            await tester.pumpAndSettle();
            expect(find.text('D01 - Merkez Depo'), findsOneWidget);
            await tester.tap(find.text('D01 - Merkez Depo'));
            await tester.pumpAndSettle();
            expect(
                (await SharedPreferences.getInstance())
                    .getInt('varsayilan_depo_id'),
                1);
            await tester.tap(find.byTooltip('Varsayılan Depo Temizle'));
            await tester.pumpAndSettle();
            expect(
                (await SharedPreferences.getInstance())
                    .getInt('varsayilan_depo_id'),
                isNull);
            await tester.tap(find.text('Kuyruk'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await previews.captureReport(tester, key,
                'settings_queue_${populated}_${design.name}_${brightness.name}');
            if (populated) {
              await tester.tap(find.byTooltip('Kayıt İşlemleri'));
              await tester.pumpAndSettle();
              expect(find.text('Düzenle'), findsOneWidget);
              expect(find.text('Tekrar Dene'), findsOneWidget);
              await tester.tap(find.text('Sil'));
              await tester.pumpAndSettle();
              expect(find.text('Kaydı Sil'), findsOneWidget);
              await tester.tap(find.text('İptal'));
              await tester.pumpAndSettle();
              expect(Hive.box<String>('offline_queue').containsKey('error'),
                  isTrue);
            }
            if (!populated) expect(find.text('Kuyruk boş'), findsOneWidget);
            await tester.tap(find.text('Barkod'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await previews.captureReport(tester, key,
                'settings_barcode_${design.name}_${brightness.name}');
            await tester.ensureVisible(find.text('Kural Ekle'));
            await tester.tap(find.text('Kural Ekle'));
            await tester.pumpAndSettle();
            expect(find.byType(AlertDialog), findsOneWidget);
            tester.view.physicalSize = const Size(320, 740);
            tester.view.viewInsets = const FakeViewPadding(bottom: 300);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.tap(find.text('İptal'));
            tester.view.resetViewInsets();
            await tester.pumpAndSettle();
            for (final tab in ['Genel', 'Kuyruk', 'Barkod']) {
              await tester.tap(find.text(tab));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
            expect(requests.every((r) => r.method == 'GET'), isTrue);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
              () => MockClient((r) async {
                    requests.add(r);
                    Object data = [];
                    if (r.url.path.contains('/Depo'))
                      data = [
                        {'Id': 1, 'Kod': 'D01', 'Ad': 'Merkez Depo'}
                      ];
                    return http.Response(jsonEncode({'Data': data}), 200,
                        headers: {
                          'content-type': 'application/json; charset=utf-8'
                        });
                  }));
        });
      }
    }
  }
}
