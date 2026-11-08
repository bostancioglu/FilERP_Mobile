import 'package:flutter/material.dart';

import '../../models/entities/fatura/faturahareket_dto.dart';
import '../../helpers/number_format_helper.dart';
import '../../helpers/para_birimi_helper.dart';

class FaturaKalemCard extends StatelessWidget {
  final FaturahareketDto kalem;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int? dovizId;
  final double kur;

  const FaturaKalemCard({
    super.key,
    required this.kalem,
    required this.onEdit,
    required this.onDelete,
    required this.dovizId,
    this.kur = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final sembol = ParaBirimiHelper.sembolById(dovizId);
    final bool isDoviz = (dovizId != null && dovizId != 1);
    final double k = isDoviz ? kur.clamp(0.001, double.infinity) : 1.0;

    double _d(double v) => isDoviz ? v / k : v;

    // Birim fiyat: dövizliyse dovizfiyat, değilse fiyat
    final fiyat = isDoviz
        ? ((kalem.dovizfiyat ?? 0) > 0
            ? kalem.dovizfiyat!
            : (kalem.fiyat ?? 0) / k)
        : (kalem.fiyat ?? 0);

    final miktar = kalem.miktar ?? 0;
    final iskonto = _d(kalem.iskontotutar ?? 0);
    final tutar = _d(kalem.tutar ?? 0);
    final hasIskonto = iskonto > 0;

    return Dismissible(
      key: ValueKey(kalem.hashCode),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        kalem.stok != null
                            ? "${kalem.stok!.Kod ?? ''} - ${kalem.stok!.Ad ?? ''}"
                            : "Stok #${kalem.stokid}",
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: onEdit),
                    IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: Colors.red),
                        onPressed: onDelete),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${NumberFormatHelper.format(miktar)} × ${NumberFormatHelper.format(fiyat, decimal: 4)} $sembol",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                if (hasIskonto)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("İskonto",
                            style: TextStyle(color: Colors.red)),
                        Text(
                          "- ${NumberFormatHelper.format(iskonto)} $sembol",
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Toplam",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      "${NumberFormatHelper.format(tutar)} $sembol",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
