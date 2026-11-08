import 'package:flutter/material.dart';

class DocumentFilterSelection {
  final int? status, electronic;
  const DocumentFilterSelection({this.status, this.electronic});
}

/// List filters live in the search field, leaving the list's height to records.
class DocumentFilterButton extends StatelessWidget {
  final int? status, electronic;
  final bool showElectronic;
  final ValueChanged<DocumentFilterSelection> onApply;
  const DocumentFilterButton(
      {super.key,
      required this.status,
      this.electronic,
      this.showElectronic = false,
      required this.onApply});

  @override
  Widget build(BuildContext context) {
    final count = (status == null ? 0 : 1) +
        (showElectronic && electronic != null ? 1 : 0);
    return Padding(
        padding: const EdgeInsets.all(4),
        child: IconButton.filledTonal(
            tooltip: 'Filtreler',
            icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(Icons.tune_rounded, size: 21)),
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              final selection =
                  await showModalBottomSheet<DocumentFilterSelection>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      showDragHandle: false,
                      shape:
                          const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24))),
                      builder: (_) => _DocumentFilterSheet(
                          status: status,
                          electronic: electronic,
                          showElectronic: showElectronic));
              if (selection != null && context.mounted) onApply(selection);
            }));
  }
}

class _DocumentFilterSheet extends StatefulWidget {
  final int? status, electronic;
  final bool showElectronic;
  const _DocumentFilterSheet(
      {required this.status,
      required this.electronic,
      required this.showElectronic});
  @override
  State<_DocumentFilterSheet> createState() => _DocumentFilterSheetState();
}

class _DocumentFilterSheetState extends State<_DocumentFilterSheet> {
  late int? _status = widget.status;
  late int? _electronic = widget.electronic;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    Widget section(
            String id,
            String title,
            Map<int?, (String, IconData)> options,
            int? selected,
            ValueChanged<int?> select) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: s.onSurface)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            for (final option in options.entries)
              ChoiceChip(
                  key: ValueKey('filter-$id-${option.key ?? 'all'}'),
                  label: Text(option.value.$1),
                  avatar: Icon(option.value.$2, size: 18),
                  selected: selected == option.key,
                  onSelected: (_) => select(option.key)),
          ]),
        ]);
    return SafeArea(
        top: false,
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .85),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                      child: Row(children: [
                        Icon(Icons.tune_rounded, color: s.primary),
                        const SizedBox(width: 10),
                        const Expanded(
                            child: Text('Filtreler',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800))),
                        IconButton(
                            tooltip: 'Filtreleri kapat',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded)),
                      ])),
                  Flexible(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                section(
                                    'status',
                                    'Belge Durumu',
                                    const {
                                      null: ('Tümü', Icons.all_inbox_outlined),
                                      0: ('Taslak', Icons.edit_note_rounded),
                                      1: ('Tamamlandı', Icons.task_alt_rounded),
                                    },
                                    _status,
                                    (value) => setState(() => _status = value)),
                                if (widget.showElectronic) ...[
                                  const SizedBox(height: 24),
                                  section(
                                      'electronic',
                                      'Gönderim Durumu',
                                      const {
                                        null: (
                                          'Tümü',
                                          Icons.all_inbox_outlined
                                        ),
                                        3: ('E-Belge', Icons.verified_outlined),
                                        1: (
                                          'Portal',
                                          Icons.cloud_upload_outlined
                                        ),
                                        -2: ('ERP', Icons.inventory_2_outlined),
                                      },
                                      _electronic,
                                      (value) =>
                                          setState(() => _electronic = value)),
                                ],
                              ]))),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton.icon(
                                onPressed: () => Navigator.pop(
                                    context,
                                    DocumentFilterSelection(
                                        status: _status,
                                        electronic: _electronic)),
                                style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48)),
                                icon: const Icon(Icons.check_rounded, size: 19),
                                label: const Text('Uygula')),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                                onPressed: () => setState(() {
                                      _status = null;
                                      _electronic = null;
                                    }),
                                style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(44),
                                    foregroundColor: s.onSurfaceVariant,
                                    side: BorderSide(color: s.outlineVariant)),
                                icon: const Icon(Icons.filter_alt_off_outlined,
                                    size: 19),
                                label: const Text('Sıfırla')),
                          ])),
                ])));
  }
}
