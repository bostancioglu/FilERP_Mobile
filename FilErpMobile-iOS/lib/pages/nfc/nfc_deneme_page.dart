import 'package:FilERP/widgets/erp_dialog_action.dart';
import '../../theme/app_theme.dart';
import '../../widgets/erp_page_style.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class NfcDenemePage extends StatefulWidget {
  const NfcDenemePage({super.key});
  @override
  State<NfcDenemePage> createState() => _NfcDenemePageState();
}

class _NfcDenemePageState extends State<NfcDenemePage>
    with SingleTickerProviderStateMixin {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _positive => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFF6EE7B7)
      : Color(0xFF16704A);
  Color get _primary => _scheme.primary;
  Color get _accent => _scheme.primary;

  NFCAvailability _availability = NFCAvailability.not_supported;
  bool _okuma = false;
  String _durum = "NFC kontrol ediliyor...";

  String? _uid;
  String? _tagTipi;
  String? _standart;
  List<_NdefKayit> _ndefKayitlar = [];
  String _detayStr = '';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _pulseAnim = Tween(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _nfcKontrol();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    FlutterNfcKit.finish().catchError((_) {});
    super.dispose();
  }

  // ─── NFC Kontrol ─────────────────────────────────────────
  Future<void> _nfcKontrol() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      if (!mounted) return;
      setState(() {
        _availability = availability;
        _durum = switch (availability) {
          NFCAvailability.available => "NFC hazır",
          NFCAvailability.disabled => "NFC kapalı",
          NFCAvailability.not_supported => "Bu cihaz NFC desteklemiyor",
        };
      });
    } catch (e) {
      if (mounted) setState(() => _durum = "NFC kontrol hatası: $e");
    }
  }

  bool get _nfcAcik => _availability == NFCAvailability.available;

  // ─── Okuma Başlat ────────────────────────────────────────
  Future<void> _okumayaBasla() async {
    if (!_nfcAcik) {
      _nfcAyarlarAc();
      return;
    }

    _pulseCtrl.repeat(reverse: true);
    setState(() {
      _okuma = true;
      _uid = null;
      _tagTipi = null;
      _standart = null;
      _ndefKayitlar = [];
      _detayStr = '';
      _durum = "Telefonu terminalin NFC alanına yaklaştırın...";
    });

    try {
      // Tag'i oku
      final tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 20),
        // FeliCa sistem kodları tanımlı değil; iOS oturumunda tarama kapalı.
        readIso18092: false,
        iosMultipleTagMessage: "Birden fazla tag algılandı",
        iosAlertMessage: "Telefonu yaklaştırın",
      );

      await _tagIsle(tag);
    } catch (e) {
      if (mounted) setState(() => _durum = "Hata: $e");
    } finally {
      await FlutterNfcKit.finish();
      if (mounted) {
        _pulseCtrl.stop();
        setState(() => _okuma = false);
      }
    }
  }

  Future<void> _okumayiDurdur() async {
    await FlutterNfcKit.finish().catchError((_) {});
    if (mounted)
      setState(() {
        _okuma = false;
        _durum = "Okuma iptal edildi";
      });
  }

  // ─── Tag İşle ────────────────────────────────────────────
  Future<void> _tagIsle(NFCTag tag) async {
    final StringBuffer detay = StringBuffer();
    final List<_NdefKayit> kayitlar = [];

    // flutter_nfc_kit direkt olarak tüm bilgileri NFCTag'de veriyor
    final uid = tag.id.toUpperCase();
    final tagTipi = tag.type.toString().split('.').last;
    final standart = tag.standard ?? "-";

    detay.writeln("ID      : ${tag.id}");
    detay.writeln("Tip     : $tagTipi");
    detay.writeln("Standart: $standart");
    if (tag.atqa != null) detay.writeln("ATQA    : ${tag.atqa}");
    if (tag.sak != null) detay.writeln("SAK     : ${tag.sak}");
    if (tag.historicalBytes != null)
      detay.writeln("Hist    : ${tag.historicalBytes}");
    if (tag.protocolInfo != null)
      detay.writeln("Proto   : ${tag.protocolInfo}");
    if (tag.applicationData != null)
      detay.writeln("AppData : ${tag.applicationData}");
    detay.writeln("NDEF    : ${(tag.ndefAvailable == true) ? 'Var' : 'Yok'}");
    if (tag.ndefCapacity != null)
      detay.writeln("Kapasite: ${tag.ndefCapacity} byte");
    if (tag.ndefWritable != null)
      detay.writeln("Yazılabilir: ${tag.ndefWritable}");

    // NDEF kayıtlarını oku
    if (tag.ndefAvailable == true) {
      try {
        final ndefRecords = await FlutterNfcKit.readNDEFRecords(cached: false);
        for (int i = 0; i < ndefRecords.length; i++) {
          final rec = ndefRecords[i];
          String tip = rec.runtimeType.toString();
          String icerik = "";

          if (rec is ndef.TextRecord) {
            tip = "Text";
            icerik = rec.text ?? "";
          } else if (rec is ndef.UriRecord) {
            tip = "URI";
            icerik = rec.uri?.toString() ?? "";
          } else if (rec is ndef.MimeRecord) {
            tip = "MIME: ${rec.decodedType}";
            icerik = utf8.decode(rec.payload ?? [], allowMalformed: true);
          } else {
            icerik = rec.payload != null
                ? utf8.decode(rec.payload!, allowMalformed: true)
                : "-";
          }

          kayitlar.add(_NdefKayit(tip: tip, icerik: icerik));
          detay.writeln("Kayıt $i [$tip]: $icerik");
        }
      } catch (e) {
        detay.writeln("NDEF okuma hatası: $e");
      }
    }

    if (mounted) {
      HapticFeedback.mediumImpact();
      setState(() {
        _uid = uid;
        _tagTipi = tagTipi;
        _standart = standart;
        _ndefKayitlar = kayitlar;
        _detayStr = detay.toString();
        _durum = "✅ Tag başarıyla okundu!";
      });
    }
  }

  void _nfcAyarlarAc() => showDialog(
      context: context,
      builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("NFC Kapalı"),
            content: Text("Cihazınızın NFC özelliği kapalı.\n\n"
                "Ayarlar → Bağlantı → NFC yolunu izleyerek açabilirsiniz."),
            actions: [
              ErpDialogAction(
                  onPressed: () => Navigator.pop(context), child: Text("Tamam"))
            ],
          ));

  void _kopyala(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Kopyalandı ✓"), duration: Duration(seconds: 1)));
  }

  // ─── BUILD ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: ErpPageAppBar(
        context: context,
        title: Text("NFC Deneme",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
              icon: Icon(Icons.refresh_rounded),
              onPressed: _nfcKontrol,
              tooltip: "Yenile")
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(children: [
          _buildDurumKart(),
          SizedBox(height: 16),
          _buildOkumaButon(),
          SizedBox(height: 16),
          if (_uid != null) ...[_buildSonucKart(), SizedBox(height: 16)],
          if (_ndefKayitlar.isNotEmpty) ...[
            _buildNdefKart(),
            SizedBox(height: 16)
          ],
          if (_detayStr.isNotEmpty) _buildDetayKart(),
          SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildDurumKart() {
    final Color renk;
    final Color arka;
    final String baslik;
    switch (_availability) {
      case NFCAvailability.available:
        renk = _positive;
        arka = _positive.withValues(alpha: .08);
        baslik = "NFC Açık";
      case NFCAvailability.disabled:
        renk = _scheme.primary;
        arka = _scheme.primary.withValues(alpha: .08);
        baslik = "NFC Kapalı";
      case NFCAvailability.not_supported:
        renk = _scheme.error;
        arka = _scheme.error.withValues(alpha: .08);
        baslik = "NFC Desteklenmiyor";
    }
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _scheme.surface,
          borderRadius:
              BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 3))
          ]),
      child: Row(children: [
        Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: arka, shape: BoxShape.circle),
            child: Icon(Icons.nfc_rounded, color: renk, size: 28)),
        SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(baslik,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: renk)),
          SizedBox(height: 4),
          Text(_durum,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color: _scheme.onSurfaceVariant)),
        ])),
        if (!_nfcAcik)
          TextButton(onPressed: _nfcAyarlarAc, child: Text("Ayarlar")),
      ]),
    );
  }

  Widget _buildOkumaButon() {
    if (_okuma) {
      return Column(children: [
        ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.12),
                  border: Border.all(color: _accent, width: 3)),
              child: Icon(Icons.nfc_rounded, size: 40, color: _accent),
            )),
        SizedBox(height: 16),
        Text("Yaklaştırın...",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _accent)),
        SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: _okumayiDurdur,
            icon: Icon(Icons.stop_circle_outlined, size: 18),
            label: Text("İptal Et"),
            style: OutlinedButton.styleFrom(
                foregroundColor: _scheme.error,
                side: BorderSide(color: _scheme.error.withValues(alpha: .3)))),
      ]);
    }
    return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _nfcAcik ? _okumayaBasla : _nfcAyarlarAc,
          style: ElevatedButton.styleFrom(
              backgroundColor: _nfcAcik ? _primary : _scheme.onSurfaceVariant,
              foregroundColor: _scheme.onPrimary,
              padding: EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
          icon: Icon(Icons.nfc_rounded, size: 24),
          label: Text(_nfcAcik ? "NFC Oku" : "NFC Ayarları",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ));
  }

  Widget _buildSonucKart() => Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius:
                BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
            border: Border.all(color: _positive.withValues(alpha: .3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.green.withOpacity(0.07),
                  blurRadius: 10,
                  offset: Offset(0, 3))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text("Okunan Tag",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            Spacer(),
            GestureDetector(
                onTap: () => _kopyala("UID: $_uid\nTip: $_tagTipi"),
                child: Icon(Icons.copy_rounded,
                    size: 18, color: _scheme.onSurfaceVariant)),
          ]),
          Divider(height: 20),
          _infoSatir("Tag Tipi", _tagTipi ?? "-", Icons.label_outline),
          SizedBox(height: 8),
          _infoSatir("Standart", _standart ?? "-", Icons.layers_outlined),
          SizedBox(height: 8),
          _infoSatir("UID", _uid ?? "-", Icons.fingerprint_rounded),
          SizedBox(height: 6),
          Text("UID = her tag'e özgü kimlik numarası",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  color: _scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic)),
        ]),
      );

  Widget _buildNdefKart() => Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius:
                BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
            border: Border.all(color: _accent.withOpacity(0.4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.article_outlined, color: _accent, size: 20),
            SizedBox(width: 8),
            Text("NDEF Kayıtları (${_ndefKayitlar.length})",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ]),
          Divider(height: 20),
          ..._ndefKayitlar.asMap().entries.map((e) => Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _accent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accent.withOpacity(0.2))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text("Kayıt ${e.key + 1}",
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 11,
                                  color: _scheme.onSurface,
                                  fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(width: 8),
                        Text(e.value.tip,
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: _scheme.onSurfaceVariant)),
                        Spacer(),
                        GestureDetector(
                            onTap: () => _kopyala(e.value.icerik),
                            child: Icon(Icons.copy_rounded,
                                size: 16, color: _scheme.onSurfaceVariant)),
                      ]),
                      SizedBox(height: 8),
                      Text(e.value.icerik,
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ]),
              )),
        ]),
      );

  Widget _buildDetayKart() => ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _scheme.outlineVariant)),
        collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _scheme.outlineVariant)),
        backgroundColor: _scheme.surface,
        collapsedBackgroundColor: _scheme.surface,
        leading:
            Icon(Icons.data_object_rounded, color: _scheme.onSurfaceVariant),
        title: Text("Teknik Detay",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: _scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600)),
        children: [
          Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: _scheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(8)),
                  child: SelectableText(_detayStr,
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4CAF50),
                          fontFamily: 'monospace')))),
        ],
      );

  Widget _infoSatir(String label, String value, IconData icon) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: _scheme.onSurfaceVariant),
        SizedBox(width: 8),
        Text("$label: ",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                color: _scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
        Expanded(
            child: GestureDetector(
                onTap: () => _kopyala(value),
                child: Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace')))),
      ]);
}

class _NdefKayit {
  final String tip;
  final String icerik;
  const _NdefKayit({required this.tip, required this.icerik});
}
