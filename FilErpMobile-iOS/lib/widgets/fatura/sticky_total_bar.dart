import 'package:flutter/material.dart';
import '../../helpers/number_format_helper.dart';
import '../../helpers/para_birimi_helper.dart';

class StickyTotalBar extends StatelessWidget {
  final double araToplam;
  final double iskonto;
  final double kdv;
  final double genelToplam;
  final VoidCallback onSave;
  final int? dovizId;
  final double kur;

  const StickyTotalBar({
    super.key,
    required this.araToplam,
    required this.iskonto,
    required this.kdv,
    required this.genelToplam,
    required this.onSave,
    required this.dovizId,
    this.kur = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDoviz = (dovizId != null && dovizId != 1);
    final double k = isDoviz ? kur.clamp(0.001, double.infinity) : 1.0;

    // Dövizli ise TL değerleri kura bölerek döviz cinsinden göster
    double _d(double v) => isDoviz ? v / k : v;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row("Ara Toplam", _d(araToplam), dovizId: dovizId),
            _row("İskonto", -_d(iskonto), dovizId: dovizId),
            _row("KDV", _d(kdv), dovizId: dovizId),
            const Divider(),
            _row("GENEL TOPLAM", _d(genelToplam), bold: true, dovizId: dovizId),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text("KAYDET"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String t, double v, {bool bold = false, int? dovizId}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(t),
        Text(
          "${NumberFormatHelper.format(v)} "
          "${ParaBirimiHelper.sembolById(dovizId)}",
          style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
        ),
      ],
    );
  }
}
