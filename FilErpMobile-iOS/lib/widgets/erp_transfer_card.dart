import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErpTransferCard extends StatelessWidget {
  final String number, date, source, target, status;
  final Color statusColor;
  final int itemCount;
  final bool offline;
  final VoidCallback onTap, onMenu;
  const ErpTransferCard(
      {super.key,
      required this.number,
      required this.date,
      required this.source,
      required this.target,
      required this.status,
      required this.statusColor,
      required this.onTap,
      required this.onMenu,
      this.itemCount = 0,
      this.offline = false});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: s.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  ErpDesignStyle.modern(context) ? 18 : 14),
              side: BorderSide(
                  color: offline
                      ? statusColor.withValues(alpha: .5)
                      : s.outlineVariant.withValues(
                          alpha: ErpDesignStyle.modern(context) ? .7 : .45))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              onLongPress: onMenu,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 8, 12),
                  child: Column(children: [
                    Row(children: [
                      Icon(
                          offline
                              ? Icons.cloud_off_outlined
                              : Icons.swap_horiz_rounded,
                          size: 19,
                          color: offline ? statusColor : s.primary),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(number,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, color: s.onSurfaceVariant))),
                      const SizedBox(width: 8),
                      Text(date,
                          style: TextStyle(
                              fontSize: 11, color: s.onSurfaceVariant)),
                      IconButton(
                          tooltip: 'Transfer işlemleri',
                          onPressed: onMenu,
                          icon: const Icon(Icons.more_horiz_rounded, size: 20)),
                    ]),
                    Row(children: [
                      Expanded(child: _node(context, 'Çıkış', source)),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 18, color: s.primary)),
                      Expanded(child: _node(context, 'Giriş', target)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Expanded(
                          child: Text(status,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor))),
                      if (itemCount > 0)
                        Text('$itemCount kalem',
                            style: TextStyle(
                                fontSize: 12, color: s.onSurfaceVariant)),
                      const SizedBox(width: 4),
                    ]),
                  ]))),
        ));
  }

  Widget _node(BuildContext context, String label, String name) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 3),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ]);
}
