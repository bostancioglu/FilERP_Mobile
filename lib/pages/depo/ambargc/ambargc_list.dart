import 'package:FilERP/widgets/document_filter_button.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../widgets/erp_page_style.dart';
import '../../../widgets/erp_ui.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../models/entities/depo/ambargc_dto.dart';
import '../../../services/depo/ambargc/ambargc_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/response.dart';
import '../../../widgets/yetki_hatasi_widget.dart';
import '../../../helpers/belge_durum_helper.dart';
import '../../../helpers/number_format_helper.dart';
import 'ambargc_ekle_page.dart';
import 'ambargc_detay_page.dart';

class AmbargcList extends StatefulWidget {
  const AmbargcList({super.key});

  @override
  State<AmbargcList> createState() => _AmbargcListState();
}

class _AmbargcListState extends State<AmbargcList> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _accent => _scheme.primary;
  Color get _surface => Theme.of(context).scaffoldBackgroundColor;

  // ─── Renkler ─────────────────────────────────────────────

  final _service = AmbargcService();
  bool _loading = false;
  bool _yetkiHatasi = false;
  List<AmbargcDto> _list = [];
  //Map<int, String>  _subeMap = {};

  final _searchCtrl = TextEditingController();
  int? _durumFilter; // null=tümü, 0=taslak, 1=onaylı

  final _dateFmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      _list = await _service.getList(token);
    } catch (e) {
      if (e is YetkiHatasi) {
        if (mounted) setState(() => _yetkiHatasi = true);
      } else {
        if (mounted) UiFeedback.showException(context, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AmbargcDto> get _filtered {
    final q = _searchCtrl.text.toLowerCase().trim();
    return _list.where((f) {
      final matchSearch = q.isEmpty ||
          (f.belgeserino ?? '').toLowerCase().contains(q) ||
          (f.aciklama ?? '').toLowerCase().contains(q);
      final matchDurum = _durumFilter == null || f.belgedurum == _durumFilter;
      return matchSearch && matchDurum;
    }).toList()
      ..sort((a, b) {
        final t = (b.tarih ?? DateTime(0)).compareTo(a.tarih ?? DateTime(0));
        if (t != 0) return t;
        return (b.belgeserino ?? '').compareTo(a.belgeserino ?? '');
      });
  }

  // ─── BUILD ───────────────────────────────────────────────
  Widget _filterButton() => DocumentFilterButton(
      status: _durumFilter,
      onApply: (selection) => setState(() {
            _durumFilter = selection.status;
          }));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: _yetkiHatasi
          ? const YetkiHatasiWidget()
          : Column(children: [
              _buildSearchBar(),
              _buildSummaryBar(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _accent,
                        child: _filtered.isEmpty
                            ? _buildEmpty()
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 4, 12, 100),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) => _buildCard(_filtered[i]),
                              ),
                      ),
              ),
            ]),
      floatingActionButton: PermissionAction(
          modules: [1301],
          access: Access.create,
          child: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                  context,
                  PermissionMaterialPageRoute(
                      builder: (_) => const AmbargcEklePage()));
              if (result != null) _load();
            },
            backgroundColor: _accent,
            foregroundColor: _scheme.onPrimary,
            icon: const Icon(Icons.add),
            label: const Text("Yeni Ambar G/Ç",
                style: TextStyle(
                    fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
          )),
    );
  }

  // ─── APPBAR ──────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() => ErpPageAppBar(
          context: context,
          title: const Text('Ambar Giriş / Çıkış',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          backgroundColor: _scheme.surface,
          foregroundColor: _scheme.onSurface,
          actions: [
            IconButton(
                tooltip: 'Yenile',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _load)
          ]);

  Widget _buildSearchBar() => Container(
      color: _scheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
              hintText: 'Belge No',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                      tooltip: 'Aramayı temizle',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      }),
                _filterButton(),
              ]),
              filled: true,
              fillColor: _surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none))));
  Widget _buildSummaryBar() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(
            child: Text('${_filtered.length} fiş',
                style:
                    TextStyle(fontSize: 12, color: _scheme.onSurfaceVariant))),
        Expanded(
            child: Text(
                '${NumberFormatHelper.format(_filtered.fold<double>(0, (s, f) => s + (f.geneltoplam ?? 0)))} ₺',
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700))),
      ]));

  Widget _buildCard(AmbargcDto f) => ErpDocumentCard(
        number: f.belgeserino ?? '-',
        date: f.tarih == null ? '-' : _dateFmt.format(f.tarih!),
        customer:
            '${f.giriscikis == 2 ? 'Ambar Çıkışı' : 'Ambar Girişi'}${f.sube?.ad?.isNotEmpty == true ? ' · ${f.sube!.ad}' : ''}',
        customerCode: '',
        amount: '${NumberFormatHelper.format(f.geneltoplam ?? 0)} ₺',
        status: BelgeDurumHelper.adById(f.belgedurum),
        statusColor: BelgeDurumHelper.renkById(f.belgedurum),
        icon: f.giriscikis == 2 ? Icons.output_rounded : Icons.input_rounded,
        onMenu: () => _showKartMenu(f),
        onTap: () async {
          final result = await Navigator.push(
              context,
              PermissionMaterialPageRoute(
                  builder: (_) => const AmbargcDetayPage(),
                  settings: RouteSettings(arguments: f.id)));
          if (result != null && mounted) _load();
        },
      );

  void _showKartMenu(AmbargcDto f) {
    final taslak = (f.belgedurum ?? 0) == 0;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                  color: _scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.blue),
            title: const Text("Düzenle"),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                  context,
                  PermissionMaterialPageRoute(
                      builder: (_) => AmbargcEklePage(ambargcId: f.id)));
              if (result == true && mounted) _load();
            },
          ),
          ListTile(
            leading: Icon(
                taslak
                    ? Icons.check_circle_outline_rounded
                    : Icons.undo_rounded,
                color: taslak ? _scheme.primary : Colors.orange.shade700),
            title: Text(taslak ? "Belgeyi Tamamla" : "Taslağa Çek",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    color: taslak ? _scheme.primary : Colors.orange.shade700)),
            onTap: () async {
              Navigator.pop(context);
              await _belgeDurumDegistir(f, taslak ? 1 : 0);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red.shade600),
            title: Text("Sil",
                style: TextStyle(
                    fontFamily: 'Roboto', color: Colors.red.shade600)),
            onTap: () async {
              Navigator.pop(context);
              await _sil(f);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ─── BELGE DURUM DEĞİŞTİR ────────────────────────────────
  Future<void> _belgeDurumDegistir(AmbargcDto f, int yeniDurum) async {
    final taslakaMi = yeniDurum == 0;
    final onay = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: taslakaMi
                    ? _scheme.primaryContainer
                    : _scheme.primaryContainer,
              ),
              child: Icon(
                taslakaMi
                    ? Icons.undo_rounded
                    : Icons.check_circle_outline_rounded,
                size: 36,
                color: taslakaMi ? Colors.orange.shade700 : _scheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(taslakaMi ? "Taslağa Çek" : "Belgeyi Tamamla",
                style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              taslakaMi
                  ? "${f.belgeserino ?? 'Bu kayıt'} taslak durumuna alınacak."
                  : "${f.belgeserino ?? 'Bu kayıt'} tamamlandı olarak işaretlenecek.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color: _scheme.onSurfaceVariant,
                  height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("Vazgeç"),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: PermissionAction(
                      modules: [1301],
                      access: Access.create,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: taslakaMi
                                ? Colors.orange.shade700
                                : _scheme.primary,
                            foregroundColor: _scheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0),
                        child: Text(taslakaMi ? "Taslağa Çek" : "Tamamla",
                            style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.bold)),
                      ))),
            ]),
          ]),
        ),
      ),
    );

    if (onay != true || !mounted) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
                child: Card(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(taslakaMi ? "Taslağa alınıyor..." : "Tamamlanıyor...",
                        style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ])),
            )));

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await _service.belgeDurumGuncelle(token, f.id!, yeniDurum);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (taslakaMi) {
        UiFeedback.showWarning(context, "Ambar fişi taslağa alındı");
      } else {
        UiFeedback.showUpdated(context, "Ambar fişi tamamlandı");
      }
      _load();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      UiFeedback.showException(context, e);
    }
  }

  // ─── SİL ─────────────────────────────────────────────────
  Future<void> _sil(AmbargcDto f) async {
    final confirm = await UiFeedback.confirm(context,
        title: "Ambar Fişi Sil",
        message: "${f.belgeserino ?? 'Bu kayıt'} silinecek. Emin misiniz?",
        destructive: true);
    if (confirm != true || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await _service.removeWithItems(token, f.id!);
      if (mounted) {
        UiFeedback.showDeleted(context, "Ambar fişi silindi");
        _load();
      }
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    }
  }

  // ─── BOŞ EKRAN ───────────────────────────────────────────
  Widget _buildEmpty() => ListView(children: [
        const SizedBox(height: 80),
        Center(
            child: Column(children: [
          Icon(Icons.local_shipping_outlined,
              size: 64, color: _scheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            _searchCtrl.text.isNotEmpty || _durumFilter != null
                ? "Arama kriterlerine uygun kayıt bulunamadı"
                : "Henüz kayıt yok",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                color: _scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500),
          ),
        ])),
      ]);
}
