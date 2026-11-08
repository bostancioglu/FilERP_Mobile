import 'package:flutter/material.dart';

import '../../models/entities/siparis/siparishareket_dto.dart';
import '../../helpers/number_format_helper.dart';

Future<SiparishareketDto?> showSiparisKalemIskontoSheet(
  BuildContext context, {
  required SiparishareketDto kalem,
  int? dovizId,
  required bool kdvDahil,
  required double brutAra, // miktar × fiyat (KDV dahil toplam)
}) {
  return showModalBottomSheet<SiparishareketDto>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _SiparisIskontoSheet(
      kalem: kalem,
      dovizId: dovizId,
      kdvDahil: kdvDahil,
      brutAra: brutAra,
    ),
  );
}

class _SiparisIskontoSheet extends StatefulWidget {
  final SiparishareketDto kalem;
  final int? dovizId;
  final bool kdvDahil;
  final double brutAra;

  const _SiparisIskontoSheet({
    required this.kalem,
    required this.dovizId,
    required this.kdvDahil,
    required this.brutAra,
  });

  @override
  State<_SiparisIskontoSheet> createState() => _SiparisIskontoSheetState();
}

class _SiparisIskontoSheetState extends State<_SiparisIskontoSheet> {
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
    return SingleChildScrollView(
        child: Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "İskontolar (Satır)",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          for (int i = 0; i < 6; i++) ...[
            Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text("${i + 1}.",
                      style: const TextStyle(
                          fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: TextField(
                    controller: _oranCtrls[i],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Oran (%)",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => _setOran(i, v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _tutarCtrls[i],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Tutar",
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixText: _sembol,
                    ),
                    onChanged: (v) => _setTutar(i, v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          const Divider(height: 24),
          // Mal Fazlası İskontosu
          Row(
            children: [
              Icon(Icons.card_giftcard_outlined,
                  size: 20, color: _scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text("Mal Fazlası İskontosu",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _scheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 36),
              Expanded(
                child: TextField(
                  controller: _malFazlasiCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Adet",
                    hintText: "Kaç adet mal fazlası?",
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixText: "adet",
                    helperText: (widget.kalem.fiyat ?? 0) > 0
                        ? "Birim: ${NumberFormatHelper.format(widget.kalem.fiyat ?? 0)} $_sembol"
                        : null,
                    helperStyle: TextStyle(
                        fontFamily: 'Roboto',
                        color: _scheme.primary,
                        fontSize: 11),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _scheme.error,
                    foregroundColor: _scheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.clear),
                  label: const Text("Temizle"),
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
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _scheme.primary,
                    foregroundColor: _scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text("Uygula"),
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
    ));
  }
}
