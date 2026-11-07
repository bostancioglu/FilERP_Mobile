import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

import '../../models/entities/rapor/stok/view_stokhareket.dart';
import '../../models/entities/rapor/cari/view_carihareket.dart';

class RaporAktarService {
  static final _dateFmt  = DateFormat('dd.MM.yyyy');
  static final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');
  static final _miktarFmt = NumberFormat('#,##0.####', 'tr_TR');

  // ─── STOK HAREKET ────────────────────────────────────────

  static Future<void> stokExcel(
    BuildContext context,
    List<ViewStokhareket> data,
    DateTime tarih1, DateTime tarih2,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Stok Hareketleri'];

    // Başlık satırı
    final basliklar = [
      'Tarih', 'Belge No', 'Belge', 'Stok Kodu', 'Stok Adı',
      'Ölçü Br', 'Cari Kodu', 'Cari Adı', 'Depo', 'Proje',
      'G/Ç', 'Miktar', 'Fiyat', 'Tutar',
      'Bakiye Miktar', 'Bakiye Tutar',
    ];

    final baslikStil = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    for (int i = 0; i < basliklar.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(basliklar[i])
        ..cellStyle = baslikStil;
    }

    // Veri satırları
    for (int i = 0; i < data.length; i++) {
      final r = data[i];
      final isGiris = (r.girismiktar ?? 0) > 0;
      final miktar  = isGiris ? r.girismiktar : r.cikismiktar;
      final tutar   = isGiris ? r.giristutar  : r.cikistutar;
      final gcStr   = isGiris ? 'Giriş' : 'Çıkış';

      final satirRenk = i.isEven
          ? ExcelColor.fromHexString('#F5F7FF')
          : ExcelColor.fromHexString('#FFFFFF');

      final cells = [
        r.tarih != null ? _dateFmt.format(r.tarih!) : '',
        r.belgeno ?? '',
        r.belge ?? '',
        r.kod ?? '',
        r.ad ?? '',
        r.olcubr ?? '',
        r.carikod ?? '',
        r.cariisim ?? '',
        r.depoadi ?? '',
        r.projeadi ?? '',
        gcStr,
        miktar ?? 0,
        r.fiyat ?? 0,
        tutar ?? 0,
        r.bakiyemiktar ?? 0,
        r.bakiyetutar ?? 0,
      ];

      for (int j = 0; j < cells.length; j++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
        final val = cells[j];
        if (val is String) {
          cell.value = TextCellValue(val);
        } else {
          cell.value = DoubleCellValue((val as num).toDouble());
        }
        cell.cellStyle = CellStyle(backgroundColorHex: satirRenk);
      }
    }

    // Kolon genişlikleri
    final genislikler = [12, 16, 14, 12, 24, 8, 12, 24, 14, 14, 8, 12, 12, 12, 14, 14];
    for (int i = 0; i < genislikler.length; i++) {
      sheet.setColumnWidth(i, genislikler[i].toDouble());
    }

    final bytes = excel.encode()!;
    final dir   = await getTemporaryDirectory();
    final file  = File('${dir.path}/stok_hareket_${_dateFmt.format(tarih1)}_${_dateFmt.format(tarih2)}.xlsx');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)],
        subject: 'Stok Hareket Raporu',
        text: '${_dateFmt.format(tarih1)} - ${_dateFmt.format(tarih2)}');
  }

  static Future<void> stokPdf(
    BuildContext context,
    List<ViewStokhareket> data,
    DateTime tarih1, DateTime tarih2,
  ) async {
    final doc  = pw.Document();
    final font = pw.Font.helvetica();
    final bold = pw.Font.helveticaBold();

    final primaryColor = PdfColor.fromHex('#1565C0');
    // final accentColor  = PdfColor.fromHex('#42A5F5');
    final girisColor   = PdfColor.fromHex('#2E7D32');
    final cikisColor   = PdfColor.fromHex('#C62828');
    final evenRow      = PdfColor.fromHex('#F5F7FF');

    // Sayfaları 30'ar kayıt olarak böl
    const perPage = 30;
    final pages   = (data.length / perPage).ceil().clamp(1, 9999);

    for (int p = 0; p < pages; p++) {
      final slice = data.skip(p * perPage).take(perPage).toList();

      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => [
          // Başlık
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Row(children: [
              pw.Expanded(child: pw.Text('Stok Hareket Raporu',
                  style: pw.TextStyle(font: bold, fontSize: 16, color: PdfColors.white))),
              pw.Text('${_dateFmt.format(tarih1)} - ${_dateFmt.format(tarih2)}',
                  style: pw.TextStyle(font: font, fontSize: 11, color: PdfColor.fromHex("#FFFFFFB2"))),
            ]),
          ),
          pw.SizedBox(height: 12),
          // Tablo başlıkları
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(55),
              1: const pw.FixedColumnWidth(70),
              2: const pw.FixedColumnWidth(55),
              3: const pw.FixedColumnWidth(50),
              4: const pw.FlexColumnWidth(2),
              5: const pw.FixedColumnWidth(30),
              6: const pw.FlexColumnWidth(2),
              7: const pw.FixedColumnWidth(40),
              8: const pw.FixedColumnWidth(55),
              9: const pw.FixedColumnWidth(55),
              10: const pw.FixedColumnWidth(55),
              11: const pw.FixedColumnWidth(60),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: ['Tarih', 'Belge No', 'Belge', 'G/Ç', 'Stok', 'OBr',
                    'Cari', 'Depo', 'Miktar', 'Fiyat', 'Tutar', 'Bakiye']
                    .map((h) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      child: pw.Text(h, style: pw.TextStyle(font: bold, fontSize: 7, color: PdfColors.white)),
                    )).toList(),
              ),
              // Data rows
              ...slice.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                final isGiris = (r.girismiktar ?? 0) > 0;
                final miktar  = isGiris ? r.girismiktar : r.cikismiktar;
                final tutar   = isGiris ? r.giristutar  : r.cikistutar;
                final gcColor = isGiris ? girisColor : cikisColor;
                final rowBg   = i.isEven ? evenRow : PdfColors.white;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowBg),
                  children: [
                    r.tarih != null ? _dateFmt.format(r.tarih!) : '-',
                    r.belgeno ?? '-',
                    r.belge ?? '-',
                    isGiris ? 'G' : 'Ç',
                    '${r.kod ?? ''} ${r.ad ?? ''}',
                    r.olcubr ?? '',
                    '${r.carikod ?? ''} ${r.cariisim ?? ''}',
                    r.depoadi ?? '',
                    _miktarFmt.format(miktar ?? 0),
                    _moneyFmt.format(r.fiyat ?? 0),
                    _moneyFmt.format(tutar ?? 0),
                    _miktarFmt.format(r.bakiyemiktar ?? 0),
                  ].asMap().entries.map((e) {
                    final isGcCol = e.key == 3;
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: pw.Text(e.value,
                          style: pw.TextStyle(
                              font: isGcCol ? bold : font,
                              fontSize: 7,
                              color: isGcCol ? gcColor : PdfColors.black)),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
          if (p == pages - 1) ...[
            pw.SizedBox(height: 10),
            pw.Text('Toplam: ${data.length} kayıt',
                style: pw.TextStyle(font: bold, fontSize: 9, color: primaryColor)),
          ],
        ],
      ));
    }

    final bytes = await doc.save();
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/stok_hareket_${_dateFmt.format(tarih1)}_${_dateFmt.format(tarih2)}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)],
        subject: 'Stok Hareket Raporu PDF',
        text: '${_dateFmt.format(tarih1)} - ${_dateFmt.format(tarih2)}');
  }

  // ─── CARİ HAREKET ────────────────────────────────────────

  static Future<void> cariExcel(
    BuildContext context,
    List<ViewCarihareket> data,
    DateTime tarih1, DateTime tarih2,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Cari Hareketleri'];

    final basliklar = [
      'Tarih', 'Belge No', 'Açıklama', 'Proje',
      'Para Birimi', 'Kur',
      'Borç', 'Alacak', 'Borç Bakiye', 'Alacak Bakiye',
      'Döviz Borç', 'Döviz Alacak', 'Döviz Borç Bak.', 'Döviz Alacak Bak.',
    ];

    final baslikStil = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    for (int i = 0; i < basliklar.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(basliklar[i])
        ..cellStyle = baslikStil;
    }

    for (int i = 0; i < data.length; i++) {
      final r = data[i];
      final satirRenk = i.isEven
          ? ExcelColor.fromHexString('#F3F4FF')
          : ExcelColor.fromHexString('#FFFFFF');

      final cells = [
        r.tarih != null ? _dateFmt.format(r.tarih!) : '',
        r.belgeno ?? '',
        r.aciklama ?? '',
        r.projekodu ?? '',
        r.dovizbirim ?? 'TRY',
        r.kur ?? 1.0,
        r.borctutar ?? 0,
        r.alacaktutar ?? 0,
        r.borcbakiye ?? 0,
        r.alacakbakiye ?? 0,
        r.dovizborctutar ?? 0,
        r.dovizalacaktutar ?? 0,
        r.dovizborcbakiye ?? 0,
        r.dovizalacakbakiye ?? 0,
      ];

      for (int j = 0; j < cells.length; j++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
        final val = cells[j];
        if (val is String) {
          cell.value = TextCellValue(val);
        } else {
          cell.value = DoubleCellValue((val as num).toDouble());
        }
        cell.cellStyle = CellStyle(backgroundColorHex: satirRenk);
      }
    }

    final genislikler = [12, 16, 28, 12, 10, 10, 14, 14, 14, 14, 14, 14, 14, 14];
    for (int i = 0; i < genislikler.length; i++) {
      sheet.setColumnWidth(i, genislikler[i].toDouble());
    }

    final bytes = excel.encode()!;
    final dir   = await getTemporaryDirectory();
    final file  = File('${dir.path}/cari_hareket_${_dateFmt.format(tarih1)}_${_dateFmt.format(tarih2)}.xlsx');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)],
        subject: 'Cari Hareket Raporu',
        text: '${_dateFmt.format(tarih1)} - ${_dateFmt.format(tarih2)}');
  }

  static Future<void> cariPdf(
    BuildContext context,
    List<ViewCarihareket> data,
    DateTime tarih1, DateTime tarih2,
    String? cariIsim,
  ) async {
    final doc  = pw.Document();
    final font = pw.Font.helvetica();
    final bold = pw.Font.helveticaBold();

    final primaryColor = PdfColor.fromHex('#1A237E');
    final borcColor    = PdfColor.fromHex('#C62828');
    final alacakColor  = PdfColor.fromHex('#2E7D32');
    final evenRow      = PdfColor.fromHex('#F3F4FF');

    const perPage = 30;
    final pages   = (data.length / perPage).ceil().clamp(1, 9999);

    for (int p = 0; p < pages; p++) {
      final slice = data.skip(p * perPage).take(perPage).toList();

      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Cari Hareket Raporu',
                  style: pw.TextStyle(font: bold, fontSize: 16, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Row(children: [
                if (cariIsim != null)
                  pw.Expanded(child: pw.Text(cariIsim,
                      style: pw.TextStyle(font: font, fontSize: 11, color: PdfColor.fromHex("#FFFFFFB2")))),
                pw.Text('${_dateFmt.format(tarih1)} - ${_dateFmt.format(tarih2)}',
                    style: pw.TextStyle(font: font, fontSize: 11, color: PdfColor.fromHex("#FFFFFFB2"))),
              ]),
            ]),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(55),
              1: const pw.FixedColumnWidth(70),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FixedColumnWidth(40),
              4: const pw.FixedColumnWidth(30),
              5: const pw.FixedColumnWidth(65),
              6: const pw.FixedColumnWidth(65),
              7: const pw.FixedColumnWidth(70),
              8: const pw.FixedColumnWidth(70),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: ['Tarih', 'Belge No', 'Açıklama', 'Proje', 'Para Br',
                    'Borç', 'Alacak', 'Borç Bakiye', 'Alacak Bakiye']
                    .map((h) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      child: pw.Text(h, style: pw.TextStyle(font: bold, fontSize: 7, color: PdfColors.white)),
                    )).toList(),
              ),
              ...slice.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                final rowBg = i.isEven ? evenRow : PdfColors.white;
                // final isBorc = (r.borctutar ?? 0) > 0;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowBg),
                  children: [
                    r.tarih != null ? _dateFmt.format(r.tarih!) : '-',
                    r.belgeno ?? '-',
                    r.aciklama ?? '',
                    r.projekodu ?? '',
                    r.dovizbirim ?? 'TRY',
                    _moneyFmt.format(r.borctutar ?? 0),
                    _moneyFmt.format(r.alacaktutar ?? 0),
                    _moneyFmt.format(r.borcbakiye ?? 0),
                    _moneyFmt.format(r.alacakbakiye ?? 0),
                  ].asMap().entries.map((e) {
                    final isBorcCol   = e.key == 5;
                    final isAlacakCol = e.key == 6;
                    final isBakiyeB   = e.key == 7;
                    final isBakiyeA   = e.key == 8;
                    final txtColor = isBorcCol || isBakiyeB ? borcColor
                        : isAlacakCol || isBakiyeA ? alacakColor
                        : PdfColors.black;
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: pw.Text(e.value,
                          style: pw.TextStyle(font: font, fontSize: 7, color: txtColor)),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
          if (p == pages - 1) ...[
            pw.SizedBox(height: 10),
            pw.Row(children: [
              pw.Text('Toplam: ${data.length} kayıt  |  ',
                  style: pw.TextStyle(font: bold, fontSize: 9, color: primaryColor)),
              pw.Text('Borç: ${_moneyFmt.format(data.fold(0.0, (s, r) => s + (r.borctutar ?? 0)))}  |  ',
                  style: pw.TextStyle(font: bold, fontSize: 9, color: borcColor)),
              pw.Text('Alacak: ${_moneyFmt.format(data.fold(0.0, (s, r) => s + (r.alacaktutar ?? 0)))}',
                  style: pw.TextStyle(font: bold, fontSize: 9, color: alacakColor)),
            ]),
          ],
        ],
      ));
    }

    final bytes = await doc.save();
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/cari_hareket_${_dateFmt.format(tarih1)}_${_dateFmt.format(tarih2)}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)],
        subject: 'Cari Hareket Raporu PDF',
        text: '${_dateFmt.format(tarih1)} - ${_dateFmt.format(tarih2)}');
  }
}