import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:flutter/material.dart';

import '../../helpers/gunluk_kod_helper.dart';
import '../../services/ai/ai_settings_service.dart';
import '../../services/ai/anthropic_service.dart';

class AiAyarlarPage extends StatefulWidget {
  const AiAyarlarPage({super.key});

  @override
  State<AiAyarlarPage> createState() => _AiAyarlarPageState();
}

class _AiAyarlarPageState extends State<AiAyarlarPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _kRed => _scheme.error;
  Color get _success => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF6EE7B7)
      : const Color(0xFF16704A);
  final _svc = AiSettingsService.instance;
  final _keyCtrl = TextEditingController();

  String? _kayitliKey;
  bool _obscure = true;
  bool _loading = true;
  bool _kaydediliyor = false;
  bool _testEdiliyor = false;
  String? _testSonucu; // null=henüz test yok
  bool? _testBasarili;

  bool _unlocked = false;
  final _pinCtrl = TextEditingController();
  String? _pinHata;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _pinDogrula() {
    if (GunlukKodHelper.dogrula(_pinCtrl.text)) {
      FocusScope.of(context).unfocus();
      setState(() {
        _unlocked = true;
        _pinHata = null;
      });
    } else {
      setState(() => _pinHata = 'Kod hatalı.');
    }
  }

  Future<void> _load() async {
    final key = await _svc.getApiKey();
    if (mounted)
      setState(() {
        _kayitliKey = key;
        _loading = false;
      });
  }

  Future<void> _kaydet() async {
    final girilen = _keyCtrl.text.trim();
    if (girilen.isEmpty) return;
    setState(() => _kaydediliyor = true);
    await _svc.saveApiKey(girilen);
    _keyCtrl.clear();
    if (!mounted) return;
    setState(() {
      _kayitliKey = girilen;
      _kaydediliyor = false;
      _testSonucu = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API anahtarı kaydedildi.')),
    );
  }

  Future<void> _sil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Anahtarı Sil'),
        content: const Text(
            'Kayıtlı API anahtarı cihazdan silinecek. Emin misiniz?'),
        actions: [
          ErpDialogAction(
              secondary: true,
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
          ErpDialogAction(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Sil', style: TextStyle(color: _kRed))),
        ],
      ),
    );
    if (onay != true) return;
    await _svc.clearApiKey();
    if (!mounted) return;
    setState(() {
      _kayitliKey = null;
      _testSonucu = null;
    });
  }

  Future<void> _testEt() async {
    if (_kayitliKey == null) return;
    setState(() {
      _testEdiliyor = true;
      _testSonucu = null;
    });
    final hata = await AnthropicService().testConnection(_kayitliKey!);
    if (!mounted) return;
    setState(() {
      _testEdiliyor = false;
      _testBasarili = hata == null;
      _testSonucu = hata ?? 'Bağlantı başarılı.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
            title: const Text('Yapay Zekâ Ayarları'),
            backgroundColor: _scheme.surface,
            foregroundColor: _scheme.onSurface),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : !_unlocked
                ? _buildKilitEkrani()
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _anahtarKarti(),
                      if (_kayitliKey != null) ...[
                        const SizedBox(height: 8),
                        _testKarti()
                      ],
                    ],
                  ),
      );

  Widget _panel(
          {required IconData icon,
          required String title,
          required Widget child}) =>
      Material(
        color: _scheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: _scheme.outlineVariant.withValues(alpha: .6))),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, size: 18, color: _scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(title,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _scheme.onSurface)))
              ]),
              const SizedBox(height: 12),
              child,
            ])),
      );

  Widget _buildKilitEkrani() => Center(
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: _panel(
                icon: Icons.lock_outline_rounded,
                title: 'Erişim Kodu',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                          controller: _pinCtrl,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _pinDogrula(),
                          decoration: InputDecoration(
                              labelText: 'Erişim Kodu',
                              errorText: _pinHata,
                              isDense: true)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                          onPressed: _pinDogrula,
                          icon: const Icon(Icons.lock_open_rounded, size: 16),
                          label: const Text('Giriş')),
                    ])),
          )));

  Widget _anahtarKarti() => _panel(
      icon: Icons.key_outlined,
      title: 'Anthropic API Anahtarı',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_kayitliKey != null) ...[
          Row(children: [
            Icon(Icons.check_circle_outline_rounded, color: _success, size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text(_svc.maskKey(_kayitliKey!),
                    style: TextStyle(fontSize: 12, color: _scheme.onSurface))),
            PopupMenuButton<String>(
                tooltip: 'Anahtar İşlemleri',
                onSelected: (_) => _sil(),
                itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'delete', child: Text('Anahtarı Sil'))
                    ]),
          ]),
          const SizedBox(height: 8),
        ],
        TextField(
            controller: _keyCtrl,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            style: TextStyle(fontSize: 13, color: _scheme.onSurface),
            decoration: InputDecoration(
                labelText: 'API Anahtarı',
                isDense: true,
                suffixIcon: IconButton(
                    tooltip: _obscure ? 'Anahtarı Göster' : 'Anahtarı Gizle',
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18),
                    onPressed: () => setState(() => _obscure = !_obscure)))),
        const SizedBox(height: 12),
        Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
                onPressed: _kaydediliyor ? null : _kaydet,
                icon: _kaydediliyor
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined, size: 16),
                label: const Text('Kaydet'))),
      ]));

  Widget _testKarti() => _panel(
      icon: Icons.wifi_tethering_rounded,
      title: 'Bağlantı',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
                onPressed: _testEdiliyor ? null : _testEt,
                icon: _testEdiliyor
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Bağlantıyı Test Et'))),
        if (_testSonucu != null)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(
                    _testBasarili == true
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    size: 16,
                    color: _testBasarili == true ? _success : _scheme.error),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_testSonucu!,
                        style: TextStyle(
                            fontSize: 12,
                            color: _testBasarili == true
                                ? _success
                                : _scheme.error))),
              ])),
      ]));
}
