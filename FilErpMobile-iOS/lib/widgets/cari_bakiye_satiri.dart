import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/number_format_helper.dart';
import '../services/rapor/rapor_service.dart';

/// Seçili carinin güncel bakiyesini gösterir: "Cari bakiye: 1.234,56 [B]".
/// Bakiye, Cari Hareket görünümünün son satırından alınır (rapordaki ile aynı).
/// [cariId] değiştiğinde kendiliğinden yeniden yüklenir; cari yoksa boş kalır.
class CariBakiyeSatiri extends StatefulWidget {
  final int? cariId;
  final bool etiketli;

  /// Bu işlemin cariye etkisi (borç yönü +, alacak yönü −). Verilirse bakiyenin altında
  /// "İşlem sonrası" satırı gösterilir.
  final double? degisim;

  const CariBakiyeSatiri(
      {super.key, required this.cariId, this.etiketli = true, this.degisim});

  @override
  State<CariBakiyeSatiri> createState() => _CariBakiyeSatiriState();
}

class _CariBakiyeSatiriState extends State<CariBakiyeSatiri> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _positive => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFF6EE7B7)
      : Color(0xFF16704A);
  Color get _borcRenk => _scheme.error;
  Color get _alacakRenk => _positive;

  double? _bakiye; // mutlak değer
  bool _borc = true; // true: borç (B), false: alacak (A)
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void didUpdateWidget(covariant CariBakiyeSatiri old) {
    super.didUpdateWidget(old);
    if (old.cariId != widget.cariId) _yukle();
  }

  Future<void> _yukle() async {
    final id = widget.cariId;
    if (id == null) {
      if (mounted) setState(() => _bakiye = null);
      return;
    }
    setState(() {
      _yukleniyor = true;
      _bakiye = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final rows = await RaporService().getCariHareket(token, cariid: id);
      if (!mounted || widget.cariId != id) return;
      final last = rows.isNotEmpty ? rows.last : null;
      final borc = (last?.borcbakiye ?? 0) > 0;
      setState(() {
        _borc = borc;
        _bakiye = last == null
            ? 0
            : (borc ? last.borcbakiye : last.alacakbakiye) ?? 0;
        _yukleniyor = false;
      });
    } catch (_) {
      if (mounted && widget.cariId == id) {
        setState(() {
          _bakiye = null;
          _yukleniyor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cariId == null) return SizedBox.shrink();
    if (_yukleniyor) {
      return Row(children: [
        SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(strokeWidth: 1.6)),
        SizedBox(width: 8),
        Text('Cari bakiyesi alınıyor...',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11.5,
                color: _scheme.onSurfaceVariant)),
      ]);
    }
    if (_bakiye == null) return SizedBox.shrink();
    final satir = _bakiyeSatiri(
        widget.etiketli ? 'Cari bakiye: ' : null, _bakiye!, _borc);
    final d = widget.degisim;
    if (d == null || d.abs() < 0.005) return satir;

    // İşaretli bakiye (borç +): işlem sonrası değeri hesapla.
    final yeni = (_borc ? _bakiye! : -_bakiye!) + d;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      satir,
      SizedBox(height: 4),
      _bakiyeSatiri('İşlem sonrası: ', yeni.abs(), yeni >= -0.005,
          sifir: yeni.abs() <= 0.005),
    ]);
  }

  Widget _bakiyeSatiri(String? etiket, double deger, bool borc,
      {bool sifir = false}) {
    final renk =
        sifir ? _scheme.onSurfaceVariant : (borc ? _borcRenk : _alacakRenk);
    return Row(children: [
      if (etiket != null)
        Text(etiket,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11.5,
                color: _scheme.onSurfaceVariant)),
      Text(NumberFormatHelper.format(deger),
          style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: renk)),
      if (!sifir) ...[
        SizedBox(width: 6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
              color: renk.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4)),
          child: Text(borc ? 'B' : 'A',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: renk)),
        ),
      ],
    ]);
  }
}
