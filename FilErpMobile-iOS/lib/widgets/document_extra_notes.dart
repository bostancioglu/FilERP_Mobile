import 'package:flutter/material.dart';

/// Additional document notes stay collapsed until the user needs them.
class DocumentExtraNotesButton extends StatelessWidget {
  final List<String?> values;
  final ValueChanged<List<String?>> onChanged;
  const DocumentExtraNotesButton(
      {super.key, required this.values, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final count = values.where((v) => v?.trim().isNotEmpty ?? false).length;
    return OutlinedButton.icon(
        icon: const Icon(Icons.notes_rounded, size: 18),
        label: Text('Ek Açıklamalar${count == 0 ? '' : ' ($count)'}'),
        onPressed: () async {
          final result = await showModalBottomSheet<List<String?>>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => _NotesSheet(values: values));
          if (result != null && context.mounted) onChanged(result);
        });
  }
}

class _NotesSheet extends StatefulWidget {
  final List<String?> values;
  const _NotesSheet({required this.values});
  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  late final controllers = List.generate(
      20,
      (i) => TextEditingController(
          text: i < widget.values.length ? widget.values[i] : null));
  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Ek Açıklamalar',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
                child: ListView.separated(
                    itemCount: 20,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => TextFormField(
                        controller: controllers[i],
                        decoration:
                            InputDecoration(labelText: 'Açıklama ${i + 1}'),
                        maxLines: 2))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Vazgeç'))),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                      onPressed: () => Navigator.pop(
                          context,
                          controllers
                              .map((c) =>
                                  c.text.trim().isEmpty ? null : c.text.trim())
                              .toList()),
                      child: const Text('Uygula'))),
            ]),
          ])));
}
