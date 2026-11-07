import 'document_filter_button.dart';
import 'package:flutter/material.dart';
import 'erp_ui.dart';

class InvoiceDocumentCard extends ErpDocumentCard {
  const InvoiceDocumentCard(
      {super.key,
      required super.number,
      required super.date,
      required super.customer,
      required super.customerCode,
      required super.amount,
      required super.status,
      required super.statusColor,
      required super.icon,
      required super.onTap,
      super.note,
      super.electronicStatus,
      super.onMenu,
      super.action});
}

class InvoiceFilters extends StatelessWidget {
  final int? status, electronic;
  final String electronicLabel;
  final ValueChanged<int?> onStatus, onElectronic;
  const InvoiceFilters(
      {super.key,
      required this.status,
      required this.electronic,
      this.electronicLabel = 'E-Fatura',
      required this.onStatus,
      required this.onElectronic});
  @override
  Widget build(BuildContext context) => DocumentFilterButton(
      status: status,
      electronic: electronic,
      showElectronic: true,
      onApply: (selection) {
        onStatus(selection.status);
        onElectronic(selection.electronic);
      });
}

class InvoiceEntryHeader extends StatelessWidget {
  final TabController controller;
  final int lines;
  const InvoiceEntryHeader(
      {super.key, required this.controller, required this.lines});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final s = Theme.of(context).colorScheme;
        return Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            child: Row(children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
                        child: Material(
                          color: controller.index == i ? s.primary : s.surface,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: controller.index == i
                                      ? s.primary
                                      : s.outlineVariant)),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                              onTap: () => controller.animateTo(i),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 4),
                                  child: Column(children: [
                                    Badge(
                                        isLabelVisible: i == 1 && lines > 0,
                                        label: Text('$lines'),
                                        child: Icon(
                                            [
                                              Icons.person_outline_rounded,
                                              Icons.inventory_2_outlined,
                                              Icons.receipt_long_outlined
                                            ][i],
                                            size: 19,
                                            color: controller.index == i
                                                ? s.onPrimary
                                                : s.onSurfaceVariant)),
                                    const SizedBox(height: 5),
                                    FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                            [
                                              'Üst Bilgiler',
                                              'Kalemler',
                                              'Özet'
                                            ][i],
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: controller.index == i
                                                    ? s.onPrimary
                                                    : s.onSurfaceVariant))),
                                  ]))),
                        ))),
            ]));
      });
}

class InvoiceCustomerSelector extends StatelessWidget {
  final String? name, code;
  final VoidCallback onTap;
  const InvoiceCustomerSelector(
      {super.key, this.name, this.code, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Material(
      color: s.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: s.primary.withValues(alpha: .3))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: s.primary.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.business_outlined,
                        color: s.primary, size: 23)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      if (code?.isNotEmpty == true) ...[
                        Text(code!,
                            style: TextStyle(
                                fontSize: 11, color: s.onSurfaceVariant)),
                        const SizedBox(height: 3)
                      ],
                      Text(name?.isNotEmpty == true ? name! : 'Cari Seç',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: s.onSurface)),
                    ])),
                const SizedBox(width: 8),
                Icon(Icons.expand_more_rounded, color: s.primary, size: 21),
              ]))),
    );
  }
}
