import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:FilERP/widgets/corporate_menu_icon.dart';
import '../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../models/yazici/yazici_sablon.dart';
import '../../services/yazici/yazici_sablon_service.dart';
import 'sablon_duzenleyici_page.dart';

class YaziciSablonListesiPage extends StatefulWidget {
  const YaziciSablonListesiPage({super.key});

  @override
  State<YaziciSablonListesiPage> createState() =>
      _YaziciSablonListesiPageState();
}

class _YaziciSablonListesiPageState extends State<YaziciSablonListesiPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _kRed => _scheme.primary;
  Color get _kDark => _scheme.onSurface;
  Color get _kBg => Theme.of(context).scaffoldBackgroundColor;

  final _svc = YaziciSablonService.instance;
  List<YaziciSablon> _sablonlar = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _svc.getSablonlar();
    if (mounted)
      setState(() {
        _sablonlar = list;
        _loading = false;
      });
  }

  Future<void> _yeniSablon() async {
    final result = await Navigator.push<bool>(
      context,
      PermissionMaterialPageRoute(
          builder: (_) => const SablonDuzenleyiciPage()),
    );
    if (result == true) _load();
  }

  Future<void> _duzenle(YaziciSablon s) async {
    final result = await Navigator.push<bool>(
      context,
      PermissionMaterialPageRoute(
          builder: (_) => SablonDuzenleyiciPage(editSablon: s)),
    );
    if (result == true) _load();
  }

  Future<void> _sil(YaziciSablon s) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Şablonu Sil'),
        content: Text('"${s.ad}" şablonu silinecek.'),
        actions: [
          ErpDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: Text('İptal')),
          ErpDialogAction(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: _kRed),
              child: Text('Sil')),
        ],
      ),
    );
    if (onay == true) {
      await _svc.delete(s.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _kDark,
        elevation: 0,
        title: Text('Baskı Şablonları'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(height: 1, color: _scheme.surfaceContainerLow),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _kRed))
          : _sablonlar.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 88),
                  itemCount: _sablonlar.length,
                  itemBuilder: (_, i) => _sablonKart(_sablonlar[i]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kRed,
        foregroundColor: _scheme.onPrimary,
        icon: Icon(Icons.add_rounded, size: 20),
        label: Text('Yeni Şablon',
            style:
                TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600)),
        onPressed: _yeniSablon,
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: _scheme.outlineVariant),
            SizedBox(height: 16),
            Text('Henüz şablon yok',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    color: _scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            TextButton(
              onPressed: _yeniSablon,
              child: Text('Yeni Şablon Oluştur'),
            ),
          ],
        ),
      );

  Widget _sablonKart(YaziciSablon s) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _scheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _scheme.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: () => _duzenle(s),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Row(children: [
                  const CorporateMenuIcon('Yazıcı Şablonları', size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(s.ad,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('${s.satirlar.length} satır',
                            style: TextStyle(
                                fontSize: 11, color: _scheme.onSurfaceVariant))
                      ])),
                  PopupMenuButton<String>(
                      tooltip: 'Şablon İşlemleri',
                      onSelected: (action) =>
                          action == 'edit' ? _duzenle(s) : _sil(s),
                      itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text('Düzenle')),
                            const PopupMenuItem(
                                value: 'delete', child: Text('Sil'))
                          ]),
                ]))),
      ));
}
