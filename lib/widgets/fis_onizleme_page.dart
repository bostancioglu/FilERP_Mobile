import 'package:FilERP/widgets/permission_page.dart';
import 'erp_page_style.dart';
import 'package:flutter/material.dart';

/// Fişi önce EKRANDA gösterir; "Yazdır" ile yazıcıya gönderir.
/// Yazıcı uzakta / kapalı olsa bile fiş ekranda kalır, yaklaşılınca "Tekrar Yazdır" denenebilir.
///
/// [yazdir]: başarılıysa `null`, değilse kullanıcıya gösterilecek hata mesajını döndürür.
Future<void> showFisOnizleme(
  BuildContext context, {
  required String baslik,
  required List<String> satirlar,
  required Future<String?> Function() yazdir,
}) {
  return Navigator.of(context).push(PermissionMaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) =>
        _FisOnizlemePage(baslik: baslik, satirlar: satirlar, yazdir: yazdir),
  ));
}

class _FisOnizlemePage extends StatefulWidget {
  final String baslik;
  final List<String> satirlar;
  final Future<String?> Function() yazdir;

  const _FisOnizlemePage(
      {required this.baslik, required this.satirlar, required this.yazdir});

  @override
  State<_FisOnizlemePage> createState() => _FisOnizlemePageState();
}

class _FisOnizlemePageState extends State<_FisOnizlemePage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.onSurface;

  bool _yaziliyor = false;
  bool _basarili = false;
  String? _hata;

  Future<void> _yazdir() async {
    setState(() {
      _yaziliyor = true;
      _hata = null;
      _basarili = false;
    });
    String? sonuc;
    try {
      sonuc = await widget.yazdir();
    } catch (e) {
      sonuc = 'Yazdırma hatası: $e';
    }
    if (!mounted) return;
    setState(() {
      _yaziliyor = false;
      _hata = sonuc;
      _basarili = sonuc == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECEFF3),
      appBar: ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        title: Text(widget.baslik,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(12),
            child: Center(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(14, 16, 14, 20),
                decoration: BoxDecoration(
                  color: _scheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: Offset(0, 4))
                  ],
                ),
                // Fiş genişliği (satır karakter sayısı) ekrana sığmazsa yazı orantılı küçülür
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: Text(
                    widget.satirlar.join('\n'),
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.3,
                        color: _scheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_hata != null)
          _durumKutusu(
            Icons.print_disabled_rounded,
            '$_hata\nFiş ekranda duruyor; yazıcıya yaklaşıp "Tekrar Yazdır"a basabilirsiniz.',
            Color(0xFFD32F2F),
          ),
        if (_basarili)
          _durumKutusu(Icons.check_circle_rounded, 'Fiş yazıcıya gönderildi.',
              Color(0xFF2E7D32)),
        Container(
          color: _scheme.surface,
          padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed:
                        _yaziliyor ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Kapat',
                        style: TextStyle(
                            fontFamily: 'Roboto', fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _yaziliyor ? null : _yazdir,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _scheme.primary,
                      foregroundColor: _scheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: _yaziliyor
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _scheme.surface))
                        : Icon(Icons.print_rounded, size: 20),
                    label: Text(
                      _yaziliyor
                          ? 'Yazdırılıyor...'
                          : (_hata != null || _basarili
                              ? 'Tekrar Yazdır'
                              : 'Yazdır'),
                      style: TextStyle(
                          fontFamily: 'Roboto', fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _durumKutusu(IconData ikon, String mesaj, Color renk) => Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: renk.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: renk.withOpacity(0.35)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(ikon, size: 18, color: renk),
          SizedBox(width: 8),
          Expanded(
              child: Text(mesaj,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12.5,
                      color: renk,
                      height: 1.35))),
        ]),
      );
}
