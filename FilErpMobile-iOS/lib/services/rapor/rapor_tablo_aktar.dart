import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../pages/rapor/ortak/rapor_modelleri.dart';

/// Genel rapor tablosunu (RaporSonuc) Excel veya PDF olarak dışa aktarır.
class RaporTabloAktar {
  const RaporTabloAktar._();

  static String _dosyaAdi(String baslik) =>
      baslik.toLowerCase().replaceAll(RegExp(r'[^a-z0-9ığüşöç]+'), '_').replaceAll(RegExp(r'^_|_$'), '');

  static Future<void> excel(String baslik, String filtreOzeti, RaporSonuc s) async {
    final excel = Excel.createExcel();
    final sheet = excel[baslik.length > 28 ? baslik.substring(0, 28) : baslik];
    excel.delete('Sheet1');

    final baslikStil = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    for (var j = 0; j < s.kolonlar.length; j++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: 0))
        ..value = TextCellValue(s.kolonlar[j].baslik)
        ..cellStyle = baslikStil;
    }

    for (var i = 0; i < s.satirlar.length; i++) {
      final satir = s.satirlar[i];
      for (var j = 0; j < s.kolonlar.length; j++) {
        final k = s.kolonlar[j];
        final v = j < satir.degerler.length ? satir.degerler[j] : null;
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
        if (v is num && k.tip != RaporKolonTipi.metin) {
          cell.value = DoubleCellValue(v.toDouble());
        } else {
          cell.value = TextCellValue(k.bicim(v));
        }
      }
    }
    for (var j = 0; j < s.kolonlar.length; j++) {
      sheet.setColumnWidth(j, 18);
    }

    final bytes = excel.encode()!;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_dosyaAdi(baslik)}.xlsx');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], subject: baslik, text: filtreOzeti);
  }

  static Future<void> pdf(String baslik, String filtreOzeti, RaporSonuc s) async {
    // Türkçe karakterler için paketle gelen Roboto kullanılır.
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

    final primary = PdfColor.fromHex('#1A237E');
    final even = PdfColor.fromHex('#F3F4FF');
    final doc = pw.Document();

    const perPage = 26;
    final pages = (s.satirlar.length / perPage).ceil().clamp(1, 9999);

    for (var p = 0; p < pages; p++) {
      final dilim = s.satirlar.skip(p * perPage).take(perPage).toList();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: pw.BoxDecoration(color: primary, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(baslik, style: pw.TextStyle(font: bold, fontSize: 16, color: PdfColors.white)),
              if (filtreOzeti.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(filtreOzeti, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.white)),
              ],
            ]),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            columnWidths: {
              for (var j = 0; j < s.kolonlar.length; j++)
                j: s.kolonlar[j].tip == RaporKolonTipi.metin && s.kolonlar[j].baslikKolonu
                    ? const pw.FlexColumnWidth(2)
                    : const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primary),
                children: s.kolonlar
                    .map((k) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                          child: pw.Text(k.baslik, style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.white)),
                        ))
                    .toList(),
              ),
              for (var i = 0; i < dilim.length; i++)
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: i.isEven ? even : PdfColors.white),
                  children: [
                    for (var j = 0; j < s.kolonlar.length; j++)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: pw.Text(
                          s.kolonlar[j].bicim(j < dilim[i].degerler.length ? dilim[i].degerler[j] : null),
                          textAlign: s.kolonlar[j].tip == RaporKolonTipi.metin || s.kolonlar[j].tip == RaporKolonTipi.tarih
                              ? pw.TextAlign.left
                              : pw.TextAlign.right,
                          style: pw.TextStyle(font: font, fontSize: 8),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if (p == pages - 1) ...[
            pw.SizedBox(height: 8),
            pw.Text('Toplam: ${s.satirlar.length} kayıt',
                style: pw.TextStyle(font: bold, fontSize: 9, color: primary)),
            for (final o in s.ozetler)
              pw.Text('${o.etiket}: ${o.deger}', style: pw.TextStyle(font: bold, fontSize: 9, color: primary)),
          ],
        ],
      ));
    }

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_dosyaAdi(baslik)}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], subject: baslik, text: filtreOzeti);
  }

  /// Çok bölümlü rapor PDF'i (Plasiyer Özeti gibi).
  static Future<void> pdfBolumlu(String baslik, String filtreOzeti, List<RaporBolum> bolumler) async {
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    final primary = PdfColor.fromHex('#1A237E');
    final even = PdfColor.fromHex('#F3F4FF');
    final doc = pw.Document();

    final widgets = <pw.Widget>[
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: pw.BoxDecoration(color: primary, borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(baslik, style: pw.TextStyle(font: bold, fontSize: 16, color: PdfColors.white)),
          if (filtreOzeti.isNotEmpty) pw.Text(filtreOzeti, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.white)),
        ]),
      ),
    ];

    for (final b in bolumler) {
      widgets.add(pw.SizedBox(height: 12));
      widgets.add(pw.Row(children: [
        pw.Expanded(child: pw.Text(b.baslik, style: pw.TextStyle(font: bold, fontSize: 12, color: primary))),
        if (b.sagBaslik != null) pw.Text(b.sagBaslik!, style: pw.TextStyle(font: bold, fontSize: 12, color: primary)),
      ]));
      widgets.add(pw.Divider(color: primary, thickness: 0.8));

      for (final d in b.degerler) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Text(d.$1, style: pw.TextStyle(font: font, fontSize: 10))),
            pw.Text(d.$2, style: pw.TextStyle(font: bold, fontSize: 10)),
          ]),
        ));
      }

      final t = b.tablo;
      if (t != null) {
        if (t.satirlar.isEmpty) {
          widgets.add(pw.Text('Kayıt yok', style: pw.TextStyle(font: font, fontSize: 9)));
        }
        const perChunk = 25;
        for (var c = 0; c < t.satirlar.length || c == 0; c += perChunk) {
          final dilim = t.satirlar.skip(c).take(perChunk).toList();
          if (dilim.isEmpty) break;
          widgets.add(pw.Table(
            children: [
              if (c == 0)
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primary),
                  children: [
                    for (final k in t.kolonlar)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: pw.Text(k.baslik, style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.white)),
                      ),
                  ],
                ),
              for (var i = 0; i < dilim.length; i++)
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: i.isEven ? even : PdfColors.white),
                  children: [
                    for (var j = 0; j < t.kolonlar.length; j++)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        child: pw.Text(
                          t.kolonlar[j].bicim(j < dilim[i].degerler.length ? dilim[i].degerler[j] : null),
                          textAlign: t.kolonlar[j].tip == RaporKolonTipi.metin || t.kolonlar[j].tip == RaporKolonTipi.tarih
                              ? pw.TextAlign.left
                              : pw.TextAlign.right,
                          style: pw.TextStyle(font: font, fontSize: 8),
                        ),
                      ),
                  ],
                ),
            ],
          ));
        }
      }
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) => widgets,
    ));

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_dosyaAdi(baslik)}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], subject: baslik, text: filtreOzeti);
  }
}
