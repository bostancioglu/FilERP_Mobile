import 'package:flutter/material.dart';
import '../../helpers/para_birimi_helper.dart';

class GenelIskontoResult {
  final double? oran;
  final double? tutar;
  const GenelIskontoResult({this.oran, this.tutar});
}

Future<GenelIskontoResult?> showFaturaGenelIskontoSheet(
  BuildContext context, {
  double? oran,
  double? tutar,
  String title = "Genel İskonto",
  double araToplam = 0,
  bool isDoviz = false,
  double kur = 1.0,
  int? dovizId,
}) {
  return showModalBottomSheet<GenelIskontoResult>(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _GenelIskontoSheet(
      oran: oran,
      tutar: tutar,
      title: title,
      araToplam: araToplam,
      isDoviz: isDoviz,
      kur: kur,
      dovizId: dovizId,
    ),
  );
}

class _GenelIskontoSheet extends StatefulWidget {
  final double? oran;
  final double? tutar;
  final String title;
  final double araToplam;
  final bool isDoviz;
  final double kur;
  final int? dovizId;

  const _GenelIskontoSheet({
    this.oran,
    this.tutar,
    this.title = "Genel İskonto",
    this.araToplam = 0,
    this.isDoviz = false,
    this.kur = 1.0,
    this.dovizId,
  });

  @override
  State<_GenelIskontoSheet> createState() => _GenelIskontoSheetState();
}

class _GenelIskontoSheetState extends State<_GenelIskontoSheet> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _oranCtrl;
  late TextEditingController _tutarCtrl;

  @override
  void initState() {
    super.initState();
    _oranCtrl = TextEditingController(
      text: (widget.oran ?? 0) > 0 ? widget.oran!.toStringAsFixed(2) : "",
    );
    _tutarCtrl = TextEditingController(
      text: (widget.tutar ?? 0) > 0 ? widget.tutar!.toStringAsFixed(2) : "",
    );
  }

  @override
  void dispose() {
    _oranCtrl.dispose();
    _tutarCtrl.dispose();
    super.dispose();
  }

  double _parse(String text) {
    if (text.trim().isEmpty) return 0;
    return double.tryParse(text.replaceAll(',', '.')) ?? 0;
  }

  // Oran değişince tutarı otomatik hesapla
  void _onOranChanged(String val) {
    final oran = _parse(val);
    if (oran > 0 && oran <= 100 && widget.araToplam > 0) {
      final hesaplanan = widget.araToplam * (oran / 100);
      _tutarCtrl.text = hesaplanan.toStringAsFixed(2);
    } else {
      _tutarCtrl.text = "";
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sembol = ParaBirimiHelper.sembolById(widget.dovizId);
    final tutarLabel =
        widget.isDoviz ? "İskonto Tutarı ($sembol)" : "İskonto Tutarı (₺)";
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding:
          EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),

            // Oran
            TextFormField(
              controller: _oranCtrl,
              decoration: InputDecoration(
                labelText: "İskonto Oranı (%)",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: _onOranChanged,
              validator: (v) {
                final d = _parse(v ?? "");
                if (d < 0) return "0'dan küçük olamaz";
                if (d > 100) return "100'den büyük olamaz";
                return null;
              },
            ),
            SizedBox(height: 12),

            // Tutar
            TextFormField(
              controller: _tutarCtrl,
              decoration: InputDecoration(
                labelText: tutarLabel,
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _oranCtrl.clear()),
              validator: (v) {
                final d = _parse(v ?? "");
                if (d < 0) return "0'dan küçük olamaz";
                if (d > widget.araToplam) return "Matrahtan büyük olamaz";
                return null;
              },
            ),

            // Dövizli ise TL karşılığı
            if (widget.isDoviz)
              Builder(builder: (_) {
                final tutar = _parse(_tutarCtrl.text);
                if (tutar <= 0) return SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _scheme.primary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _scheme.primary),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline,
                          size: 14, color: _scheme.primary),
                      SizedBox(width: 6),
                      Text(
                        "TL Karşılığı: ${(tutar * widget.kur).toStringAsFixed(2)} ₺"
                        "  (Kur: ${widget.kur.toStringAsFixed(4)})",
                        style: TextStyle(fontSize: 12, color: _scheme.primary),
                      ),
                    ]),
                  ),
                );
              }),

            SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _scheme.error,
                  foregroundColor: _scheme.onError,
                  minimumSize: Size.fromHeight(48),
                ),
                onPressed: () => Navigator.pop(
                    context, const GenelIskontoResult(oran: null, tutar: null)),
                child: Text("Temizle"),
              )),
              SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: Size.fromHeight(48)),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  final oran = _parse(_oranCtrl.text);
                  final tutar = _parse(_tutarCtrl.text);
                  Navigator.pop(
                      context,
                      GenelIskontoResult(
                        oran: oran > 0 ? oran : null,
                        tutar: tutar > 0 ? tutar : null,
                      ));
                },
                child: Text("Uygula"),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}
