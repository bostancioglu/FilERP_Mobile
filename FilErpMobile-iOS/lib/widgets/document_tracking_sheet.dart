import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/number_format_helper.dart';
import '../helpers/ui_feedback.dart';
import '../models/entities/stok/document_tracking.dart';
import '../services/stok/document_tracking_service.dart';
import '../services/auth/authorization_session.dart';
import 'erp_selector.dart';

class DocumentTrackingButton extends StatelessWidget {
  final TrackingLine line;
  final int? mode;
  const DocumentTrackingButton(
      {super.key, required this.line, required this.mode});
  @override
  Widget build(BuildContext context) {
    if (mode != 1 && mode != 2) return const SizedBox.shrink();
    if (!AuthorizationSession.instance.can(line.document.module, Access.read))
      return const SizedBox.shrink();
    return Tooltip(
        message: line.saved ? 'Seri / Parti Takibi' : 'Önce kalemi kaydedin',
        child: OutlinedButton.icon(
            style:
                OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: const Icon(Icons.qr_code_2_rounded, size: 16),
            label: Text(mode == 2 ? 'Seri Takibi' : 'Parti Takibi'),
            onPressed: !line.saved
                ? null
                : () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => _TrackingSheet(line: line))));
  }
}

class _TrackingSheet extends StatefulWidget {
  final TrackingLine line;
  const _TrackingSheet({required this.line});
  @override
  State<_TrackingSheet> createState() => _TrackingSheetState();
}

class _TrackingSheetState extends State<_TrackingSheet> {
  final service = DocumentTrackingService();
  final quantity = TextEditingController();
  String token = '';
  int branch = 0;
  bool loading = true, busy = false, draft = false;
  String? error;
  TrackingSelection? selection;
  List<TrackingDetail> rows = [];
  TrackingChoice? choice;
  DateTime? expiry;
  bool get serial => selection?.mode == 2;
  bool get editable =>
      draft &&
      AuthorizationSession.instance
          .can(widget.line.document.module, Access.update);
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    quantity.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token_final') ?? '';
      branch = AuthorizationSession.instance.branchId ??
          prefs.getInt('sube_id') ??
          0;
      final currentDraft = await service.isDraft(token, widget.line);
      final saved = await service.details(token, widget.line);
      final options = await service.choices(token, widget.line, branch);
      if (!mounted) return;
      setState(() {
        draft = currentDraft;
        rows = saved;
        selection = options;
        loading = false;
        error = null;
        choice = null;
        expiry = null;
        final remaining = widget.line.quantity -
            rows.fold<double>(0, (s, r) => s + r.quantity);
        quantity.text = NumberFormatHelper.format(
            remaining.clamp(0, double.infinity).toDouble(),
            decimal: 4);
      });
    } catch (e) {
      if (mounted)
        setState(() {
          loading = false;
          error = e.toString();
        });
    }
  }

  Future<void> _select() async {
    final options = (serial ? selection!.serials : selection!.parties)
        .where((c) => !serial || !rows.any((r) => r.serialId == c.id))
        .toList();
    final result = await showErpSelector<TrackingChoice>(
        context: context,
        title: serial ? 'Seri Seç' : 'Parti Seç',
        hintText: serial ? 'Seri No' : 'Parti No',
        items: options,
        itemText: (c) =>
            '${c.label}${c.expiry == null ? '' : ' · ${_date(c.expiry!)}'}${widget.line.incoming ? '' : ' · ${NumberFormatHelper.format(c.balance)}'}');
    if (result != null && mounted)
      setState(() {
        choice = result;
        expiry = result.expiry;
      });
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  Future<void> _mutate(Future<void> Function() action) async {
    if (busy || !editable) return;
    setState(() => busy = true);
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _label(TrackingDetail row) {
    final source =
        row.serialId != null ? selection?.serials : selection?.parties;
    return source
            ?.where((c) => c.id == (row.serialId ?? row.partyId))
            .firstOrNull
            ?.label ??
        '${row.serialId != null ? 'Seri' : 'Parti'} #${row.serialId ?? row.partyId}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .8,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text('Seri / Parti Takibi',
                            style: Theme.of(context).textTheme.titleLarge)),
                    IconButton(
                        tooltip: 'Kapat',
                        onPressed: busy ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded))
                  ]),
                  if (loading)
                    const Expanded(
                        child: Center(child: CircularProgressIndicator()))
                  else if (error != null)
                    Expanded(
                        child: Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                          Text(error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                              onPressed: () {
                                setState(() => loading = true);
                                _load();
                              },
                              child: const Text('Yeniden Dene'))
                        ])))
                  else if (selection?.mode == 0)
                    const Expanded(
                        child: Center(
                            child: Text('Bu stokta seri/parti takibi yok.')))
                  else
                    Expanded(
                        child: ListView(children: [
                      Text(
                          'Seçilen: ${NumberFormatHelper.format(rows.fold<double>(0, (s, r) => s + r.quantity))} / ${NumberFormatHelper.format(widget.line.quantity)}',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      if (editable) ...[
                        OutlinedButton.icon(
                            onPressed: busy ? null : _select,
                            icon: const Icon(Icons.search_rounded, size: 18),
                            label: Text(choice?.label ??
                                (serial ? 'Seri Seç' : 'Parti Seç'))),
                        if (!serial)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: TextField(
                                  controller: quantity,
                                  enabled: !busy,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                      labelText: 'Miktar'))),
                        if (widget.line.incoming)
                          Row(children: [
                            Expanded(
                                child: TextButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () async {
                                            final picked = await showDatePicker(
                                                context: context,
                                                initialDate:
                                                    expiry ?? DateTime.now(),
                                                firstDate: DateTime(2000),
                                                lastDate: DateTime(2100));
                                            if (picked != null && mounted)
                                              setState(() => expiry = picked);
                                          },
                                    icon: const Icon(Icons.event_outlined,
                                        size: 18),
                                    label: Text(expiry == null
                                        ? 'Son Kullanma Tarihi'
                                        : _date(expiry!)))),
                            if (expiry != null)
                              IconButton(
                                  tooltip: 'Tarihi temizle',
                                  onPressed: busy
                                      ? null
                                      : () => setState(() => expiry = null),
                                  icon:
                                      const Icon(Icons.close_rounded, size: 18))
                          ]),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                            onPressed: busy || choice == null
                                ? null
                                : () => _mutate(() => service.add(
                                    token, widget.line,
                                    choice: choice!,
                                    serial: serial,
                                    quantity: serial
                                        ? 1
                                        : NumberFormatHelper.parse(
                                            quantity.text),
                                    expiry: expiry)),
                            icon: busy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Ekle')),
                      ],
                      const SizedBox(height: 12),
                      rows.isEmpty
                          ? const Center(child: Text('Kayıt yok'))
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: rows.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final row = rows[i];
                                return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(_label(row)),
                                    subtitle: row.expiry == null
                                        ? null
                                        : Text(_date(row.expiry!)),
                                    trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(NumberFormatHelper.format(
                                              row.quantity)),
                                          if (editable && row.status == 1)
                                            IconButton(
                                                tooltip: 'Takibi kaldır',
                                                icon: Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    color: scheme.error),
                                                onPressed: busy
                                                    ? null
                                                    : () async {
                                                        final confirmed =
                                                            await UiFeedback.confirm(
                                                                context,
                                                                title:
                                                                    'Takibi Kaldır',
                                                                message:
                                                                    '${_label(row)} kaldırılsın mı?',
                                                                destructive:
                                                                    true);
                                                        if (confirmed == true &&
                                                            mounted)
                                                          await _mutate(() =>
                                                              service.remove(
                                                                  token,
                                                                  widget.line,
                                                                  row));
                                                      })
                                        ]));
                              }),
                    ])),
                ])));
  }
}
