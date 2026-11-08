import 'package:FilERP/widgets/document_filter_button.dart';
import 'package:FilERP/widgets/document_list_actions.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/widgets/invoice_modern_ui.dart';
import 'package:FilERP/helpers/electronic_document_filter.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../../widgets/erp_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../models/entities/irsaliye/irsaliye_dto.dart';
import '../../../services/irsaliye/irsaliye_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/response.dart';
import '../../../widgets/yetki_hatasi_widget.dart';
import '../../../helpers/belge_durum_helper.dart';
import '../../../helpers/number_format_helper.dart';
import 'alisirsaliye_ekle_page.dart';
import 'alisirsaliye_detay_page.dart';

class AlisIrsaliyeList extends StatefulWidget {
  const AlisIrsaliyeList({super.key});

  @override
  State<AlisIrsaliyeList> createState() => _AlisIrsaliyeListState();
}

class _AlisIrsaliyeListState extends State<AlisIrsaliyeList> {
  // ─── Renkler ─────────────────────────────────────────────
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.onSurface;
  Color get _accent => _scheme.primary;
  Color get _surface => Theme.of(context).scaffoldBackgroundColor;

  final _service = IrsaliyeService();
  bool _loading = false;
  bool _yetkiHatasi = false;
  List<IrsaliyeDto> _list = [];
  //Map<int, String>  _subeMap = {};

  final _searchCtrl = TextEditingController();
  int? _durumFilter; // null=tümü, 0=taslak, 1=onaylı
  int? _eirsaliyeFilter; // null=tümü, 3=E-Belge, 1=Portal

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
      _list = await _service.getAlisList(token);
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

  List<IrsaliyeDto> get _filtered {
    final q = _searchCtrl.text.toLowerCase().trim();
    return _list.where((f) {
      final matchSearch = q.isEmpty ||
          (f.belgeserino ?? '').toLowerCase().contains(q) ||
          (f.cari?.Ad ?? '').toLowerCase().contains(q) ||
          (f.cari?.Kod ?? '').toLowerCase().contains(q) ||
          (f.aciklama ?? '').toLowerCase().contains(q);
      final matchDurum = _durumFilter == null || f.belgedurum == _durumFilter;
      final matchEirsaliye =
          ElectronicDocumentFilter.matches(f.eirsaliyedurum, _eirsaliyeFilter);
      return matchSearch && matchDurum && matchEirsaliye;
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
      electronic: _eirsaliyeFilter,
      showElectronic: true,
      onApply: (selection) => setState(() {
            _durumFilter = selection.status;
            _eirsaliyeFilter = selection.electronic;
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
          modules: [502],
          access: Access.create,
          child: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                  context,
                  PermissionMaterialPageRoute(
                      builder: (_) => const AlisIrsaliyeEklePage()));
              if (result != null) _load();
            },
            backgroundColor: _accent,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: const Icon(Icons.add),
            label: const Text("Yeni Alış İrsaliyesi",
                style: TextStyle(fontWeight: FontWeight.bold)),
          )),
    );
  }

  // ─── APPBAR ──────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() => ErpPageAppBar(
        context: context,
        title: Text("Alış İrsaliyeleri",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _scheme.onSurface)),
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
              tooltip: "Yenile"),
        ],
      );

  // ─── ARAMA ───────────────────────────────────────────────
  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'İrsaliye no, cari veya açıklama ara...',
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
          ),
        ),
      );

  Widget _buildSummaryBar() => ErpListOverview(
        count:
            '${_filtered.length} irsaliye • ${NumberFormatHelper.format(_filtered.fold<double>(0, (s, f) => s + (f.geneltoplam ?? 0)))} ₺',
      );

  Widget _buildCard(IrsaliyeDto f) => ErpDocumentCard(
        number: f.belgeserino ?? '-',
        date: f.tarih == null ? '-' : _dateFmt.format(f.tarih!),
        customer: f.cari?.Ad ?? 'Cari bilgisi yok',
        customerCode: f.cari?.Kod ?? '',
        amount: '${NumberFormatHelper.format(f.geneltoplam ?? 0)} ₺',
        status: BelgeDurumHelper.adById(f.belgedurum),
        statusColor: BelgeDurumHelper.renkById(f.belgedurum),
        icon: Icons.local_shipping_outlined,
        note: f.aciklama,
        electronicStatus: (f.eirsaliyedurum ?? 0) > 0 ? 'E-İrsaliye' : null,
        action: _belgeIslemleri(f),
        onTap: () async {
          final result = await Navigator.push(
              context,
              PermissionMaterialPageRoute(
                  builder: (_) => const AlisIrsaliyeDetayPage(),
                  settings: RouteSettings(arguments: f.id)));
          if (result != null && mounted) _load();
        },
      );

  Widget _belgeIslemleri(IrsaliyeDto f) => DocumentListActions(
      module: 502,
      id: f.id ?? '',
      number: f.belgeserino ?? 'İrsaliye',
      status: f.belgedurum ?? 0,
      electronicStatus: f.eirsaliyedurum ?? 0,
      onStatusChange: (status) => _belgeDurumDegistir(f, status),
      onRefresh: _load,
      onDelete: () => _sil(f),
      onEdit: () async {
        final result = await Navigator.push(
            context,
            PermissionMaterialPageRoute(
                builder: (_) => AlisIrsaliyeEklePage(irsaliyeId: f.id)));
        if (result == true && mounted) await _load();
      });

  Future<void> _belgeDurumDegistir(IrsaliyeDto f, int yeniDurum) async {
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
                color:
                    taslakaMi ? Colors.orange.shade50 : const Color(0xFFE8F5E9),
              ),
              child: Icon(
                taslakaMi
                    ? Icons.undo_rounded
                    : Icons.check_circle_outline_rounded,
                size: 36,
                color: taslakaMi
                    ? Colors.orange.shade700
                    : const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 20),
            Text(taslakaMi ? "Taslağa Çek" : "Belgeyi Tamamla",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              taslakaMi
                  ? "${f.belgeserino ?? 'Bu kayıt'} taslak durumuna alınacak."
                  : "${f.belgeserino ?? 'Bu kayıt'} tamamlandı olarak işaretlenecek.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: _scheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 24),
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
                      modules: [502],
                      access: Access.create,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: taslakaMi
                                ? Colors.orange.shade700
                                : const Color(0xFF2E7D32),
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0),
                        child: Text(taslakaMi ? "Taslağa Çek" : "Tamamla",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
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
                    const SizedBox(height: 16),
                    Text(taslakaMi ? "Taslağa alınıyor..." : "Tamamlanıyor...",
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ])),
            )));

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await _service.alisBelgeDurumGuncelle(token, f.id!, yeniDurum);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (taslakaMi) {
        UiFeedback.showWarning(context, "İrsaliye taslağa alındı");
      } else {
        UiFeedback.showUpdated(context, "İrsaliye tamamlandı");
      }
      _load();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      UiFeedback.showException(context, e);
    }
  }

  // ─── SİL ─────────────────────────────────────────────────
  Future<void> _sil(IrsaliyeDto f) async {
    final confirm = await UiFeedback.confirm(context,
        title: "İrsaliye Sil",
        message: "${f.belgeserino ?? 'Bu kayıt'} silinecek. Emin misiniz?",
        destructive: true);
    if (confirm != true || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await _service.removeAlisWithItems(token, f.id!);
      if (mounted) {
        UiFeedback.showDeleted(context, "İrsaliye silindi");
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
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isNotEmpty || _durumFilter != null
                ? "Arama kriterlerine uygun irsaliye bulunamadı"
                : "Henüz irsaliye yok",
            style: TextStyle(
                fontSize: 15,
                color: _scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text("Yeni irsaliye eklemek için + butonuna basın",
              style: TextStyle(fontSize: 13, color: _scheme.onSurfaceVariant)),
        ])),
      ]);
}
