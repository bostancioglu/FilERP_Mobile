import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/helpers/irsaliye_hesap_helper.dart';
import 'package:FilERP/models/entities/fatura/faturahareket_dto.dart';
import 'package:FilERP/models/entities/irsaliye/irsaliye_dto.dart';
import 'package:FilERP/models/entities/irsaliye/irsaliyehareket_dto.dart';
import 'package:FilERP/models/entities/helper/istisna_dto.dart';
import 'package:FilERP/models/entities/olcubirimi/olcubr_dto.dart';
import 'package:FilERP/widgets/document_extra_notes.dart';
import 'package:FilERP/widgets/document_line_extras.dart';
import 'package:FilERP/widgets/fatura/fatura_genel_iskonto_sheet.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'invoice line preserves real packaging and exemption IDs and clones the draft',
      () {
    final row = FaturahareketDto.fromJson({
      'Id': 12,
      'Olcubr2id': 7,
      'IstisnaId': 9,
      'Stokadiaciklama': 'Özel ürün',
      'Kdvorani': 20,
      'Doviziskontotutari6': 4.5,
      'Olcubr2': {'Id': 7, 'Ad': 'Koli'},
      'Istisna': {'Id': 9, 'Kod': '301'}
    });
    final draft = row.copy()
      ..olcubr2id = 8
      ..istisnaId = null;
    expect(row.olcubr2id, 7);
    expect(row.istisnaId, 9);
    expect(draft.kdvorani, 20);
    expect(draft.doviziskontotutari6, 4.5);
    expect(row.toJson(), containsPair('olcubr2id', 7));
    expect(row.toJson(), containsPair('istisnaId', 9));
    expect(row.toJson(), containsPair('stokadiaciklama', 'Özel ürün'));
  });

  test('waybill loads all additional notes and new line fields', () {
    final doc = IrsaliyeDto.fromJson(
        {for (var i = 1; i <= 20; i++) 'Aciklama$i': 'Not $i'});
    expect(doc.extraNotes.length, 20);
    expect(doc.extraNotesJson['aciklama20'], 'Not 20');
    doc.extraNotes = ['Yeni not'];
    expect(doc.extraNotesJson['aciklama1'], 'Yeni not');
    expect(doc.extraNotesJson['aciklama20'], isNull);
    final row = IrsaliyehareketDto.fromJson({
      'Olcubr2id': 8,
      'IstisnaId': 3,
      'Stokadiaciklama': 'Ürün açıklaması',
      'Doviziskontotutari6': 2.5
    });
    expect(row.olcubr2id, 8);
    expect(row.istisnaId, 3);
    expect(row.stokadiaciklama, 'Ürün açıklaması');
    expect(row.doviziskontotutari6, 2.5);
    final draft = row.copy()
      ..istisnaId = null
      ..olcubr2id = null;
    expect(row.istisnaId, 3);
    expect(draft.stokadiaciklama, 'Ürün açıklaması');
    final payload = row.toInsertJson('test-document');
    expect(payload['olcubr2id'], 8);
    expect(payload['istisnaId'], 3);
    expect(payload['stokadiaciklama'], 'Ürün açıklaması');
    expect(payload['doviziskontotutari6'], 2.5);
    expect(payload['irsaliyeid'], 'test-document');
  });

  for (final foreign in [false, true]) {
    test(
        'waybill discount recalculates VAT and withholding in ${foreign ? 'foreign currency' : 'TL'}',
        () {
      final doc = IrsaliyeDto()
        ..dovizid = foreign ? 2 : 1
        ..kur = foreign ? 40 : 1
        ..geneliskontooran = 10
        ..geneliskontotutar = 1; // stale computed value must not win
      final rows = [
        IrsaliyehareketDto()
          ..bruttutar = 1000
          ..kdvtutar = 200
          ..tevkifattutar = 100
      ];
      final result = IrsaliyeHesapHelper.recalculate(doc, rows);
      expect(result.aratoplam, 900);
      expect(result.kdvtoplam, 90);
      expect(result.geneltoplam, 990);
      expect(doc.geneliskontotutar, 100);
      expect(doc.dovizgeneliskontotutar, foreign ? 2.5 : 100);
      rows.first.bruttutar = 2000;
      rows.first.kdvtutar = 400;
      rows.first.tevkifattutar = 200;
      IrsaliyeHesapHelper.recalculate(doc, rows);
      expect(doc.geneliskontotutar, 200);
      doc.geneliskontooran = null;
      doc.geneliskontotutar = 250;
      IrsaliyeHesapHelper.recalculate(doc, rows);
      expect(doc.geneltoplam, 1925);
      doc.geneliskontotutar = null;
      IrsaliyeHesapHelper.recalculate(doc, rows);
      expect(doc.geneltoplam, 2200);
    });
  }

  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
          '${design.name} ${brightness.name}: additional notes apply and cancel',
          (tester) async {
        var notes = <String?>['İlk not', ...List<String?>.filled(19, null)];
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.build(brightness, design: design),
            home: Scaffold(
                body: StatefulBuilder(
                    builder: (context, setState) => DocumentExtraNotesButton(
                        values: notes,
                        onChanged: (value) =>
                            setState(() => notes = value))))));
        await tester.tap(find.text('Ek Açıklamalar (1)'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, 'Vazgeçilen');
        await tester.tap(find.text('Vazgeç'));
        await tester.pumpAndSettle();
        expect(notes.first, 'İlk not');
        await tester.tap(find.text('Ek Açıklamalar (1)'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, 'Yeni not');
        await tester.tap(find.text('Uygula'));
        await tester.pumpAndSettle();
        expect(notes.first, 'Yeni not');
        expect(notes.length, 20);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
      'real exemption/package selectors use API data and allow clearing',
      (tester) async {
    SharedPreferences.setMockInitialValues({'token_final': 'fixture'});
    IstisnaDto? exemption;
    OlcubrDto? package;
    final requests = <String>[];
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: StatefulBuilder(
                  builder: (context, setState) => SingleChildScrollView(
                      child: DocumentLineExtras(
                          exemptionId: exemption?.id,
                          exemption: exemption,
                          packageUnitId: package?.Id,
                          packageUnit: package,
                          onExemption: (value) =>
                              setState(() => exemption = value),
                          onPackageUnit: (value) =>
                              setState(() => package = value)))))));
      await tester.tap(find.text('Vergi ve Ambalaj'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('document-line-İstisna')));
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('301 · İhracat').last);
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pumpAndSettle();
      expect(exemption?.id, 9);
      await tester.runAsync(() async {
        await tester.tap(
            find.byKey(const ValueKey('document-line-Ambalaj Ölçü Birimi')));
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('KL · Koli').last);
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pumpAndSettle();
      expect(package?.Id, 7);
      await tester.tap(find.byTooltip('İstisna temizle'));
      await tester.tap(find.byTooltip('Ambalaj Ölçü Birimi temizle'));
      await tester.pumpAndSettle();
      expect(exemption, isNull);
      expect(package, isNull);
      expect(
          requests,
          containsAll(
              ['/api/Istisna/AllWithoutAuth', '/api/Olcubr/AllWithoutAuth']));
    },
        () => MockClient((r) async {
              requests.add(r.url.path);
              return http.Response(
                  jsonEncode({
                    'Data': r.url.path.contains('Istisna')
                        ? [
                            {'Id': 9, 'Kod': '301', 'Aciklama': 'İhracat'}
                          ]
                        : [
                            {'Id': 7, 'Kod': 'KL', 'Ad': 'Koli'}
                          ]
                  }),
                  200,
                  headers: {'content-type': 'application/json; charset=utf-8'});
            }));
  });

  testWidgets(
      'manual discount amount replaces percentage and validates the tax base',
      (tester) async {
    GenelIskontoResult? result;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => FilledButton(
                    onPressed: () async {
                      result = await showFaturaGenelIskontoSheet(context,
                          araToplam: 1000, oran: 10, tutar: 100);
                    },
                    child: const Text('Aç'))))));
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '1500');
    await tester.tap(find.text('Uygula'));
    await tester.pumpAndSettle();
    expect(find.text('Matrahtan büyük olamaz'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, '200');
    await tester.tap(find.text('Uygula'));
    await tester.pumpAndSettle();
    expect(result?.oran, isNull);
    expect(result?.tutar, 200);
  });
}
