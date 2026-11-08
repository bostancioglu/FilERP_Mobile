import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entities/helper/istisna_dto.dart';
import '../models/entities/olcubirimi/olcubr_dto.dart';
import '../services/helper/istisna_service.dart';
import '../services/helper/olcubr_service.dart';
import '../helpers/ui_feedback.dart';
import 'erp_selector.dart';

class DocumentLineExtras extends StatelessWidget {
  final int? exemptionId, packageUnitId;
  final IstisnaDto? exemption;
  final OlcubrDto? packageUnit;
  final ValueChanged<IstisnaDto?> onExemption;
  final ValueChanged<OlcubrDto?> onPackageUnit;
  final String? stockDescription;
  final ValueChanged<String>? onStockDescription;
  const DocumentLineExtras(
      {super.key,
      this.exemptionId,
      this.packageUnitId,
      this.exemption,
      this.packageUnit,
      required this.onExemption,
      required this.onPackageUnit,
      this.stockDescription,
      this.onStockDescription});

  @override
  Widget build(BuildContext context) {
    Widget field(String label, String value, Future<void> Function() select,
            VoidCallback? clear) =>
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
                key: ValueKey('document-line-$label'),
                onTap: select,
                child: InputDecorator(
                    decoration: InputDecoration(
                        labelText: label,
                        suffixIcon: clear == null
                            ? const Icon(Icons.expand_more_rounded)
                            : IconButton(
                                tooltip: '$label temizle',
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: clear)),
                    child: Text(value,
                        maxLines: 2, overflow: TextOverflow.ellipsis))));
    return ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: const Text('Vergi ve Ambalaj',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        children: [
          field(
              'İstisna',
              exemption == null
                  ? (exemptionId == null ? '' : '#$exemptionId')
                  : '${exemption!.kod ?? ''} · ${exemption!.aciklama ?? ''}',
              () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              final rows = await IstisnaService()
                  .getAll(prefs.getString('token_final') ?? '');
              if (!context.mounted) return;
              final selected = await showErpSelector<IstisnaDto>(
                  context: context,
                  hintText: 'İstisna',
                  title: 'İstisna',
                  items: rows,
                  itemText: (e) => '${e.kod ?? ''} · ${e.aciklama ?? ''}');
              if (selected != null && context.mounted) onExemption(selected);
            } catch (error) {
              if (context.mounted) UiFeedback.showException(context, error);
            }
          }, exemptionId == null ? null : () => onExemption(null)),
          field(
              'Ambalaj Ölçü Birimi',
              packageUnit?.Kod ??
                  packageUnit?.Ad ??
                  (packageUnitId == null ? '' : '#$packageUnitId'), () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              final rows = await OlcubrService()
                  .getAll(prefs.getString('token_final') ?? '');
              if (!context.mounted) return;
              final selected = await showErpSelector<OlcubrDto>(
                  context: context,
                  hintText: 'Ambalaj Ölçü Birimi',
                  title: 'Ambalaj Ölçü Birimi',
                  items: rows,
                  itemText: (e) => '${e.Kod ?? ''} · ${e.Ad ?? ''}');
              if (selected != null && context.mounted) onPackageUnit(selected);
            } catch (error) {
              if (context.mounted) UiFeedback.showException(context, error);
            }
          }, packageUnitId == null ? null : () => onPackageUnit(null)),
          if (onStockDescription != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                    initialValue: stockDescription,
                    decoration:
                        const InputDecoration(labelText: 'Stok Adı Açıklama'),
                    maxLines: 2,
                    onChanged: onStockDescription)),
        ]);
  }
}
