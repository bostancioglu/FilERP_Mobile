import 'package:flutter/material.dart';

import '../../models/entities/irsaliye/irsaliyehareket_dto.dart';
import '../../helpers/number_format_helper.dart';

Future<IrsaliyehareketDto?> showIrsaliyeKalemIskontoSheet(
  BuildContext context, {
  required IrsaliyehareketDto kalem,
  int? dovizId,
  required bool kdvDahil,
  required double brutAra, // miktar × fiyat (KDV dahil toplam)
}) {
  return showModalBottomSheet<IrsaliyehareketDto>(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _IrsaliyeIskontoSheet(
      kalem: kalem,
      dovizId: dovizId,
      kdvDahil: kdvDahil,
      brutAra: brutAra,
    ),
  );
}

class _IrsaliyeIskontoSheet extends StatefulWidget {
  final IrsaliyehareketDto kalem;
  final int? dovizId;
  final bool kdvDahil;
  final double brutAra;

  const _IrsaliyeIskontoSheet({
    required this.kalem,
    required this.dovizId,
    required this.kdvDahil,
    required this.brutAra,
  });

  @override
  State<_IrsaliyeIskontoSheet> createState() => _IrsaliyeIskontoSheetState();
}

class _IrsaliyeIskontoSheetState extends State<_IrsaliyeIskontoSheet> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  late final List<TextEditingController> _oranCtrls;
  late final List<TextEditingController> _tutarCtrls;
  late final TextEditingController _malFazlasiCtrl;
  late final String _sembol;

  @override
  void initState() {
    super.initState();

    _sembol = '₺';

    double? oranByIdx(int i) {
      switch (i) {
        case 0:
          return widget.kalem.iskontoorani1;
        case 1:
          return widget.kalem.iskontoorani2;
        case 2:
          return widget.kalem.iskontoorani3;
        case 3:
          return widget.kalem.iskontoorani4;
        case 4:
          return widget.kalem.iskontoorani5;
        case 5:
          return widget.kalem.iskontoorani6;
      }
      return null;
    }

    double? tutarByIdx(int i) {
      switch (i) {
        case 0:
          return widget.kalem.iskontotutari1;
        case 1:
          return widget.kalem.iskontotutari2;
        case 2:
          return widget.kalem.iskontotutari3;
        case 3:
          return widget.kalem.iskontotutari4;
        case 4:
          return widget.kalem.iskontotutari5;
        case 5:
          return widget.kalem.iskontotutari6;
      }
      return null;
    }

    _oranCtrls = List.generate(6, (i) {
      final v = oranByIdx(i);
      return TextEditingController(
        text: v == null || v == 0 ? "" : v.toString(),
      );
    });

    _tutarCtrls = List.generate(6, (i) {
      final v = tutarByIdx(i);
      return TextEditingController(
        text: v == null || v == 0 ? "" : NumberFormatHelper.format(v),
      );
    });

    // Mal fazlası: malfazlasiiskonto alanında adet tutulur
    final mfAdet = widget.kalem.malfazlasiiskonto;
    _malFazlasiCtrl = TextEditingController(
      text: mfAdet == null || mfAdet == 0
          ? ""
          : NumberFormatHelper.format(mfAdet),
    );
  }

  @override
  void dispose() {
    for (final c in _oranCtrls) c.dispose();
    for (final c in _tutarCtrls) c.dispose();
    _malFazlasiCtrl.dispose();
    super.dispose();
  }

  void _setOran(int i, String v) {
    if (v.trim().isNotEmpty) {
      _tutarCtrls[i].text = "";
    }
  }

  void _setTutar(int i, String v) {
    if (v.trim().isNotEmpty) {
      _oranCtrls[i].text = "";
    }
  }

  void _applyToKalem() {
    // KDV dahil/hariç fark etmeksizin brüt ara tutar (miktar × fiyat) üzerinden hesapla
    double kalan = widget.brutAra;
    double toplamIskonto = 0;

    double? parseOran(int i) {
      final t = _oranCtrls[i].text.trim();
      if (t.isEmpty) return null;
      return double.tryParse(t.replaceAll(',', '.'));
    }

    double? parseTutar(int i) {
      final t = _tutarCtrls[i].text.trim();
      if (t.isEmpty) return null;
      return NumberFormatHelper.parse(t);
    }

    void setIdx(int i, double? oran, double? tutar) {
      switch (i) {
        case 0:
          widget.kalem.iskontoorani1 = oran;
          widget.kalem.iskontotutari1 = tutar;
          break;
        case 1:
          widget.kalem.iskontoorani2 = oran;
          widget.kalem.iskontotutari2 = tutar;
          break;
        case 2:
          widget.kalem.iskontoorani3 = oran;
          widget.kalem.iskontotutari3 = tutar;
          break;
        case 3:
          widget.kalem.iskontoorani4 = oran;
          widget.kalem.iskontotutari4 = tutar;
          break;
        case 4:
          widget.kalem.iskontoorani5 = oran;
          widget.kalem.iskontotutari5 = tutar;
          break;
        case 5:
          widget.kalem.iskontoorani6 = oran;
          widget.kalem.iskontotutari6 = tutar;
          break;
      }
    }

    for (int i = 0; i < 6; i++) {
      final oran = parseOran(i);
      final tutar = parseTutar(i);

      // Her iki alan da boşsa bu satırı temizle ve atla
      if (oran == null && tutar == null) {
        setIdx(i, null, null);
        continue;
      }

      double isk = 0;

      if ((tutar ?? 0) > 0) {
        isk = tutar!;
      } else if ((oran ?? 0) > 0) {
        isk = kalan * (oran! / 100);
        _tutarCtrls[i].text = NumberFormatHelper.format(isk);
      } else {
        setIdx(i, null, null);
        continue;
      }

      if (isk > kalan) isk = kalan;

      toplamIskonto += isk;
      kalan -= isk;

      setIdx(i, oran, isk);
    }

    widget.kalem.iskontotutar = toplamIskonto;
    widget.kalem.aratoplamiskontolu = kalan;

    // Mal fazlası: adet × birim fiyat → tutar
    final mfAdet = NumberFormatHelper.parse(_malFazlasiCtrl.text);
    if (mfAdet > 0) {
      final birimFiyat = widget.kalem.fiyat ?? 0;
      widget.kalem.malfazlasiiskonto = mfAdet;
      widget.kalem.malfazlasitutar = mfAdet * birimFiyat;
    } else {
      widget.kalem.malfazlasiiskonto = null;
      widget.kalem.malfazlasitutar = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "İskontolar (Satır)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),

          for (int i = 0; i < 6; i++) ...[
            Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text("${i + 1}.",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: TextField(
                    controller: _oranCtrls[i],
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Oran (%)",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => _setOran(i, v),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _tutarCtrls[i],
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Tutar",
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixText: _sembol,
                    ),
                    onChanged: (v) => _setTutar(i, v),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
          ],

          Divider(height: 24),
          // Mal Fazlası İskontosu
          Row(
            children: [
              Icon(Icons.card_giftcard_outlined,
                  size: 20, color: _scheme.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text("Mal Fazlası İskontosu",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _scheme.primary)),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              SizedBox(width: 36),
              Expanded(
                child: TextField(
                  controller: _malFazlasiCtrl,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Adet",
                    hintText: "Adet",
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixText: "adet",
                    helperText: (widget.kalem.fiyat ?? 0) > 0
                        ? "Birim: ${NumberFormatHelper.format(widget.kalem.fiyat ?? 0)} $_sembol"
                        : null,
                    helperStyle:
                        TextStyle(color: _scheme.primary, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _scheme.error,
                    foregroundColor: _scheme.onError,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(Icons.clear),
                  label: Text("Temizle"),
                  onPressed: () {
                    for (int i = 0; i < 6; i++) {
                      _oranCtrls[i].clear();
                      _tutarCtrls[i].clear();
                    }
                    _malFazlasiCtrl.clear();
                    setState(() {});
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _scheme.primary,
                    foregroundColor: _scheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(Icons.check),
                  label: Text("Uygula"),
                  onPressed: () {
                    _applyToKalem();
                    Navigator.pop(context, widget.kalem);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
