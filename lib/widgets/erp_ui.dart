import 'erp_page_style.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'erp_modern_cards.dart';

/// Common visual language for lists, without coupling them to API models.
class ErpListOverview extends StatelessWidget {
  final String count;
  const ErpListOverview({super.key, required this.count});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
        child: Row(children: [
          Icon(Icons.list_alt_rounded,
              size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 7),
          Expanded(
              child: Text(count,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500))),
        ]),
      );
}

class ErpRecordCard extends StatelessWidget {
  final String title, code;
  final IconData icon;
  final List<String> details;
  final VoidCallback onTap;
  const ErpRecordCard(
      {super.key,
      required this.title,
      required this.code,
      required this.icon,
      required this.details,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    if (ErpDesignStyle.modern(context))
      return ErpModernRecordCard(
          title: title, code: code, icon: icon, details: details, onTap: onTap);
    final s = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: s.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: s.outlineVariant.withValues(alpha: .45))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: s.primary.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(13)),
                            child: Icon(icon, color: s.primary, size: 23)),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: s.onSurface,
                                      fontSize: 16,
                                      height: 1.3,
                                      fontWeight: FontWeight.w600)),
                              if (code.isNotEmpty) ...[
                                const SizedBox(height: 7),
                                Text(code,
                                    style: TextStyle(
                                        color: s.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600))
                              ],
                              if (details.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: details
                                        .map((d) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 9, vertical: 5),
                                            decoration: BoxDecoration(
                                                color: s.surfaceContainerLow,
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            child: Text(d,
                                                style: TextStyle(
                                                    color: s.onSurfaceVariant,
                                                    fontSize: 12))))
                                        .toList())
                              ],
                            ])),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded,
                            color: s.onSurfaceVariant, size: 20),
                      ]))),
        ));
  }
}

class ErpDocumentCard extends StatelessWidget {
  final String number, date, customer, customerCode, amount, status;
  final String? note, electronicStatus;
  final Color statusColor;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;
  final Widget? action;
  const ErpDocumentCard(
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
    if (ErpDesignStyle.modern(context))
      return ErpModernDocumentCard(
          number: number,
          date: date,
          customer: customer,
          customerCode: customerCode,
          amount: amount,
          status: status,
          statusColor: statusColor,
          icon: icon,
          onTap: onTap,
          onMenu: onMenu,
          action: action,
          note: note,
          electronicStatus: electronicStatus);
    final s = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: s.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: s.outlineVariant.withValues(alpha: .45))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              onLongPress: onMenu,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(icon, size: 16, color: s.primary),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(number,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: s.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500))),
                        const SizedBox(width: 8),
                        Text(date,
                            style: TextStyle(
                                color: s.onSurfaceVariant, fontSize: 11)),
                        if (action != null)
                          action!
                        else if (onMenu != null)
                          IconButton(
                              tooltip: 'Belge işlemleri',
                              onPressed: onMenu,
                              icon: const Icon(Icons.more_horiz_rounded,
                                  size: 20))
                        else
                          const SizedBox(height: 40),
                      ]),
                      Text(customer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: s.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                                flex: 5,
                                child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      InkWell(
                                          onTap: onMenu,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                              child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration:
                                                            BoxDecoration(
                                                                color:
                                                                    statusColor,
                                                                shape: BoxShape
                                                                    .circle)),
                                                    const SizedBox(width: 5),
                                                    Flexible(
                                                        child: Text(status,
                                                            style: TextStyle(
                                                                color:
                                                                    statusColor,
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600))),
                                                  ]))),
                                      if (electronicStatus?.isNotEmpty == true)
                                        Text(electronicStatus!,
                                            style: TextStyle(
                                                color: s.onSurfaceVariant,
                                                fontSize: 11)),
                                    ])),
                            const SizedBox(width: 10),
                            Flexible(
                                flex: 4,
                                child: Align(
                                    alignment: Alignment.centerRight,
                                    child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(amount,
                                            style: TextStyle(
                                                color: s.onSurface,
                                                fontSize: 18,
                                                fontWeight:
                                                    FontWeight.w700))))),
                          ]),
                    ]),
              )),
        ));
  }
}

class ErpEntryActions extends StatelessWidget {
  final VoidCallback onAdd, onBarcode, onCamera, onManual;
  const ErpEntryActions(
      {super.key,
      required this.onAdd,
      required this.onBarcode,
      required this.onCamera,
      required this.onManual});
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final actions = [
      (Icons.add_shopping_cart_outlined, 'Kalem ekle', onAdd),
      (Icons.barcode_reader, 'Barkod', onBarcode),
      (Icons.qr_code_scanner_rounded, 'Kamera', onCamera),
      (Icons.keyboard_alt_outlined, 'Elle giriş', onManual)
    ];
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < actions.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
            child: Material(
                color: s.primary.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                    onTap: actions[i].$3,
                    borderRadius: BorderRadius.circular(13),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 2),
                        child: Column(children: [
                          Icon(actions[i].$1, color: s.primary, size: 23),
                          const SizedBox(height: 7),
                          Text(actions[i].$2,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: s.onSurface,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600))
                        ]))))),
      ]
    ]);
  }
}

class ErpDetailHeader extends StatelessWidget {
  final String pageTitle, title, code;
  final IconData icon;
  final List<Widget> actions;
  const ErpDetailHeader(
      {super.key,
      required this.pageTitle,
      required this.title,
      required this.code,
      required this.icon,
      this.actions = const []});
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return ErpPageSliverAppBar(
      context: context,
      pinned: true,
      expandedHeight: 176,
      toolbarHeight: 56,
      backgroundColor: s.surface,
      foregroundColor: s.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text(pageTitle,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
          background: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: s.primary.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(13)),
                    child: Icon(icon, color: s.primary, size: 24)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: s.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.3)),
                      if (code.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: s.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600))
                      ],
                    ])),
              ]),
            )),
      )),
    );
  }
}

/// Account balances and money movements share a compact, currency-explicit card.
class ErpFinanceCard extends StatelessWidget {
  final String title;
  final List<String> metadata;
  final IconData icon;
  final String? amount, secondaryAmount;
  final Color? amountColor;
  final VoidCallback? onTap, onDelete;
  const ErpFinanceCard(
      {super.key,
      required this.title,
      required this.icon,
      required this.metadata,
      this.amount,
      this.secondaryAmount,
      this.amountColor,
      this.onTap,
      this.onDelete});
  @override
  Widget build(BuildContext context) {
    if (ErpDesignStyle.modern(context))
      return ErpModernFinanceCard(
          title: title,
          metadata: metadata,
          icon: icon,
          amount: amount,
          secondaryAmount: secondaryAmount,
          amountColor: amountColor,
          onTap: onTap,
          onDelete: onDelete);
    final s = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: s.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: s.outlineVariant.withValues(alpha: .45))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: s.primary.withValues(alpha: .07),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(icon, color: s.primary, size: 19)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: s.onSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      height: 1.25))),
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
                                    ]))
                              ],
                            )
                          else
                            const SizedBox(width: 8),
                        ]),
                        const SizedBox(height: 8),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                  flex: 5,
                                  child: Wrap(
                                      spacing: 7,
                                      runSpacing: 4,
                                      children: metadata
                                          .where((v) => v.isNotEmpty)
                                          .map((v) => Text(v,
                                              style: TextStyle(
                                                  color: s.onSurfaceVariant,
                                                  fontSize: 12,
                                                  height: 1.4)))
                                          .toList())),
                              if (amount != null ||
                                  secondaryAmount != null) ...[
                                const SizedBox(width: 10),
                                Flexible(
                                    flex: 5,
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          if (amount != null)
                                            Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(amount!,
                                                        style: TextStyle(
                                                            color:
                                                                amountColor ??
                                                                    s.onSurface,
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700)))),
                                          if (secondaryAmount != null) ...[
                                            const SizedBox(height: 4),
                                            Text(secondaryAmount!,
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                    color: s.onSurfaceVariant,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w500))
                                          ],
                                        ])),
                              ] else
                                Icon(Icons.chevron_right_rounded,
                                    color: s.onSurfaceVariant, size: 19),
                            ]),
                      ]))),
        ));
  }
}

class ErpSwipeDelete extends StatelessWidget {
  final Widget child;
  final Future<void> Function()? onDelete;
  const ErpSwipeDelete(
      {super.key, required this.child, required this.onDelete});
  @override
  Widget build(BuildContext context) => Dismissible(
        key: key ?? ValueKey(child),
        direction: onDelete == null
            ? DismissDirection.none
            : DismissDirection.endToStart,
        confirmDismiss: (_) async {
          if (onDelete != null) await onDelete!();
          return false;
        },
        background: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.only(right: 18),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.onError)),
        child: child,
      );
}
