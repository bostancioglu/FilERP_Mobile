import 'package:FilERP/widgets/document_list_actions.dart';
import 'package:FilERP/widgets/document_filter_button.dart';
import 'package:FilERP/services/auth/menu_access.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/belge_durum_helper.dart';
import '../../helpers/number_format_helper.dart';
import '../../helpers/oncelik_couples.dart';
import '../../helpers/response.dart';
import '../../helpers/ui_feedback.dart';
import '../../models/entities/teklif/teklif_dto.dart';
import '../../services/teklif/teklif_service.dart';
import '../../widgets/erp_ui.dart';
import '../../widgets/yetki_hatasi_widget.dart';
import 'teklif_entry_page.dart';

class TeklifListPage extends StatefulWidget {
  final bool sales;
  const TeklifListPage({super.key, required this.sales});
  @override
  State<TeklifListPage> createState() => _TeklifListPageState();
}

class _TeklifListPageState extends State<TeklifListPage> {
  final _search = TextEditingController();
  List<TeklifDto> _quotes = [];
  bool _loading = true, _denied = false;
  int? _status;
  TeklifService get _service => TeklifService(sales: widget.sales);
  String get _kind => widget.sales ? 'Satış' : 'Alış';
  List<TeklifDto> get _filtered {
    final query = _search.text.trim().toLowerCase();
    return _quotes
        .where((q) =>
            (_status == null || (q.belgedurum ?? 0) == _status) &&
            [q.belgeserino, q.cari?.Ad, q.cari?.Kod]
                .any((v) => (v ?? '').toLowerCase().contains(query)))
        .toList()
      ..sort(
          (a, b) => (b.tarih ?? DateTime(0)).compareTo(a.tarih ?? DateTime(0)));
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<String> _token() async =>
      (await SharedPreferences.getInstance()).getString('token_final') ?? '';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _denied = false;
    });
    try {
      final data = await _service.getAll(await _token());
      if (mounted) setState(() => _quotes = data);
    } catch (e) {
      if (!mounted) return;
      if (e is YetkiHatasi) {
        setState(() => _denied = true);
      } else {
        UiFeedback.showException(context, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open([TeklifDto? quote]) async {
    final changed = await Navigator.push<bool>(
        context,
        PermissionMaterialPageRoute(
            builder: (_) =>
                TeklifEntryPage(sales: widget.sales, quoteId: quote?.id)));
    if (changed == true && mounted) await _load();
  }

  Future<void> _action(TeklifDto quote, String action) async {
    if (action == 'open') {
      await _open(quote);
      return;
    }
    final complete = (quote.belgedurum ?? 0) == 0;
    final title = action == 'delete'
        ? 'Teklifi Sil'
        : complete
            ? 'Belgeyi Tamamla'
            : 'Taslağa Çek';
    final approved = await UiFeedback.confirm(context,
        title: title,
        message: action == 'delete'
            ? '${quote.belgeserino ?? 'Teklif'} silinecek. Emin misiniz?'
            : '${quote.belgeserino ?? 'Teklif'} ${complete ? 'tamamlanacak' : 'taslağa alınacak'}.',
        confirmLabel: action == 'delete'
            ? 'Sil'
            : complete
                ? 'Tamamla'
                : 'Taslağa Çek',
        destructive: action == 'delete');
    if (!approved || !mounted) return;
    try {
      final token = await _token();
      if (action == 'delete') {
        await _service.remove(token, quote.id!);
      } else {
        await _service.changeStatus(token, quote.id!, complete);
      }
      if (mounted) await _load();
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    }
  }

  Widget _filterButton() => DocumentFilterButton(
      status: _status,
      onApply: (selection) => setState(() {
            _status = selection.status;
          }));

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final records = _filtered;
    return Scaffold(
      appBar: ErpPageAppBar(
          context: context,
          title: Text('$_kind Teklifleri'),
          actions: [
            IconButton(
                tooltip: 'Yenile',
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded))
          ]),
      body: _denied
          ? const YetkiHatasiWidget()
          : Column(children: [
              Container(
                  color: s.surface,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                          hintText: 'Teklif No veya Cari',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            if (_search.text.isNotEmpty)
                              IconButton(
                                  tooltip: 'Aramayı temizle',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _search.clear();
                                    setState(() {});
                                  }),
                            _filterButton(),
                          ])))),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Expanded(
                        child: Text('${records.length} teklif',
                            style: TextStyle(
                                fontSize: 12, color: s.onSurfaceVariant))),
                    Expanded(
                        child: Text(
                            '${NumberFormatHelper.format(records.fold<double>(0, (sum, q) => sum + (q.geneltoplam ?? 0)))} ₺',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700))),
                  ])),
              Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: records.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                      const SizedBox(height: 80),
                                      Icon(Icons.request_quote_outlined,
                                          size: 48, color: s.outlineVariant),
                                      const SizedBox(height: 12),
                                      Center(
                                          child: Text('Teklif bulunamadı',
                                              style: TextStyle(
                                                  color: s.onSurfaceVariant)))
                                    ])
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 0, 12, 100),
                                  itemCount: records.length,
                                  itemBuilder: (_, i) {
                                    final q = records[i];
                                    return ErpDocumentCard(
                                        number: q.belgeserino ?? '-',
                                        date: q.tarih == null
                                            ? '-'
                                            : DateFormat('dd.MM.yyyy')
                                                .format(q.tarih!),
                                        customer: q.cari?.Ad ?? '-',
                                        customerCode: q.cari?.Kod ?? '',
                                        amount:
                                            '${NumberFormatHelper.format(q.geneltoplam ?? 0)} ₺',
                                        status: BelgeDurumHelper.adById(
                                            q.belgedurum),
                                        statusColor: BelgeDurumHelper.renkById(
                                            q.belgedurum),
                                        icon: Icons.request_quote_outlined,
                                        electronicStatus: (q.oncelik ?? 0) > 0
                                            ? OncelikCouples.adByValue(
                                                q.oncelik)
                                            : null,
                                        onTap: () => _open(q),
                                        action: DocumentListActions(
                                            module: widget.sales ? 601 : 602,
                                            id: q.id ?? '',
                                            number: q.belgeserino ?? 'Teklif',
                                            status: q.belgedurum ?? 0,
                                            electronicStatus: 0,
                                            onStatusChange: (_) =>
                                                _action(q, 'status'),
                                            onRefresh: _load,
                                            onDelete: () =>
                                                _action(q, 'delete'),
                                            onEdit: () async {
                                              if ((q.belgedurum ?? 0) != 0) {
                                                UiFeedback.showWarning(context,
                                                    'Düzenlemek için belgeyi önce taslağa çekin.');
                                                return;
                                              }
                                              await _open(q);
                                            }));
                                  }))),
            ]),
      floatingActionButton: PermissionAction(
          modules: [widget.sales ? 601 : 602],
          access: Access.create,
          child: FloatingActionButton.extended(
              onPressed: _loading || _denied ? null : () => _open(),
              icon: const Icon(Icons.add_rounded),
              label: Text('Yeni $_kind Teklifi'))),
    );
  }
}
