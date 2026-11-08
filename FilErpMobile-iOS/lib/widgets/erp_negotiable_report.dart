import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared compact presentation for cheque and promissory note reports.
class ErpNegotiableReportCard extends StatelessWidget {
  final String customer, number, dueDate, amount;
  final String? status, location, secondaryAmount, bank, originalDebtor, batch;

  const ErpNegotiableReportCard({
    super.key,
    required this.customer,
    required this.number,
    required this.dueDate,
    required this.amount,
    this.status,
    this.location,
    this.secondaryAmount,
    this.bank,
    this.originalDebtor,
    this.batch,
  });

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final details = <String, String?>{
      'Belge No': number,
      'Cari': customer,
      'Vade': dueDate,
      'Durum': status,
      'Evrak Yeri': location,
      'Banka': bank,
      'Asıl Borçlu': originalDebtor,
      'Bordro No': batch,
      'Tutar': amount,
      'Döviz Tutarı': secondaryAmount,
    }..removeWhere((_, v) => v == null || v.trim().isEmpty);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: s.surface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 14),
          side: BorderSide(
              color: s.outlineVariant
                  .withValues(alpha: ErpDesignStyle.modern(context) ? .7 : .5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (context) => SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Belge Detayı',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    for (final entry in details.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  width: 100,
                                  child: Text(entry.key,
                                      style: TextStyle(
                                          color: s.onSurfaceVariant,
                                          fontSize: 13))),
                              Expanded(
                                  child: SelectableText(entry.value!,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500))),
                            ]),
                      ),
                  ],
                ),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.receipt_long_outlined, size: 17, color: s.primary),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(number,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: s.onSurfaceVariant))),
                const SizedBox(width: 8),
                Text('Vade $dueDate',
                    style: TextStyle(fontSize: 11, color: s.onSurfaceVariant)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: s.onSurfaceVariant),
              ]),
              const SizedBox(height: 8),
              Text(customer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      if (status?.isNotEmpty == true)
                        Text(status!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: s.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      if (location?.isNotEmpty == true)
                        Text(location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: s.onSurfaceVariant, fontSize: 11)),
                    ])),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                      FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(amount,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700))),
                      if (secondaryAmount != null)
                        Text(secondaryAmount!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: s.onSurfaceVariant)),
                    ])),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
