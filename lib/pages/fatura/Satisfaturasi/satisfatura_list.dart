import 'fatura_ekle_page.dart';
import 'package:FilERP/widgets/document_filter_button.dart';
import 'package:FilERP/widgets/document_list_actions.dart';
import 'package:FilERP/services/ebelge/portal_service.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:FilERP/helpers/electronic_document_filter.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/invoice_modern_ui.dart';
import 'package:flutter/material.dart';
import '../../../widgets/erp_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../models/entities/fatura/fatura_list_dto.dart';
import '../../../services/fatura/fatura_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/response.dart';
import '../../../widgets/yetki_hatasi_widget.dart';
import '../../../helpers/para_birimi_helper.dart';
import '../../../helpers/belge_durum_helper.dart';
import '../../../helpers/stokhareket_couples.dart';
import 'fatura_ekle_page.dart';

class SatisFaturaListPage extends StatefulWidget {
  const SatisFaturaListPage({super.key});

  @override
  State<SatisFaturaListPage> createState() => _SatisFaturaListPageState();
}

class _SatisFaturaListPageState extends State<SatisFaturaListPage> {
  bool get _modern => ErpDesignStyle.modern(context);
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.onSurface;
  Color get _accent => _scheme.primary;
  Color get _surface => Theme.of(context).scaffoldBackgroundColor;

  final service = FaturaService();
  bool loading = false;
  bool _yetkiHatasi = false;
  List<FaturaListDto> list = [];
  final TextEditingController searchCtrl = TextEditingController();
  int? belgeDurumFilter;
  int? efaturaFilter; // null=tümü, 3=E-Belge, 1=Portala Gönderildi

  final NumberFormat moneyFmt = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      list = await service.getSatisFaturaList(token);
    } catch (e) {
      if (e is YetkiHatasi) {
        if (mounted) setState(() => _yetkiHatasi = true);
      } else {
        if (mounted) UiFeedback.showException(context, e);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String fmtDate(DateTime? d) {
    if (d == null) return "-";
    return "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";
  }

  List<FaturaListDto> get filteredList {
    final q = searchCtrl.text.toLowerCase().trim();
    return list.where((f) {
      final matchSearch = q.isEmpty ||
          (f.belgeserino ?? "").toLowerCase().contains(q) ||
          (f.cari?.Ad ?? "").toLowerCase().contains(q) ||
          (f.cari?.Kod ?? "").toLowerCase().contains(q) ||
          (f.aciklama ?? "").toLowerCase().contains(q);
      final matchDurum =
          belgeDurumFilter == null || f.belgedurum == belgeDurumFilter;
      final matchEfatura =
          ElectronicDocumentFilter.matches(f.efaturadurum, efaturaFilter);
      return matchSearch && matchDurum && matchEfatura;
    }).toList()
      ..sort((a, b) {
        final tarihCmp =
            (b.tarih ?? DateTime(0)).compareTo(a.tarih ?? DateTime(0));
        if (tarihCmp != 0) return tarihCmp;
        return (b.belgeserino ?? '').compareTo(a.belgeserino ?? '');
      });
  }

  Widget _filterButton() => DocumentFilterButton(
      status: belgeDurumFilter,
      electronic: efaturaFilter,
      showElectronic: true,
      onApply: (selection) => setState(() {
            belgeDurumFilter = selection.status;
            efaturaFilter = selection.electronic;
          }));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: _yetkiHatasi
          ? const YetkiHatasiWidget()
          : Column(
              children: [
                _buildSearchBar(),
                _buildSummaryBar(),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: load,
                          color: _accent,
                          child: filteredList.isEmpty
                              ? _buildEmpty()
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 4, 12, 100),
                                  itemCount: filteredList.length,
                                  itemBuilder: (_, i) =>
                                      _buildCard(filteredList[i]),
                                ),
                        ),
                ),
              ],
            ),
      floatingActionButton: PermissionAction(
          modules: [301],
          access: Access.create,
          child: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const FaturaEklePage()),
              );
              if (result != null) load();
            },
            backgroundColor: _accent,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: const Icon(Icons.add),
            label: const Text("Yeni Fatura",
                style: TextStyle(fontWeight: FontWeight.bold)),
          )),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        "Satış Faturaları",
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: _modern ? Colors.white : _scheme.onSurface),
      ),
      backgroundColor: _modern ? const Color(0xFF14213D) : _scheme.surface,
      foregroundColor: _modern ? Colors.white : _scheme.onSurface,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: load,
          tooltip: "Yenile",
        ),
      ],
    );
  }

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: TextField(
          controller: searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: _modern
                ? 'Fatura / Cari'
                : 'Fatura no, cari veya açıklama ara...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
              if (searchCtrl.text.isNotEmpty)
                IconButton(
                    tooltip: 'Aramayı temizle',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      searchCtrl.clear();
                      setState(() {});
                    }),
              _filterButton(),
            ]),
          ),
        ),
      );

  Widget _buildSummaryBar() => _modern
      ? Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Row(children: [
            Text('${filteredList.length} Belge',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _scheme.onSurface)),
            const Spacer(),
            Text(
                '${filteredList.where((f) => f.belgedurum == 0).length} Taslak',
                style:
                    TextStyle(fontSize: 11, color: _scheme.onSurfaceVariant)),
          ]))
      : ErpListOverview(count: '${filteredList.length} fatura listeleniyor');

  Widget _buildCard(FaturaListDto f) {
    final isDoviz = f.dovizId != null && f.dovizId != 1;
    final toplam = isDoviz
        ? (f.dovizToplam ?? f.sonGenelToplam ?? f.genelToplam ?? 0)
        : (f.sonGenelToplam ?? f.genelToplam ?? 0);
    return InvoiceDocumentCard(
      number: f.belgeserino ?? '-',
      date: fmtDate(f.tarih),
      customer: f.cari?.Ad ?? 'Cari bilgisi yok',
      customerCode: f.cari?.Kod ?? '',
      amount:
          '${moneyFmt.format(toplam)} ${ParaBirimiHelper.sembolById(f.dovizId)}',
      status: BelgeDurumHelper.adById(f.belgedurum),
      statusColor: BelgeDurumHelper.renkById(f.belgedurum),
      icon: Icons.receipt_long_outlined,
      note: f.aciklama,
      electronicStatus: (f.efaturadurum ?? 0) > 0
          ? StokHareketCouples.efaturaDurumAdi(f.efaturadurum)
          : null,
      action: _belgeIslemleri(f),
      onTap: () async {
        final result = await Navigator.pushNamed(context, '/satis-fatura-detay',
            arguments: f.id);
        if (result != null && mounted) load();
      },
    );
  }

  Widget _belgeIslemleri(FaturaListDto f) => DocumentListActions(
      module: 301,
      id: f.id ?? '',
      number: f.belgeserino ?? 'Fatura',
      status: f.belgedurum ?? 0,
      electronicStatus: f.efaturadurum ?? 0,
      document: PortalDocument.invoice,
      onStatusChange: (status) => _durumDegistir(f, status),
      onRefresh: load,
      onEdit: () => _duzenle(f),
      onDelete: () => _sil(f));

  Future<void> _duzenle(FaturaListDto f) async {
    final changed = await Navigator.push(
        context,
        PermissionMaterialPageRoute(
            builder: (_) => FaturaEklePage(faturaId: f.id)));
    if (changed == true && mounted) await load();
  }

  Future<void> _sil(FaturaListDto f) async {
    final confirmed = await UiFeedback.confirm(context,
        title: 'Fatura Sil',
        message: '${f.belgeserino ?? "Fatura"} silinecek. Emin misiniz?',
        confirmLabel: 'Sil',
        destructive: true);
    if (!confirmed || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await service.deleteFatura(prefs.getString('token_final') ?? '', f.id!);
      if (!mounted) return;
      UiFeedback.showDeleted(context, 'Fatura silindi');
      await load();
    } catch (error) {
      if (mounted) UiFeedback.showException(context, error);
    }
  }

  Future<void> _durumDegistir(FaturaListDto f, int status) async {
    final draft = status == 0;
    final confirmed = await UiFeedback.confirm(context,
        title: draft ? 'Taslağa Çek' : 'Belgeyi Tamamla',
        message:
            '${f.belgeserino ?? "Fatura"} ${draft ? "taslak durumuna alınacak" : "tamamlanacak"}. Emin misiniz?',
        confirmLabel: draft ? 'Taslağa Çek' : 'Tamamla',
        cancelLabel: 'Vazgeç');
    if (!confirmed || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await service.belgeDurumGuncelle(
          prefs.getString('token_final') ?? '', f.id!, status);
      if (!mounted) return;
      UiFeedback.showUpdated(
          context, draft ? 'Fatura taslağa alındı' : 'Fatura tamamlandı');
      await load();
    } catch (error) {
      if (mounted) UiFeedback.showException(context, error);
    }
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 64, color: _scheme.outlineVariant),
              const SizedBox(height: 16),
              Text(
                searchCtrl.text.isNotEmpty || belgeDurumFilter != null
                    ? "Arama kriterlerine uygun fatura bulunamadı"
                    : "Henüz fatura yok",
                style: TextStyle(
                    fontSize: 15,
                    color: _scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                "Yeni fatura eklemek için + butonuna basın",
                style: TextStyle(fontSize: 13, color: _scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
