import 'package:flutter/material.dart';
import '../helpers/number_format_helper.dart';
import '../helpers/ui_feedback.dart';
import 'erp_selector.dart';

enum RecordFieldType { text, number, integer, flag, lookup, choice, date }

class RecordField {
  final String key, label;
  final RecordFieldType type;
  final String? lookup;
  final Map<int, String>? options;
  final bool required;
  final double? minimum;
  const RecordField(this.key, this.label, this.type,
      {this.lookup, this.options, this.required = false, this.minimum});
}

class RecordChoice {
  final int id;
  final String label;
  const RecordChoice(this.id, this.label);
}

class RecordFieldsController extends ChangeNotifier {
  final List<RecordField> fields;
  final Map<String, TextEditingController> text = {};
  final Map<String, dynamic> values = {};
  final Map<String, String> labels = {};
  RecordFieldsController(this.fields,
      {Map<String, dynamic> initial = const {}}) {
    for (final f in fields) {
      final v = initial[f.key];
      if ([
        RecordFieldType.text,
        RecordFieldType.number,
        RecordFieldType.integer
      ].contains(f.type)) {
        text[f.key] = TextEditingController(
            text: v == null
                ? ''
                : f.type == RecordFieldType.number && v is num
                    ? v.toString().replaceAll('.', ',')
                    : v.toString());
      } else {
        values[f.key] = v ?? (f.type == RecordFieldType.flag ? false : null);
      }
      if (initial['_labels'] is Map)
        labels.addAll(Map<String, String>.from(initial['_labels']));
      if (f.type == RecordFieldType.lookup) {
        final nav =
            f.key.endsWith('id') ? f.key.substring(0, f.key.length - 2) : f.key;
        final row = initial[nav];
        if (row is Map)
          labels[f.key] = [
            row['Kod'],
            row['Ad'] ?? row['Aciklama'] ?? row['Adsoyad']
          ].whereType<String>().join(' · ');
      }
    }
  }
  void choose(String key, int? id, String? label) {
    values[key] = id;
    if (label == null) {
      labels.remove(key);
    } else {
      labels[key] = label;
    }
    notifyListeners();
  }

  void setValue(String key, dynamic value) {
    values[key] = value;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        for (final f in fields)
          f.key: text.containsKey(f.key)
              ? text[f.key]!.text.trim().isEmpty
                  ? null
                  : f.type == RecordFieldType.integer
                      ? int.tryParse(text[f.key]!.text)
                      : f.type == RecordFieldType.number
                          ? NumberFormatHelper.parse(text[f.key]!.text)
                          : text[f.key]!.text.trim()
              : values[f.key]
      };
  @override
  void dispose() {
    for (final c in text.values) {
      c.dispose();
    }
    super.dispose();
  }
}

class ErpRecordFields extends StatelessWidget {
  final RecordFieldsController controller;
  final List<RecordField>? fields;
  final Future<List<RecordChoice>> Function(String) lookup;
  final String prefix;
  final bool enabled;
  const ErpRecordFields(
      {super.key,
      required this.controller,
      required this.lookup,
      this.fields,
      this.prefix = 'record',
      this.enabled = true});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final f in fields ?? controller.fields)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _field(context, f))
      ]);
  Widget _field(BuildContext context, RecordField f) {
    final key = ValueKey('$prefix-${f.key}');
    final decoration = InputDecoration(labelText: f.label);
    if (controller.text.containsKey(f.key))
      return TextFormField(
          key: key,
          controller: controller.text[f.key],
          enabled: enabled,
          keyboardType: f.type == RecordFieldType.integer
              ? TextInputType.number
              : f.type == RecordFieldType.number
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
          decoration: decoration,
          validator: (v) {
            if (v == null || v.trim().isEmpty)
              return f.required ? 'Zorunlu alan' : null;
            if (f.type == RecordFieldType.integer && int.tryParse(v) == null)
              return 'Tam sayı giriniz';
            if (f.type == RecordFieldType.number) {
              final parsed =
                  double.tryParse(v.replaceAll('.', '').replaceAll(',', '.'));
              if (parsed == null || !parsed.isFinite)
                return 'Geçerli bir sayı giriniz';
            }
            if (f.minimum != null && NumberFormatHelper.parse(v) < f.minimum!)
              return 'En az ${f.minimum} olmalı';
            return null;
          });
    if (f.type == RecordFieldType.flag)
      return SwitchListTile.adaptive(
          key: key,
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(f.label, style: const TextStyle(fontSize: 13)),
          value: controller.values[f.key] == true,
          onChanged: enabled ? (v) => controller.setValue(f.key, v) : null);
    if (f.type == RecordFieldType.choice)
      return DropdownButtonFormField<int>(
          key: key,
          isExpanded: true,
          initialValue: f.options!.containsKey(controller.values[f.key])
              ? controller.values[f.key]
              : null,
          decoration: decoration,
          items: [
            if (!f.required)
              const DropdownMenuItem<int>(
                  value: null, child: Text('Seçilmedi')),
            ...f.options!.entries.map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value, overflow: TextOverflow.ellipsis)))
          ],
          validator: (v) => f.required && v == null ? 'Zorunlu alan' : null,
          onChanged: enabled ? (v) => controller.choose(f.key, v, null) : null);
    if (f.type == RecordFieldType.date) {
      final date =
          DateTime.tryParse(controller.values[f.key]?.toString() ?? '');
      return InkWell(
          key: key,
          onTap: !enabled
              ? null
              : () async {
                  final picked = await showDatePicker(
                      context: context,
                      initialDate: date ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100));
                  if (picked != null && context.mounted) {
                    controller.setValue(f.key, picked.toIso8601String());
                  }
                },
          child: InputDecorator(
              decoration: decoration.copyWith(
                  suffixIcon: date == null
                      ? const Icon(Icons.event_outlined)
                      : IconButton(
                          tooltip: '${f.label} temizle',
                          onPressed: enabled
                              ? () => controller.setValue(f.key, null)
                              : null,
                          icon: const Icon(Icons.close_rounded, size: 18))),
              child: Text(date == null
                  ? ''
                  : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}')));
    }
    return FormField<int>(
        key: key,
        initialValue: controller.values[f.key],
        validator: (_) => f.required && controller.values[f.key] == null
            ? 'Zorunlu alan'
            : null,
        builder: (state) => InkWell(
            onTap: !enabled
                ? null
                : () async {
                    try {
                      final rows = await lookup(f.lookup!);
                      if (!context.mounted) return;
                      final selected = await showErpSelector<RecordChoice>(
                          context: context,
                          title: f.label,
                          hintText: f.label,
                          items: rows,
                          itemText: (r) => r.label);
                      if (selected != null && context.mounted) {
                        controller.choose(f.key, selected.id, selected.label);
                        state.didChange(selected.id);
                      }
                    } catch (e) {
                      if (context.mounted) UiFeedback.showException(context, e);
                    }
                  },
            child: InputDecorator(
                decoration: decoration.copyWith(
                    errorText: state.errorText,
                    suffixIcon: controller.values[f.key] == null
                        ? const Icon(Icons.expand_more_rounded)
                        : IconButton(
                            tooltip: '${f.label} temizle',
                            onPressed: enabled
                                ? () {
                                    controller.choose(f.key, null, null);
                                    state.didChange(null);
                                  }
                                : null,
                            icon: const Icon(Icons.close_rounded, size: 18))),
                child: Text(
                    controller.values[f.key] == null
                        ? ''
                        : controller.labels[f.key] ?? '${f.label} seçili',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis))));
  }
}
