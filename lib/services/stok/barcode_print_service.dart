import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/entities/stok/stok_dto.dart';

class BarcodePrintService {
  static Future<void> printLabels({
    required StokDto stok,
    required String barkod,
    required String olcuBirimi,
    required int adet,
  }) async {
    final doc = await _buildDocument(
      stok: stok,
      barkod: barkod,
      olcuBirimi: olcuBirimi,
      adet: adet,
    );

    await Printing.layoutPdf(
      name: _fileName(stok, barkod),
      format: const PdfPageFormat(
        58 * PdfPageFormat.mm,
        40 * PdfPageFormat.mm,
      ),
      onLayout: (_) => doc.save(),
    );
  }

  static Future<void> shareLabels({
    required StokDto stok,
    required String barkod,
    required String olcuBirimi,
    required int adet,
  }) async {
    final doc = await _buildDocument(
      stok: stok,
      barkod: barkod,
      olcuBirimi: olcuBirimi,
      adet: adet,
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_fileName(stok, barkod)}.pdf');
    await file.writeAsBytes(await doc.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Barkod Etiketi',
    );
  }

  static Future<pw.Document> _buildDocument({
    required StokDto stok,
    required String barkod,
    required String olcuBirimi,
    required int adet,
  }) async {
    final doc = pw.Document();
    final bold = await PdfGoogleFonts.robotoBold();
    final regular = await PdfGoogleFonts.robotoRegular();

    for (var i = 0; i < adet; i++) {
      doc.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            58 * PdfPageFormat.mm,
            40 * PdfPageFormat.mm,
          ),
          margin: const pw.EdgeInsets.all(6),
          build: (_) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  stok.Kod ?? '-',
                  style: pw.TextStyle(font: bold, fontSize: 10),
                  maxLines: 1,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  stok.Ad ?? '-',
                  style: pw.TextStyle(font: regular, fontSize: 9),
                  maxLines: 2,
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: barkod,
                    width: 150,
                    height: 42,
                    drawText: false,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(
                    barkod,
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 9,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#EEF2F7'),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      olcuBirimi,
                      style: pw.TextStyle(font: bold, fontSize: 8),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return doc;
  }

  static String _fileName(StokDto stok, String barkod) {
    final kod =
        (stok.Kod ?? 'stok').replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final barcode = barkod.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'barkod_${kod}_$barcode';
  }
}
