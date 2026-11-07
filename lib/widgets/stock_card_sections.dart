import 'package:flutter/material.dart';
import '../services/stok/stock_card_fields_service.dart';
import '../helpers/ui_feedback.dart';
import 'erp_record_fields.dart';

const stockRowTitles = {
  'Stokfiyat': 'Fiyatlar',
  'Stokolcubr': 'Ek Ölçü Birimleri',
  'Stokbarkod': 'Barkodlar',
  'Stokozellik': 'Stok Özellikleri',
  'Stokalternatif': 'Alternatif Stoklar',
  'Stoksube': 'Şubeler',
};

class StockCardRows extends StatelessWidget {
  final StockRowsController controller;
  final StockCardFieldsService service;
  final bool enabled;
  const StockCardRows(
      {super.key,
      required this.controller,
      required this.service,
      this.enabled = true});

  Future<void> _edit(BuildContext context, String kind, [int? index]) async {
    final rows = controller.rows[kind]!;
    final initial = index == null
        ? <String, dynamic>{
            'Pay': 1,
            'Payda': 1,
            'Sira': rows.fold<int>(
                    0, (n, r) => (r['Sira'] as int? ?? 0) > n ? r['Sira'] : n) +
                1
          }
        : rows[index];
    final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) =>
            _StockRowEditor(kind: kind, initial: initial, service: service));
    if (result == null || !context.mounted) return;
    final uniqueKey = switch (kind) {
      'Stokolcubr' => 'Olcubrid',
      'Stokfiyat' => 'Sira',
      'Stokbarkod' => 'Barkod',
      'Stokozellik' => 'Stokozelliksabitid',
      'Stokalternatif' => 'Alternatifstokid',
      _ => 'Subeid'
    };
    if (rows.indexed.any((entry) =>
        entry.$1 != index && entry.$2[uniqueKey] == result[uniqueKey])) {
      UiFeedback.showError(context, 'Bu kayıt zaten ekli.');
      return;
    }
    controller.put(kind, result, index);
  }

  String _label(String kind, Map<String, dynamic> row) {
    final f = stockRowFields[kind]!.first;
    if (f.type == RecordFieldType.text) return row[f.key]?.toString() ?? '';
    final labels = row['_labels'];
    if (labels is Map && labels[f.key] != null) return labels[f.key];
    final nav = row[f.key.substring(0, f.key.length - 2)];
    if (nav is Map)
      return [nav['Kod'], nav['Ad'] ?? nav['Aciklama'] ?? nav['Birim']]
          .whereType<String>()
          .join(' · ');
    return '${f.label} ${row[f.key] ?? ''}';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: controller,
      builder: (_, __) => Column(children: [
            for (final entry in stockRowTitles.entries)
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                          key: ValueKey('stock-rows-${entry.key}'),
                          maintainState: true,
                          title: Text(
                              '${entry.value} (${controller.rows[entry.key]!.length})',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          children: [
                            for (final row
                                in controller.rows[entry.key]!.indexed)
                              ListTile(
                                  dense: true,
                                  title: Text(_label(entry.key, row.$2),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(entry.key == 'Stokfiyat'
                                      ? 'Alış: ${row.$2['Alisfiyat'] ?? 0} · Satış: ${row.$2['Satisfiyat'] ?? 0}'
                                      : entry.key == 'Stokolcubr'
                                          ? '${row.$2['Pay']} / ${row.$2['Payda']}'
                                          : row.$2['Sira'] == null
                                              ? ''
                                              : 'Sıra: ${row.$2['Sira']}'),
                                  onTap: enabled
                                      ? () => _edit(context, entry.key, row.$1)
                                      : null,
                                  trailing: enabled
                                      ? IconButton(
                                          tooltip: 'Satırı kaldır',
                                          icon: Icon(Icons.delete_outline,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error),
                                          onPressed: () => controller.remove(
                                              entry.key, row.$1))
                                      : null),
                            if (enabled)
                              Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 4, 16, 12),
                                  child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _edit(context, entry.key),
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('Ekle'))),
                          ])))
          ]));
}

class _StockRowEditor extends StatefulWidget {
  final String kind;
  final Map<String, dynamic> initial;
  final StockCardFieldsService service;
  const _StockRowEditor(
      {required this.kind, required this.initial, required this.service});
  @override
  State<_StockRowEditor> createState() => _StockRowEditorState();
}

class _StockRowEditorState extends State<_StockRowEditor> {
  final form = GlobalKey<FormState>();
  late final controller = RecordFieldsController(stockRowFields[widget.kind]!,
      initial: widget.initial)
    ..addListener(_changed);
  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
          child: Form(
              key: form,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(stockRowTitles[widget.kind]!,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 20),
                    ErpRecordFields(
                        controller: controller,
                        lookup: widget.service.choices,
                        prefix: 'stock-row'),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Vazgeç'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: FilledButton(
                              onPressed: () {
                                if (form.currentState!.validate())
                                  Navigator.pop(context, {
                                    ...widget.initial,
                                    ...controller.toJson(),
                                    '_labels': {...controller.labels}
                                  });
                              },
                              child: const Text('Uygula')))
                    ]),
                  ]))));
}
