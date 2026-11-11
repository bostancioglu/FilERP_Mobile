import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardSlice {
  final String label;
  final double value;
  final Color color;
  const DashboardSlice(this.label, this.value, this.color);
}

class DashboardDonut extends StatefulWidget {
  final String title, subtitle;
  final List<DashboardSlice>? slices;
  const DashboardDonut(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.slices});
  @override
  State<DashboardDonut> createState() => _DashboardDonutState();
}

class _DashboardDonutState extends State<DashboardDonut> {
  int? selected;
  @override
  void didUpdateWidget(DashboardDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final slices = widget.slices;
    final total = slices?.fold<double>(0, (sum, s) => sum + s.value) ?? 0;
    final valid =
        slices != null && slices.every((s) => s.value.isFinite && s.value >= 0);
    final money = NumberFormat('#,##0.00', 'tr_TR');
    return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
        child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (widget.subtitle.isNotEmpty) const SizedBox(height: 4),
              if (widget.subtitle.isNotEmpty)
                Text(widget.subtitle,
                    style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              if (!valid)
                const Text(
                    'Dağılım için tüm kaynakların alınması ve tutarların pozitif olması gerekiyor.')
              else if (total <= 0)
                const Text('Bu dönemde dağılım oluşturacak işlem yok.')
              else ...[
                Center(
                    child: SizedBox(
                        width: 180,
                        height: 180,
                        child: Stack(alignment: Alignment.center, children: [
                          ExcludeSemantics(
                              child: CustomPaint(
                                  size: const Size(180, 180),
                                  painter: _DonutPainter(slices, selected,
                                      Theme.of(context).colorScheme.surface))),
                          Padding(
                              padding: const EdgeInsets.all(34),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                        selected == null
                                            ? 'TOPLAM'
                                            : slices[selected!].label,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        style: const TextStyle(fontSize: 11)),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                        child: Text(
                                            '${money.format(selected == null ? total : slices[selected!].value)} TL',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800))),
                                  ])),
                        ]))),
                const SizedBox(height: 16),
                for (var i = 0; i < slices.length; i++)
                  Semantics(
                      button: true,
                      selected: selected == i,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () =>
                            setState(() => selected = selected == i ? null : i),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(children: [
                              Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                      color: slices[i].color,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(slices[i].label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 8),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        '%${(100 * slices[i].value / total).toStringAsFixed(1)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    Text('${money.format(slices[i].value)} TL',
                                        style: const TextStyle(fontSize: 11))
                                  ]),
                            ])),
                      )),
              ],
            ])));
  }
}

class _DonutPainter extends CustomPainter {
  final List<DashboardSlice> slices;
  final int? selected;
  final Color background;
  _DonutPainter(this.slices, this.selected, this.background);
  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;
    final rect = Rect.fromCircle(
        center: size.center(Offset.zero), radius: size.shortestSide / 2 - 16);
    var angle = -math.pi / 2;
    for (var i = 0; i < slices.length; i++) {
      final sweep = slices[i].value / total * math.pi * 2;
      if (sweep > 0) {
        canvas.drawArc(
            rect,
            angle,
            sweep,
            false,
            Paint()
              ..color = selected == null || selected == i
                  ? slices[i].color
                  : slices[i].color.withValues(alpha: .25)
              ..style = PaintingStyle.stroke
              ..strokeWidth = selected == i ? 26 : 20);
        if (sweep < math.pi * 2) {
          canvas.drawArc(
              rect,
              angle,
              math.min(.025, sweep / 3),
              false,
              Paint()
                ..color = background
                ..style = PaintingStyle.stroke
                ..strokeWidth = 28);
        }
      }
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
