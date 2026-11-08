import 'package:FilERP/widgets/permission_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helpers/weighted_barcode_helper.dart';
import '../helpers/ui_feedback.dart';
import '../helpers/hata_sesi.dart';
import '../models/entities/stok/stok_list_dto.dart';
import 'barcode_scanner_sheet.dart';

class QuickBarcodeLine {
  final String barcode;
  final StokListDto? stok;
  double quantity;

  QuickBarcodeLine({
    required this.barcode,
    required this.stok,
    required this.quantity,
  });
}

class QuickBarcodeScanResult {
  final List<String> rawBarcodes;
  final List<QuickBarcodeLine> lines;

  QuickBarcodeScanResult({
    required this.rawBarcodes,
    required this.lines,
  });
}

Future<QuickBarcodeScanResult?> showQuickBarcodeScanSheet(
  BuildContext context, {
  required List<StokListDto> stoklar,
  String title = 'H\u0131zl\u0131 Barkod Okut',
  bool hataSesi = false, // eşleşmeyen barkod / hata olunca yüksek sesli uyarı
}) {
  return showModalBottomSheet<QuickBarcodeScanResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuickBarcodeScanSheet(
        stoklar: stoklar, title: title, hataSesi: hataSesi),
  );
}

class _QuickBarcodeScanSheet extends StatefulWidget {
  final List<StokListDto> stoklar;
  final String title;
  final bool hataSesi;

  const _QuickBarcodeScanSheet({
    required this.stoklar,
    required this.title,
    this.hataSesi = false,
  });

  @override
  State<_QuickBarcodeScanSheet> createState() => _QuickBarcodeScanSheetState();
}

class _QuickBarcodeScanSheetState extends State<_QuickBarcodeScanSheet> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.onSurface;
  Color get _accent => _scheme.primary;

  final _barcodeCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final List<String> _barcodes = [];
  late final Map<String, StokListDto> _barcodeIndex;
  bool _summaryMode = false;
  List<QuickBarcodeLine> _summaryLines = [];

  // Hardware barkod okuyucu desteği
  final StringBuffer _hwBuffer = StringBuffer();
  DateTime? _hwLastKey;
  static const _hwTimeout = Duration(milliseconds: 80);

  @override
  void initState() {
    super.initState();
    _barcodeIndex = _buildBarcodeIndex(widget.stoklar);
    WeightedBarcodeHelper.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
    // LIFO sırası: bu handler parent sayfaların handler'ından önce çalışır
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _barcodeCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final now = DateTime.now();
    if (_hwLastKey != null && now.difference(_hwLastKey!) > _hwTimeout) {
      _hwBuffer.clear();
    }
    _hwLastKey = now;
    final label = event.logicalKey.keyLabel;
    if (label == 'Enter') {
      final barcode = _hwBuffer.toString().trim();
      _hwBuffer.clear();
      if (barcode.isNotEmpty) {
        Future.microtask(() => _addBarcode(barcode));
      }
      return true; // parent handler'a ulaşmasın
    }
    if (label.length == 1) {
      _hwBuffer.write(label);
      return true; // parent handler'a ulaşmasın
    }
    return false;
  }

  Map<String, StokListDto> _buildBarcodeIndex(List<StokListDto> stoklar) {
    final map = <String, StokListDto>{};
    for (final stok in stoklar) {
      for (final barkod in stok.getBarkodListesi()) {
        final key = _normalize(barkod);
        if (key.isNotEmpty) {
          map.putIfAbsent(key, () => stok);
        }
      }
    }
    return map;
  }

  String _normalize(String value) => value.trim().toLowerCase();

  String _formatQuantity(double value) {
    final text = value.toStringAsFixed(4);
    final trimmed =
        text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return trimmed.replaceAll('.', ',');
  }

  String _displayTitle(String title) {
    if (title.contains('HÄ±zlÄ±') || title.contains('G\u0131zl\u0131')) {
      return 'H\u0131zl\u0131 Barkod Okut';
    }
    return title;
  }

  void _uyari(String m) {
    if (widget.hataSesi) HataSesi.cal();
    UiFeedback.showWarning(context, m);
  }

  void _addBarcode(String value) {
    final barcode = value.trim();
    if (barcode.isEmpty) {
      return;
    }
    setState(() => _barcodes.insert(0, barcode));
    if (widget.hataSesi) {
      final w = WeightedBarcodeHelper.tryParse(barcode);
      if (_barcodeIndex[_normalize(w?.stockBarcode ?? barcode)] == null) {
        _uyari('Stok bulunamadı: $barcode');
      }
    }
    _barcodeCtrl.clear();
    _focusNode.requestFocus();
  }

  Future<void> _scanWithCamera() async {
    final barcode = await Navigator.push<String>(
      context,
      PermissionMaterialPageRoute(builder: (_) => BarcodeScannerSheet()),
    );
    if (barcode != null && mounted) {
      _addBarcode(barcode);
    }
  }

  void _openSummary() {
    if (_barcodes.isEmpty) {
      _uyari('\u00d6nce barkod okutunuz!');
      return;
    }

    final grouped = <String, QuickBarcodeLine>{};
    for (final barcode in _barcodes) {
      final weighted = WeightedBarcodeHelper.tryParse(barcode);
      final resolvedBarcode = weighted?.stockBarcode ?? barcode;
      final key = _normalize(resolvedBarcode);
      final quantity = weighted?.quantity ?? 1;
      final existing = grouped[key];
      if (existing != null) {
        existing.quantity += quantity;
      } else {
        grouped[key] = QuickBarcodeLine(
          barcode: resolvedBarcode,
          stok: _barcodeIndex[key],
          quantity: quantity,
        );
      }
    }

    setState(() {
      _summaryLines = grouped.values.toList()
        ..sort((a, b) => a.barcode.compareTo(b.barcode));
      _summaryMode = true;
    });
  }

  int get _uniqueCount => _summaryMode
      ? _summaryLines.length
      : _barcodes.map(_normalize).where((e) => e.isNotEmpty).toSet().length;

  int get _totalCount => _barcodes.length;

  int get _unmatchedCount =>
      _summaryLines.where((line) => line.stok == null).length;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 12),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
            Container(
              width: 42,
              height: 4,
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: _scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildHeader(),
            SizedBox(height: 10),
            _buildInfoBar(),
            SizedBox(height: 10),
            Expanded(
              child: _summaryMode
                  ? _buildSummaryList(controller)
                  : _buildScanList(controller),
            ),
            SizedBox(height: 10),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _summaryMode ? 'Barkod \u00d6zeti' : _displayTitle(widget.title),
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _primary,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CircleAvatar(
            backgroundColor: _scheme.outlineVariant,
            radius: 15,
            child: Icon(Icons.close_rounded, size: 18, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.fact_check_outlined, color: _accent, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '$_uniqueCount farkl\u0131 barkod, toplam $_totalCount barkod okutuldu',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: _primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (_summaryMode && _unmatchedCount > 0)
            Text(
              '$_unmatchedCount e\u015fle\u015fmedi',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: _scheme.error,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanList(ScrollController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _barcodeCtrl,
                focusNode: _focusNode,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Barkod',
                  prefixIcon: Icon(Icons.barcode_reader),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: _addBarcode,
              ),
            ),
            SizedBox(width: 8),
            _iconAction(
              Icons.qr_code_scanner_rounded,
              _accent,
              _scanWithCamera,
            ),
          ],
        ),
        SizedBox(height: 10),
        Expanded(
          child: _barcodes.isEmpty
              ? Center(
                  child: Text(
                    'Hen\u00fcz barkod okutulmad\u0131',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        color: _scheme.onSurfaceVariant,
                        fontSize: 13),
                  ),
                )
              : ListView.builder(
                  controller: controller,
                  itemCount: _barcodes.length,
                  itemBuilder: (_, index) {
                    final barcode = _barcodes[index];
                    return _plainCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: _scheme.surface.withOpacity(0.08),
                            child: Text(
                              '${_barcodes.length - index}',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _primary,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              barcode,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _barcodes.removeAt(index)),
                            icon: Icon(
                              Icons.delete_outline,
                              color: _scheme.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryList(ScrollController controller) {
    if (_summaryLines.isEmpty) {
      return Center(
        child: Text(
          '\u00d6zetlenecek barkod kalmad\u0131',
          style:
              TextStyle(fontFamily: 'Roboto', color: _scheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      controller: controller,
      itemCount: _summaryLines.length,
      itemBuilder: (_, index) {
        final line = _summaryLines[index];
        final stok = line.stok;
        return _plainCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stok == null
                      ? _scheme.error.withValues(alpha: .08)
                      : _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  stok == null
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
                  color: stok == null ? _scheme.error : _accent,
                  size: 20,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stok == null
                          ? 'Stok bulunamad\u0131'
                          : '${stok.Kod ?? ''} - ${stok.Ad ?? ''}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: stok == null ? _scheme.error : _primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3),
                    Text(
                      line.barcode,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: _scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              _quantityStepper(index, line),
              IconButton(
                onPressed: () => setState(() => _summaryLines.removeAt(index)),
                icon: Icon(Icons.delete_outline, color: _scheme.error),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quantityStepper(int index, QuickBarcodeLine line) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: _scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (line.quantity <= 1) {
                return;
              }
              setState(() => line.quantity -= 1);
            },
            child: SizedBox(width: 30, child: Icon(Icons.remove, size: 16)),
          ),
          SizedBox(
            width: 64,
            child: TextFormField(
              key: ValueKey('${line.barcode}-$index-${line.quantity}'),
              initialValue: _formatQuantity(line.quantity),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed != null && parsed > 0) {
                  line.quantity = parsed;
                }
              },
            ),
          ),
          InkWell(
            onTap: () => setState(() => line.quantity += 1),
            child: SizedBox(width: 30, child: Icon(Icons.add, size: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    if (_summaryMode) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _summaryMode = false),
              icon: Icon(Icons.arrow_back_rounded),
              label: Text('Geri'),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _completeSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: _scheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.check_circle_outline_rounded),
              label: Text(
                'Tamam',
                style: TextStyle(
                    fontFamily: 'Roboto', fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _barcodes.isEmpty
                ? null
                : () => setState(() => _barcodes.clear()),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cleaning_services_outlined, size: 16),
                SizedBox(width: 5),
                Text('Temizle',
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _openSummary,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _scheme.onPrimary,
              padding: EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.summarize_outlined),
            label: Text(
              'Kaydet',
              style:
                  TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _completeSummary() {
    if (_summaryLines.isEmpty) {
      _uyari('Eklenecek barkod yok!');
      return;
    }
    if (_unmatchedCount > 0) {
      _uyari('Stok bulunamayan barkodlar\u0131 siliniz!');
      return;
    }
    if (_summaryLines.any((line) => line.quantity <= 0)) {
      _uyari('Adetler s\u0131f\u0131rdan b\u00fcy\u00fck olmal\u0131!');
      return;
    }
    Navigator.pop(
      context,
      QuickBarcodeScanResult(
        rawBarcodes: List<String>.from(_barcodes),
        lines: List<QuickBarcodeLine>.from(_summaryLines),
      ),
    );
  }

  Widget _plainCard({required Widget child}) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _iconAction(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _scheme.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(13),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}
