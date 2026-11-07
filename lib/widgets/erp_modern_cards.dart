import 'package:flutter/material.dart';

class ErpModernRecordCard extends StatelessWidget {
  final String title, code;
  final IconData icon;
  final List<String> details;
  final VoidCallback onTap;
  const ErpModernRecordCard(
      {super.key,
      required this.title,
      required this.code,
      required this.icon,
      required this.details,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: s.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: s.outlineVariant.withValues(alpha: .7))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: s.primary.withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(icon, color: s.primary, size: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              if (code.isNotEmpty) ...[
                                Text(code,
                                    style: TextStyle(
                                        color: s.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 5)
                              ],
                              Text(title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: s.onSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                              if (details.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(spacing: 6, runSpacing: 6, children: [
                                  for (final detail in details)
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                            color: s.surfaceContainerLow,
                                            borderRadius:
                                                BorderRadius.circular(7)),
                                        child: Text(detail,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: s.onSurfaceVariant))),
                                ])
                              ],
                            ])),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            color: s.primary, size: 18),
                      ]))),
        ));
  }
}

class ErpModernFinanceCard extends StatelessWidget {
  final String title;
  final List<String> metadata;
  final IconData icon;
  final String? amount, secondaryAmount;
  final Color? amountColor;
  final VoidCallback? onTap, onDelete;
  const ErpModernFinanceCard(
      {super.key,
      required this.title,
      required this.metadata,
      required this.icon,
      this.amount,
      this.secondaryAmount,
      this.amountColor,
      this.onTap,
      this.onDelete});
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: s.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: s.outlineVariant.withValues(alpha: .7))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: s.primary.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(icon, color: s.primary, size: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: s.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700))),
                          if (onDelete != null)
                            PopupMenuButton<String>(
                                tooltip: 'İşlemler',
                                icon: const Icon(Icons.more_horiz_rounded,
                                    size: 20),
                                onSelected: (_) => onDelete!(),
                                itemBuilder: (_) => [
                                      PopupMenuItem(
                                          value: 'delete',
                                          child: Row(children: [
                                            Icon(Icons.delete_outline_rounded,
                                                color: s.error, size: 19),
                                            const SizedBox(width: 8),
                                            const Text('Sil')
                                          ])),
                                    ])
                          else if (onTap != null)
                            Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.chevron_right_rounded,
                                    color: s.onSurfaceVariant, size: 20)),
                        ]),
                        if (metadata.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(spacing: 6, runSpacing: 6, children: [
                            for (final detail in metadata)
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: s.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text(detail,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: s.onSurfaceVariant))),
                          ])
                        ],
                        if (amount != null || secondaryAmount != null) ...[
                          const SizedBox(height: 10),
                          Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (amount != null)
                                      FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(amount!,
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  color: amountColor ??
                                                      s.onSurface,
                                                  fontSize: 19,
                                                  letterSpacing: -.3,
                                                  fontWeight:
                                                      FontWeight.w800))),
                                    if (secondaryAmount != null)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(secondaryAmount!,
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  color: s.onSurfaceVariant,
                                                  fontSize: 11))),
                                  ]))
                        ],
                      ]))),
        ));
  }
}

class ErpModernDocumentCard extends StatelessWidget {
  final String number, date, customer, customerCode, amount, status;
  final String? note, electronicStatus;
  final Color statusColor;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;
  final Widget? action;
  const ErpModernDocumentCard(
      {super.key,
      required this.number,
      required this.date,
      required this.customer,
      required this.customerCode,
      required this.amount,
      required this.status,
      required this.statusColor,
      required this.icon,
      required this.onTap,
      this.note,
      this.electronicStatus,
      this.onMenu,
      this.action});
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: s.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: s.outlineVariant.withValues(alpha: .7))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              onLongPress: onMenu,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: s.primary.withValues(alpha: .09),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(icon, color: s.primary, size: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(number,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: s.onSurface)),
                              const SizedBox(height: 3),
                              Text(date,
                                  style: TextStyle(
                                      fontSize: 11, color: s.onSurfaceVariant)),
                            ])),
                        const SizedBox(width: 6),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(7)),
                            child: Text(status,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? HSLColor.fromColor(statusColor)
                                            .withLightness(.76)
                                            .toColor()
                                        : statusColor))),
                        SizedBox(
                            width: 36,
                            height: 36,
                            child: action ??
                                (onMenu != null
                                    ? IconButton(
                                        tooltip: 'Belge işlemleri',
                                        onPressed: onMenu,
                                        icon: const Icon(
                                            Icons.more_horiz_rounded,
                                            size: 20))
                                    : Icon(Icons.chevron_right_rounded,
                                        color: s.onSurfaceVariant, size: 19))),
                      ]),
                      const SizedBox(height: 11),
                      Text(customer,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: s.onSurface)),
                      const SizedBox(height: 9),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  if (customerCode.isNotEmpty)
                                    Text(customerCode,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: s.onSurfaceVariant)),
                                  if (electronicStatus?.isNotEmpty == true)
                                    Text(electronicStatus!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 10, color: s.primary)),
                                ])),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Align(
                                    alignment: Alignment.centerRight,
                                    child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(amount,
                                            style: TextStyle(
                                                fontSize: 19,
                                                letterSpacing: -.5,
                                                fontWeight: FontWeight.w800,
                                                color: s.onSurface))))),
                          ]),
                      if (note?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: s.onSurfaceVariant))
                      ],
                    ]),
              )),
        ));
  }
}
