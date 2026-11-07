import 'package:flutter/material.dart';
import '../../helpers/number_format_helper.dart';

enum GenelIskontoTip { oran, tutar }

class GenelIskontoBar extends StatefulWidget {
  final double? oran;
  final double? tutar;
  final ValueChanged<double?> onOranChanged;
  final ValueChanged<double?> onTutarChanged;

  const GenelIskontoBar({
    super.key,
    required this.oran,
    required this.tutar,
    required this.onOranChanged,
    required this.onTutarChanged,
  });

  @override
  State<GenelIskontoBar> createState() => _GenelIskontoBarState();
}

class _GenelIskontoBarState extends State<GenelIskontoBar> {
  GenelIskontoTip tip = GenelIskontoTip.oran;

  final TextEditingController _oranCtrl = TextEditingController();
  final TextEditingController _tutarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    if ((widget.tutar ?? 0) > 0) {
      tip = GenelIskontoTip.tutar;
    }

    _oranCtrl.text = NumberFormatHelper.format(widget.oran, decimal: 2);
    _tutarCtrl.text = NumberFormatHelper.format(widget.tutar, decimal: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Genel İskonto",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            /// SWITCH
            Row(
              children: [
                Expanded(
                  child: RadioListTile<GenelIskontoTip>(
                    value: GenelIskontoTip.oran,
                    groupValue: tip,
                    title: const Text("%"),
                    onChanged: (v) {
                      setState(() {
                        tip = v!;
                        _tutarCtrl.clear();
                        widget.onTutarChanged(0);
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<GenelIskontoTip>(
                    value: GenelIskontoTip.tutar,
                    groupValue: tip,
                    title: const Text("₺"),
                    onChanged: (v) {
                      setState(() {
                        tip = v!;
                        _oranCtrl.clear();
                        widget.onOranChanged(0);
                      });
                    },
                  ),
                ),
              ],
            ),

            /// INPUT
            if (tip == GenelIskontoTip.oran)
              TextField(
                controller: _oranCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "İskonto Oranı (%)",
                ),
                onChanged: (v) =>
                    widget.onOranChanged(NumberFormatHelper.parse(v)),
              ),

            if (tip == GenelIskontoTip.tutar)
              TextField(
                controller: _tutarCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "İskonto Tutarı (₺)",
                ),
                onChanged: (v) =>
                    widget.onTutarChanged(NumberFormatHelper.parse(v)),
              ),
          ],
        ),
      ),
    );
  }
}
