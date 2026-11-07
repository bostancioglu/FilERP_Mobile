import 'package:flutter/material.dart';
import '../models/entities/stok/stok_dto.dart';

class WarehouseFeatureField extends StatelessWidget {
  final StokDto? stock;
  final int? value;
  final ValueChanged<int?> onChanged;
  const WarehouseFeatureField(
      {super.key,
      required this.stock,
      required this.value,
      required this.onChanged});
  @override
  Widget build(BuildContext context) {
    if (stock?.Stokozelligesahip != true && value == null)
      return const SizedBox.shrink();
    final choices = <int, String>{
      for (final f in stock?.Stokozellik ?? [])
        if (f.stokozelliksabitid != null) f.stokozelliksabitid!: f.displayAd
    };
    if (value != null && !choices.containsKey(value))
      choices[value!] = 'Özellik $value';
    return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: DropdownButtonFormField<int>(
            key: ValueKey('warehouse-feature-${stock?.Id}-$value'),
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Stok Özelliği'),
            items: choices.entries
                .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: onChanged));
  }
}
