import 'package:FilERP/widgets/permission_page.dart';
import 'erp_page_style.dart';
import 'package:flutter/material.dart';
import 'barcode_scanner_sheet.dart';

Future<T?> showErpSelector<T>({
  required BuildContext context,
  required String title,
  required String hintText,
  required List<T> items,
  required String Function(T) itemText,
  List<String> Function(T)? getBarcodes,
  String Function(T)? getUnit,
  bool startWithCamera = false,
  bool startWithScanner = false,
  String? initialQuery,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    pageBuilder: (context, animation, secondaryAnimation) {
      return _ErpSelectorContent<T>(
        title: title,
        hintText: hintText,
        items: items,
        itemText: itemText,
        getBarcodes: getBarcodes,
        getUnit: getUnit,
        startWithCamera: startWithCamera,
        startWithScanner: startWithScanner,
        initialQuery: initialQuery,
      );
    },
  );
}

class _ErpSelectorContent<T> extends StatefulWidget {
  final String title;
  final String hintText;
  final List<T> items;
  final String Function(T) itemText;
  final List<String> Function(T)? getBarcodes;
  final String Function(T)? getUnit;
  final bool startWithCamera;
  final bool startWithScanner;
  final String? initialQuery;

  const _ErpSelectorContent({
    required this.title,
    required this.hintText,
    required this.items,
    required this.itemText,
    this.getBarcodes,
    this.getUnit,
    this.startWithCamera = false,
    this.startWithScanner = false,
    this.initialQuery,
  });

  @override
  State<_ErpSelectorContent<T>> createState() => _ErpSelectorContentState<T>();
}

class _ErpSelectorContentState<T> extends State<_ErpSelectorContent<T>> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _positive => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF6EE7B7)
      : const Color(0xFF16704A);

  late List<T> filteredItems;
  final TextEditingController _searchCtrl = TextEditingController();

  // A-Z sıralama — varsayılan artan (A→Z), butonla Z→A'ya çevrilebilir
  bool _ascending = true;

  void _sortItems() {
    filteredItems.sort((a, b) {
      final cmp = widget
          .itemText(a)
          .toLowerCase()
          .compareTo(widget.itemText(b).toLowerCase());
      return _ascending ? cmp : -cmp;
    });
  }

  void _toggleSort() {
    setState(() {
      _ascending = !_ascending;
      _sortItems();
    });
  }

  @override
  void initState() {
    super.initState();
    filteredItems = List.from(widget.items);
    _sortItems();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchCtrl.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _filter(widget.initialQuery!);
        // Tek eşleşme varsa otomatik seç
        if (filteredItems.length == 1) {
          Navigator.pop(context, filteredItems.first);
        }
      });
    } else if (widget.startWithCamera && widget.getBarcodes != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCamera());
    }
  }

  Future<void> _openCamera() async {
    final barcode = await Navigator.push<String>(
      context,
      PermissionMaterialPageRoute(builder: (context) => BarcodeScannerSheet()),
    );
    if (barcode != null && mounted) {
      _searchCtrl.text = barcode;
      _filter(barcode);
      // Tek eşleşme varsa otomatik seç
      if (filteredItems.length == 1) {
        Navigator.pop(context, filteredItems.first);
      }
    }
  }

  void _filter(String text) {
    final query = text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        filteredItems = List.from(widget.items);
      } else {
        filteredItems = widget.items.where((item) {
          // 1. İsim ve Kod Araması
          final String mainText = widget.itemText(item).toLowerCase();
          if (mainText.contains(query)) return true;

          // 2. Barkod Araması
          if (widget.getBarcodes != null) {
            try {
              final List<String> barcodes = widget.getBarcodes!(item);
              for (var barcode in barcodes) {
                if (barcode.toLowerCase().contains(query)) {
                  return true;
                }
              }
            } catch (e) {
              return false;
            }
          }
          return false;
        }).toList();
      }
      _sortItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scheme.surfaceContainerLow,
      appBar: ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        elevation: 0,
        title: Text(
          widget.title,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: _scheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: _scheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _ascending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: Colors.black87,
            ),
            tooltip: _ascending ? "A → Z" : "Z → A",
            onPressed: _toggleSort,
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama Kutusu
          Container(
            color: _scheme.surface,
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              autofocus: true,
              onSubmitted: (value) {
                // Terminal barkod okutunca enter gelir — tek eşleşme varsa otomatik seç
                if (filteredItems.length == 1) {
                  Navigator.pop(context, filteredItems.first);
                } else if (filteredItems.isEmpty &&
                    widget.getBarcodes != null) {
                  // Tam barkod eşleşmesi ara
                  final exact = widget.items.where((item) {
                    final barcodes = widget.getBarcodes!(item);
                    return barcodes.any(
                        (b) => b.toLowerCase() == value.toLowerCase().trim());
                  }).toList();
                  if (exact.length == 1) Navigator.pop(context, exact.first);
                }
              },
              decoration: InputDecoration(
                hintText: widget.startWithScanner
                    ? "Barkod okutun..."
                    : widget.hintText,
                hintStyle: TextStyle(
                    fontFamily: 'Roboto', color: _scheme.onSurfaceVariant),
                prefixIcon: Icon(
                  widget.startWithScanner ? Icons.barcode_reader : Icons.search,
                  color: widget.startWithScanner
                      ? _positive
                      : _scheme.onSurfaceVariant,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Kamera Butonu
                    if (widget.getBarcodes != null)
                      IconButton(
                        icon:
                            Icon(Icons.qr_code_scanner, color: _scheme.primary),
                        onPressed: _openCamera,
                        tooltip: 'Kamera ile Tara',
                      ),
                    // Temizle Butonu
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon:
                            Icon(Icons.clear, color: _scheme.onSurfaceVariant),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filter('');
                        },
                      ),
                  ],
                ),
                filled: true,
                fillColor: widget.startWithScanner
                    ? _positive.withValues(alpha: .08)
                    : _scheme.surfaceContainerLow,
                // ... geri kalan
              ),
            ),
          ),

          // Sonuç Sayısı
          if (filteredItems.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _scheme.surface,
              child: Text(
                '${filteredItems.length} ürün bulundu',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          SizedBox(height: 8),

          // Liste
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 72,
                          color: _scheme.outlineVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Sonuç bulunamadı',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            color: _scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Farklı bir arama deneyin',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: _scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredItems.length,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];

                      // Barkodları al
                      List<String> barkodlar = [];
                      if (widget.getBarcodes != null) {
                        try {
                          barkodlar = widget.getBarcodes!(item);
                        } catch (e) {
                          // Sessizce devam et
                        }
                      }

                      // Ölçü birimini al
                      String? olcuBirimi;
                      if (widget.getUnit != null) {
                        try {
                          olcuBirimi = widget.getUnit!(item);
                        } catch (e) {
                          // Sessizce devam et
                        }
                      }

                      return GestureDetector(
                        onTap: () => Navigator.pop(context, item),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _scheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _scheme.outlineVariant),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // İkon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _scheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  color: _scheme.onSurface,
                                  size: 22,
                                ),
                              ),
                              SizedBox(width: 12),

                              // İçerik
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Ürün Adı
                                    Text(
                                      widget.itemText(item),
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: _scheme.onSurface,
                                        height: 1.3,
                                      ),
                                    ),

                                    // Ölçü Birimi ve Barkodlar
                                    if (olcuBirimi != null ||
                                        barkodlar.isNotEmpty) ...[
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          // Ölçü Birimi
                                          if (olcuBirimi != null &&
                                              olcuBirimi.isNotEmpty) ...[
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _positive.withValues(
                                                    alpha: .08),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: _positive.withValues(
                                                      alpha: .3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                olcuBirimi,
                                                style: TextStyle(
                                                  fontFamily: 'Roboto',
                                                  fontSize: 11,
                                                  color: _positive,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ],

                                          // Ayırıcı
                                          if (olcuBirimi != null &&
                                              olcuBirimi.isNotEmpty &&
                                              barkodlar.isNotEmpty) ...[
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8),
                                              child: Container(
                                                width: 1,
                                                height: 14,
                                                color: _scheme.outlineVariant,
                                              ),
                                            ),
                                          ],

                                          // Barkodlar
                                          if (barkodlar.isNotEmpty) ...[
                                            Icon(
                                              Icons.qr_code_scanner_rounded,
                                              size: 14,
                                              color: _scheme.onSurfaceVariant,
                                            ),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                barkodlar.join(' • '),
                                                style: TextStyle(
                                                  fontFamily: 'Roboto',
                                                  fontSize: 12,
                                                  color:
                                                      _scheme.onSurfaceVariant,
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: 0.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Ok İkonu
                              Icon(
                                Icons.chevron_right_rounded,
                                color: _scheme.onSurfaceVariant,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
