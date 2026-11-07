import 'package:FilERP/widgets/document_filter_button.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../widgets/erp_page_style.dart';
import '../../../widgets/erp_transfer_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../models/entities/depo/dat_dto.dart';
import '../../../models/entities/firma/sube_dto.dart';
import '../../../services/depo/dat/dat_service.dart';
import '../../../services/yonetim/sube_service.dart';
import '../../../services/offline/offline_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/response.dart';
import '../../../widgets/yetki_hatasi_widget.dart';
import '../../../helpers/belge_durum_helper.dart';
import '../../ayarlar/ayarlar_page.dart';
import 'arac_yukle_ekle_page.dart';
import 'dat_ekle_page.dart';
import 'rapor/malzeme_ambar_durum_raporu.dart';

class DatListPage extends StatefulWidget {
  /// true: "Araç Yüklemeleri" — DAT ile aynı veri, kayıtlar Araç Yükleme ekranında açılır/eklenir.
  final bool aracYukleme;

  const DatListPage({super.key, this.aracYukleme = false});

  @override
  State<DatListPage> createState() => _DatListPageState();
}

class _DatListPageState extends State<DatListPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.primary;
  Color get _accent => _scheme.primary;
  Color get _surface => Theme.of(context).scaffoldBackgroundColor;
  Color get _offlineColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFCD34D)
      : const Color(0xFF9A6700);

  final _service = DatService();
  bool _loading = false;
  bool _yetkiHatasi = false;
  List<DatDto> _list = [];
  List<OfflineQueueItem> _offlineItems = [];
  Map<int, String> _subeMap = {}; // id → ad
  final _searchCtrl = TextEditingController();
  int? _durumFilter;

  final _dateFmt = DateFormat('dd.MM.yyyy');

  bool get _arac => widget.aracYukleme;
  String get _ad => _arac ? 'Araç Yükleme' : 'DAT';

  Widget _yeniSayfa() =>
      _arac ? const AracYukleEklePage() : const DatEklePage();

  Widget _duzenleSayfa({String? datId, OfflineQueueItem? queueItem}) => _arac
      ? AracYukleEklePage(datId: datId, queueItem: queueItem)
      : DatEklePage(datId: datId, queueItem: queueItem);

  @override
  void initState() {
    super.initState();
    _load();
    OfflineService.instance.pendingCount.addListener(_refreshOffline);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    OfflineService.instance.pendingCount.removeListener(_refreshOffline);
    super.dispose();
  }

  void _refreshOffline() {
    if (mounted)
      setState(() {
        _offlineItems = OfflineService.instance
            .getAll()
            .where((i) => i.type == 'dat_full' && i.status == 'pending')
            .toList();
      });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final results = await Future.wait([
        _service.getList(token),
        SubeService().getAll(token),
      ]);
      _list = results[0] as List<DatDto>;
      final subeler = results[1] as List<SubeDto>;
      _subeMap = {
        for (final s in subeler)
          if (s.id != null) s.id!: s.ad ?? ''
      };
      _offlineItems = OfflineService.instance
          .getAll()
          .where((i) => i.type == 'dat_full' && i.status == 'pending')
          .toList();
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

  List<DatDto> get _filtered {
    final q = _searchCtrl.text.toLowerCase().trim();
    return _list.where((d) {
      final matchSearch = q.isEmpty ||
          (d.belgeserino ?? '').toLowerCase().contains(q) ||
          (d.sube?.ad ?? '').toLowerCase().contains(q) ||
          (d.gidecegisube?.ad ?? '').toLowerCase().contains(q) ||
          (d.belgeno ?? '').toLowerCase().contains(q) ||
          (d.aciklama ?? '').toLowerCase().contains(q);
      final matchDurum = _durumFilter == null || d.belgedurum == _durumFilter;
      return matchSearch && matchDurum;
    }).toList()
      ..sort(
          (a, b) => (b.tarih ?? DateTime(0)).compareTo(a.tarih ?? DateTime(0)));
  }

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
      floatingActionButton: PermissionAction(
          modules: [801],
          access: Access.create,
          child: FloatingActionButton.extended(
            backgroundColor: _accent,
            foregroundColor: _scheme.onPrimary,
            icon: const Icon(Icons.add_rounded),
            label: Text(_arac ? "Araç Yükle" : "Yeni Transfer",
                style: const TextStyle(
                    fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
            onPressed: () async {
              final result = await Navigator.push(context,
                  PermissionMaterialPageRoute(builder: (_) => _yeniSayfa()));
              if (result == true && mounted) _load();
            },
          )),
      body: _yetkiHatasi
          ? const YetkiHatasiWidget()
          : Column(
              children: [
                _buildFilterBar(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : (_filtered.isEmpty && _offlineItems.isEmpty)
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 80),
                                children: [
                                  // Offline bekleyen kayıtlar üstte
                                  ..._offlineItems.map(_buildOfflineCard),
                                  // API kayıtları
                                  ..._filtered.map(_buildCard),
                                ],
                              ),
                            ),
                ),
              ],
            ),
    );
  }

  AppBar _buildAppBar() {
    return ErpPageAppBar(
      context: context,
      backgroundColor: _scheme.surface,
      foregroundColor: _scheme.onSurface,
      elevation: 0,
      title: Text(_arac ? "Araç Yüklemeleri" : "Depo Transferleri",
          style: const TextStyle(
              fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 17)),
      actions: [
        // Bekleyen offline kayıt sayacı
        ValueListenableBuilder<int>(
          valueListenable: OfflineService.instance.pendingCount,
          builder: (_, count, __) => count > 0
              ? IconButton(
                  tooltip:
                      "$count ${_arac ? 'araç yükleme' : 'DAT'} bekliyor — sync için tıkla",
                  onPressed: () => Navigator.push(
                      context,
                      PermissionMaterialPageRoute(
                          builder: (_) => const AyarlarPage())),
                  icon: Badge(
                    label: Text("$count",
                        style: const TextStyle(
                            fontFamily: 'Roboto', fontSize: 10)),
                    child: const Icon(Icons.cloud_upload_outlined),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded),
          onPressed: _openRaporlarMenu,
          tooltip: "Raporlar",
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _load,
          tooltip: "Yenile",
        ),
      ],
    );
  }

  void _openRaporlarMenu() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Raporlar",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _primary)),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child:
                        Icon(Icons.warehouse_rounded, color: _accent, size: 20),
                  ),
                  title: const Text("Malzeme Ambar Durum Raporu",
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                        context,
                        PermissionMaterialPageRoute(
                            builder: (_) => const MalzemeAmbarDurumRaporu()));
                  },
                ),
                const SizedBox(height: 4),
              ]),
        ),
      ),
    );
  }

  Widget _buildFilterBar() => Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
              hintText: 'Belge No veya Şube',
              prefixIcon: Icon(Icons.search_rounded),
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
              ]))));

  Widget _buildOfflineCard(OfflineQueueItem item) {
    final dat = item.payload['dat'] as Map<String, dynamic>;
    final belgeNo = '${dat['belgeseri'] ?? ''}-${dat['belgeno'] ?? ''}';
    final tarih =
        dat['tarih'] != null ? DateTime.tryParse(dat['tarih'] as String) : null;
    final cikisSube = _subeMap[dat['subeid'] as int?] ?? '-';
    final girisSube = _subeMap[dat['gidecegisubeid'] as int?] ?? '-';
    final kalemSayisi = (item.payload['kalemler'] as List?)?.length ?? 0;

    return ErpTransferCard(
        number: belgeNo.trim() == '-' ? 'Yeni Transfer' : belgeNo,
        date: tarih == null ? '-' : _dateFmt.format(tarih),
        source: cikisSube,
        target: girisSube,
        status: 'Gönderim Bekliyor',
        statusColor: _offlineColor,
        itemCount: kalemSayisi,
        offline: true,
        onMenu: () => _showOfflineKartMenu(item),
        onTap: () async {
          final result = await Navigator.push(
              context,
              PermissionMaterialPageRoute(
                  builder: (_) => _duzenleSayfa(queueItem: item)));
          if (result == true && mounted) _load();
        });
  }

  void _showOfflineKartMenu(OfflineQueueItem item) {
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
                    builder: (_) => _duzenleSayfa(queueItem: item)));
            if (result == true && mounted) _load();
          },
        ),
        ListTile(
          leading: const Icon(Icons.sync_rounded, color: Colors.green),
          title: const Text("Şimdi Gönder"),
          onTap: () async {
            Navigator.pop(context);
            await OfflineService.instance.retryItem(item.localId);
            if (mounted) _load();
          },
        ),
        ListTile(
          leading: Icon(Icons.delete_outline, color: Colors.red.shade600),
          title: Text("Sil",
              style:
                  TextStyle(fontFamily: 'Roboto', color: Colors.red.shade600)),
          onTap: () async {
            Navigator.pop(context);
            final ok = await UiFeedback.confirm(context,
                title: "Offline $_ad Sil",
                message:
                    "Bu kayıt henüz gönderilmedi. Silinirse kaybolur. Emin misiniz?",
                destructive: true);
            if (ok == true) {
              await OfflineService.instance.deleteItem(item.localId);
              if (mounted) setState(() => _offlineItems.remove(item));
            }
          },
        ),
        const SizedBox(height: 8),
      ])),
    );
  }

  Widget _buildCard(DatDto d) => ErpTransferCard(
        number: d.belgeserino ?? '-',
        date: d.tarih == null ? '-' : _dateFmt.format(d.tarih!),
        source: d.sube?.ad ?? _subeMap[d.subeid] ?? '-',
        target: d.gidecegisube?.ad ?? _subeMap[d.gidecegisubeid] ?? '-',
        status: BelgeDurumHelper.adById(d.belgedurum),
        statusColor: BelgeDurumHelper.renkById(d.belgedurum),
        itemCount: d.dathareket.length,
        onMenu: () => _showKartMenu(context, d),
        onTap: () async {
          final result = await Navigator.push(
              context,
              PermissionMaterialPageRoute(
                  builder: (_) => _duzenleSayfa(datId: d.id)));
          if (result == true && mounted) _load();
        },
      );

  void _showKartMenu(BuildContext context, DatDto d) {
    final taslak = (d.belgedurum ?? 0) == 0;
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
          // Düzenle ve Sil sadece taslak belgede göster
          if (taslak) ...[
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blue),
              title: const Text("Düzenle"),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                    context,
                    PermissionMaterialPageRoute(
                        builder: (_) => _duzenleSayfa(datId: d.id)));
                if (result == true && mounted) _load();
              },
            ),
          ],
          ListTile(
            leading: Icon(
              taslak ? Icons.check_circle_outline_rounded : Icons.undo_rounded,
              color: taslak ? _scheme.primary : Colors.orange.shade700,
            ),
            title: Text(
              taslak ? "Belgeyi Tamamla" : "Taslağa Çek",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  color: taslak ? _scheme.primary : Colors.orange.shade700),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _belgeDurumDegistir(d, taslak ? 1 : 0);
            },
          ),
          // Sil sadece taslak belgede göster
          if (taslak)
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade600),
              title: Text("Sil",
                  style: TextStyle(
                      fontFamily: 'Roboto', color: Colors.red.shade600)),
              onTap: () async {
                Navigator.pop(context);
                await _silDat(d);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _belgeDurumDegistir(DatDto d, int yeniDurum) async {
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
                  ? "${d.belgeserino ?? d.belgeno ?? 'Bu kayıt'} taslak durumuna alınacak."
                  : "${d.belgeserino ?? d.belgeno ?? 'Bu kayıt'} tamamlandı olarak işaretlenecek.",
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
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Vazgeç"),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: PermissionAction(
                      modules: [801],
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
                          elevation: 0,
                        ),
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

    // ── Offline mod veya internet yoksa kuyruğa al ─────────────────────
    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (manuelOffline || internetYok) {
      await OfflineService.instance.enqueue('dat_status_change', {
        'datId': d.id!,
        'durum': yeniDurum,
      });
      if (!mounted) return;
      UiFeedback.showSuccess(
          context,
          taslakaMi
              ? "Taslağa çekme kuyruğa alındı"
              : "Tamamlama kuyruğa alındı");
      return;
    }

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
      await _service.belgeDurumGuncelle(token, d.id!, yeniDurum);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (taslakaMi) {
        UiFeedback.showWarning(context, "$_ad taslağa alındı");
      } else {
        UiFeedback.showUpdated(context, "$_ad tamamlandı");
      }
      _load();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      UiFeedback.showException(context, e);
    }
  }

  Future<void> _silDat(DatDto d) async {
    final confirm = await UiFeedback.confirm(
      context,
      title: "$_ad Sil",
      message:
          "${d.belgeserino ?? d.belgeno ?? 'Bu kayıt'} silinecek. Emin misiniz?",
      destructive: true,
    );
    if (confirm != true || !mounted) return;

    // ── Offline mod veya internet yoksa kuyruğa al ─────────────────────
    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (manuelOffline || internetYok) {
      await OfflineService.instance.enqueue('dat_delete', {'datId': d.id!});
      if (mounted)
        UiFeedback.showSuccess(context, "Silme işlemi kuyruğa alındı");
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await _service.deleteDat(token, d.id!);
      if (mounted) {
        UiFeedback.showDeleted(context, "$_ad silindi");
        _load();
      }
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_arac ? Icons.local_shipping_rounded : Icons.swap_horiz_rounded,
              size: 64, color: _scheme.outlineVariant),
          const SizedBox(height: 12),
          Text(_arac ? "Araç yükleme bulunamadı" : "Transfer bulunamadı",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  color: _scheme.onSurfaceVariant,
                  fontSize: 16)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Yenile"),
          ),
        ],
      ),
    );
  }
}
