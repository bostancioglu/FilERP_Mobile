import 'package:FilERP/theme/theme_controller.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/pages/rapor/rapor_tanimlari.dart';
import 'package:FilERP/pages/rapor/ortak/rapor_sayfasi.dart';
import 'package:FilERP/pages/rapor/kasa/kasa_sondurum_raporu.dart';
import 'report_center_screens_test.dart' as previews;

Object dataFor(String path) {
  if (path.contains('Faturairsaliyeicmali'))
    return [
      {
        'Belgeno': 'SF2026000000001',
        'Cariisim': 'Marmara Gıda',
        'Carikod': 'CR.001',
        'Belgeturu': 1,
        'Tarih': '2026-10-29',
        'Geneltoplam': 2400,
        'Parabirimi': 'TL'
      },
      {
        'Belgeno': 'AF2026000000002',
        'Cariisim': 'Kuzey Ticaret',
        'Carikod': 'CR.002',
        'Belgeturu': 2,
        'Tarih': '2026-10-29',
        'Geneltoplam': 1200,
        'Parabirimi': 'TL'
      },
      {'Belgeno': 'IR2026000000003', 'Belgeturu': 3, 'Geneltoplam': 9999}
    ];
  if (path.contains('Faturahareket'))
    return [
      {
        'Faturano': 'SF2026000000001',
        'Ad': 'Organik Zeytinyağı 1 L',
        'Kod': 'ST.001',
        'Cariadi': 'Marmara Gıda',
        'Tarih': '2026-10-29',
        'Faturamiktar': 10,
        'Olcubr': 'Adet',
        'Faturanettutar': 2000,
        'Faturatutar': 2400
      }
    ];
  if (path.contains('Finanskasatoplam'))
    return [
      {
        'Id': 1,
        'Kasaid': 1,
        'Kasakod': 'K01',
        'Kasaisim': 'Merkez Kasa',
        'Dovizbirim': 'TL',
        'Bakiyetutar': 2400
      },
      {
        'Id': 2,
        'Kasaid': 2,
        'Kasakod': 'K02',
        'Kasaisim': 'Döviz Kasası',
        'Dovizbirim': 'USD',
        'Bakiyetutar': -4000,
        'Dovizbakiyetutar': -100
      }
    ];
  if (path.contains('Finansbankatoplam'))
    return [
      {
        'Bankahesapid': 1,
        'Bankakod': 'B01',
        'Bankaisim': 'Ticari Hesap',
        'Hesapno': 'TR000001234567890123456789',
        'Dovizbirim': 'USD',
        'Bakiyetutar': 4000,
        'Dovizbakiyetutar': 100
      }
    ];
  if (path.contains('Finanskasahareket') || path.contains('Finansbankahareket'))
    return [
      {
        'Tarih': '2026-10-29',
        'Islemcariad': 'Marmara Gıda',
        'Islemcarikod': 'CR.001',
        'Kasakod': 'K01',
        'Kasaisim': 'Merkez Kasa',
        'Bankakod': 'B01',
        'Bankaisim': 'Ticari Hesap',
        'Giriscikis': 1,
        'Tutar': 2400,
        'Dovizbirim': 'TL',
        'Belgeno': 'TH2026000000001',
        'Hareketaciklama': 'Fatura tahsilatı'
      },
      {
        'Tarih': '2026-10-29',
        'Islemcariad': 'Kuzey Ticaret',
        'Giriscikis': 2,
        'Tutar': 500,
        'Dovizbirim': 'TL',
        'Belgeno': 'OD2026000000002',
        'Hareketaciklama': 'Tedarikçi ödemesi'
      }
    ];
  if (path.contains('Finanscek') || path.contains('Finanssenet'))
    return [
      {
        'Cekno': 'CK000001',
        'Senetno': 'SN000001',
        'Cariad': 'Marmara Gıda',
        'Carikod': 'CR.001',
        'Tarih': '2026-10-29',
        'Vadetarihi': '2026-11-29',
        'Tutar': 12000,
        'Suandaevrakdurum': 'Portföyde'
      }
    ];
  return previews.fixture(path);
}

void main() {
  setUpAll(() async {
    for (final e in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  final screens = <String, Widget Function()>{
    'invoice_summary': () => RaporSayfasi(tanim: faturaIcmaliTanim),
    'invoice_lines': () => RaporSayfasi(tanim: faturaDetayTanim),
    'cash_balances': () => const KasaSondurumRaporu(),
    'cash_movements': () => RaporSayfasi(tanim: kasaHareketTanim),
    'bank_balances': () => RaporSayfasi(tanim: bankaGenelDurumTanim),
    'bank_movements': () => RaporSayfasi(tanim: bankaHareketTanim),
    'negotiable': () => RaporSayfasi(tanim: cekSenetTanim),
  };
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final screen in screens.entries) {
        testWidgets('${screen.key} ${design.name}_${brightness.name}',
            (tester) async {
          SharedPreferences.setMockInitialValues({'token_final': 'preview'});
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          final capture = GlobalKey();
          final requests = <http.Request>[];
          await http.runWithClient(() async {
            await tester.runAsync(() async {
              await tester.pumpWidget(RepaintBoundary(
                  key: capture,
                  child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.build(brightness, design: design),
                      home: screen.value())));
              await Future<void>.delayed(const Duration(milliseconds: 1600));
            });
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await previews.captureReport(tester, capture,
                '${screen.key}_${design.name}_${brightness.name}');
            if (screen.key == 'invoice_summary') {
              expect(find.text('SF2026000000001'), findsOneWidget);
              expect(find.text('IR2026000000003'), findsNothing);
              expect(find.text('2.400,00'), findsWidgets);
            }
            if (screen.key == 'cash_balances') {
              expect(find.text('-4.000,00 ₺'), findsOneWidget);
              expect(find.text('-100,00 USD'), findsOneWidget);
              await tester.enterText(find.byType(TextField).first, 'Merkez');
              await tester.pumpAndSettle();
              expect(find.text('Döviz Kasası'), findsNothing);
              await tester.tap(find.byIcon(Icons.close_rounded).first);
              await tester.pumpAndSettle();
            } else {
              await tester.tap(find.byTooltip('Dışa Aktar'));
              await tester.pumpAndSettle();
              expect(find.text("Excel'e Aktar"), findsOneWidget);
              expect(find.text("PDF'e Aktar"), findsOneWidget);
              Navigator.of(tester.element(find.text("PDF'e Aktar"))).pop();
              await tester.pumpAndSettle();
              await tester.tap(find.byTooltip('Filtreler').first);
              await tester.pumpAndSettle();
              await previews.captureReport(tester, capture,
                  '${screen.key}_filters_${design.name}_${brightness.name}');
              tester.view.physicalSize = const Size(320, 740);
              tester.view.viewInsets = const FakeViewPadding(bottom: 300);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              tester.view.resetViewInsets();
              Navigator.of(tester.element(find.text('Filtreler').last)).pop();
              await tester.pumpAndSettle();
            }
            tester.view.physicalSize = const Size(320, 740);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
                requests.where((r) =>
                    r.method != 'GET' &&
                    !(r.method == 'POST' && r.url.path.contains('/VW_'))),
                isEmpty);
            await tester.pump(const Duration(seconds: 2));
            await tester.runAsync(() async {
              await Future<void>.delayed(const Duration(milliseconds: 800));
            });
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
              () => MockClient((r) async {
                    requests.add(r);
                    return http.Response(
                        jsonEncode({'Data': dataFor(r.url.path)}), 200,
                        headers: {
                          'content-type': 'application/json; charset=utf-8'
                        });
                  }));
        });
      }
    }
  }
}
