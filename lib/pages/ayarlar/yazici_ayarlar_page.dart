import 'package:FilERP/widgets/permission_page.dart';
import 'package:FilERP/widgets/corporate_menu_icon.dart';
import '../../widgets/erp_page_style.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/yazici/bluetooth_print_service.dart';
import '../../services/yazici/yazici_sablon_service.dart';
import 'yazici_sablon_listesi_page.dart';

class YaziciAyarlarPage extends StatefulWidget {
  const YaziciAyarlarPage({super.key});

  @override
  State<YaziciAyarlarPage> createState() => _YaziciAyarlarPageState();
}

class _YaziciAyarlarPageState extends State<YaziciAyarlarPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _kRed => _scheme.primary;
  Color get _kDark => _scheme.onSurface;
  Color get _kBg => Theme.of(context).scaffoldBackgroundColor;

  final _svc = BluetoothPrintService.instance;

  String? _savedMac;
  String? _savedName;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isPrinting = false;
  bool _isLoadingDevices = false;
  int _kagitEni = 80;
  int _satirGen = 32;
  bool _permissionDenied = false;
  String? _customLogoPath;

  List<BluetoothInfo> _pairedDevices = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _requestPermissions();
    await _loadSaved();
    await _loadPaired();
    await _checkConnection();
    final eni = await YaziciSablonService.instance.getKagitEni();
    final gen = await YaziciSablonService.instance.getSatirGenisligi();
    final logo = await YaziciSablonService.instance.getCustomLogoPath();
    if (mounted)
      setState(() {
        _kagitEni = eni;
        _satirGen = gen;
        _customLogoPath = logo;
      });
  }

  Future<void> _requestPermissions() async {
    try {
      final results = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      final denied = results.values.any(
        (s) =>
            s == PermissionStatus.denied ||
            s == PermissionStatus.permanentlyDenied,
      );
      if (mounted) setState(() => _permissionDenied = denied);
    } catch (_) {}
  }

  Future<void> _loadSaved() async {
    final mac = await _svc.getSavedMac();
    final name = await _svc.getSavedName();
    if (mounted)
      setState(() {
        _savedMac = mac;
        _savedName = name;
      });
  }

  Future<void> _loadPaired() async {
    if (!mounted) return;
    setState(() => _isLoadingDevices = true);
    final list = await _svc.getPairedDevices();
    if (mounted)
      setState(() {
        _pairedDevices = list;
        _isLoadingDevices = false;
      });
  }

  Future<void> _checkConnection() async {
    final connected = await _svc.isConnected;
    if (mounted) setState(() => _isConnected = connected);
  }

  Future<void> _connect() async {
    if (_savedMac == null) return;
    setState(() => _isConnecting = true);
    final ok = await _svc.connect(_savedMac!);
    if (mounted) {
      setState(() {
        _isConnected = ok;
        _isConnecting = false;
      });
      _snack(ok ? 'Yazıcıya bağlandı' : 'Bağlantı başarısız', ok);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _isConnecting = true);
    await _svc.disconnect();
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
      });
      _snack('Bağlantı kesildi', true);
    }
  }

  Future<void> _testPrint() async {
    if (!_isConnected) {
      _snack('Önce yazıcıya bağlanın', false);
      return;
    }
    setState(() => _isPrinting = true);
    final ok = await _svc.printTest(printerName: _savedName ?? '');
    if (mounted) {
      setState(() => _isPrinting = false);
      _snack(ok ? 'Test çıktısı gönderildi' : 'Yazdırma başarısız', ok);
    }
  }

  Future<void> _selectDevice(BluetoothInfo device) async {
    await _svc.savePrinter(device.macAdress, device.name);
    // Önceki bağlantıyı kapat
    if (_isConnected) await _svc.disconnect();
    setState(() {
      _savedMac = device.macAdress;
      _savedName = device.name;
      _isConnected = false;
    });
    _snack('Yazıcı seçildi: ${device.name}', true);
  }

  Future<void> _removePrinter() async {
    if (_isConnected) await _svc.disconnect();
    await _svc.clearPrinter();
    if (mounted) {
      setState(() {
        _savedMac = null;
        _savedName = null;
        _isConnected = false;
      });
    }
  }

  Future<void> _logoSec() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (xfile == null || !mounted) return;
    try {
      final path =
          await YaziciSablonService.instance.saveCustomLogo(xfile.path);
      setState(() => _customLogoPath = path);
      _snack('Logo güncellendi', true);
    } catch (e) {
      _snack('Logo kaydedilemedi', false);
    }
  }

  Future<void> _logoSifirla() async {
    await YaziciSablonService.instance.clearCustomLogo();
    if (mounted) setState(() => _customLogoPath = null);
    _snack('Varsayılan logo geri yüklendi', true);
  }

  void _snack(String msg, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? _scheme.primary : _kRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _kDark,
        elevation: 0,
        title: Text('Yazıcı Ayarları'),
        actions: [
          IconButton(
            tooltip: 'Cihazları Yenile',
            icon: _isLoadingDevices
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kDark))
                : Icon(Icons.refresh_rounded),
            onPressed: _isLoadingDevices ? null : _loadPaired,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(height: 1, color: _scheme.surfaceContainerLow),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          // İzin uyarısı
          if (_permissionDenied) ...[
            _permissionBanner(),
            SizedBox(height: 8),
          ],

          // ── Kayıtlı Yazıcı ──
          _sectionCard(
            icon: Icons.print_rounded,
            title: 'Kayıtlı Yazıcı',
            child: _savedMac == null ? _emptyPrinter() : _savedPrinterCard(),
          ),

          SizedBox(height: 8),

          // ── Eşleştirilmiş Cihazlar ──
          _sectionCard(
            icon: Icons.bluetooth_rounded,
            title: 'Bluetooth Cihazları',
            child: _pairedList(),
          ),

          SizedBox(height: 8),

          // ── Kağıt Eni ──
          _sectionCard(
            icon: Icons.straighten_rounded,
            title: 'Kağıt Eni',
            child: Row(
                children: [58, 80].map((mm) {
              final sel = _kagitEni == mm;
              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final gen = mm >= 80 ? 48 : 32;
                    setState(() {
                      _kagitEni = mm;
                      _satirGen = gen;
                    });
                    await YaziciSablonService.instance.setKagitEni(mm);
                    await YaziciSablonService.instance.setSatirGenisligi(gen);
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    margin: EdgeInsets.only(right: mm == 58 ? 8 : 0),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel
                          ? _kRed.withOpacity(0.08)
                          : _scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? _kRed : _scheme.outlineVariant,
                          width: sel ? 1.5 : 1),
                    ),
                    child: Column(children: [
                      Text('${mm}mm',
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: sel ? _kRed : _kDark)),
                      SizedBox.shrink(),
                    ]),
                  ),
                ),
              );
            }).toList()),
          ),

          SizedBox(height: 8),

          // ── Satır Genişliği ince ayarı ──
          _sectionCard(
            icon: Icons.format_size_rounded,
            title: 'Satır Genişliği',
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_satirGen karakter / satır',
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _kDark)),
                    SizedBox.shrink(),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Row(children: [
                _stepBtn(
                    Icons.remove_rounded,
                    _satirGen > 20
                        ? () async {
                            setState(() => _satirGen--);
                            await YaziciSablonService.instance
                                .setSatirGenisligi(_satirGen);
                          }
                        : null),
                Container(
                  width: 44,
                  alignment: Alignment.center,
                  child: Text('$_satirGen',
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _kDark)),
                ),
                _stepBtn(
                    Icons.add_rounded,
                    _satirGen < 64
                        ? () async {
                            setState(() => _satirGen++);
                            await YaziciSablonService.instance
                                .setSatirGenisligi(_satirGen);
                          }
                        : null),
              ]),
            ]),
          ),

          SizedBox(height: 8),

          // ── Yazıcı Logosu ──
          _sectionCard(
            icon: Icons.image_outlined,
            title: 'Yazıcı Logosu',
            child: Row(
              children: [
                // Logo önizleme
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _scheme.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _customLogoPath != null
                        ? Image.file(File(_customLogoPath!),
                            fit: BoxFit.contain)
                        : Image.asset('assets/images/logo_filerp.png',
                            fit: BoxFit.contain),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _customLogoPath != null
                            ? 'Özel Logo'
                            : 'FilERP Logosu (Varsayılan)',
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kDark),
                      ),
                      SizedBox(height: 4),
                      SizedBox.shrink(),
                      SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 4, children: [
                        OutlinedButton.icon(
                          onPressed: _logoSec,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kRed,
                            side: BorderSide(color: _kRed),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: Icon(Icons.upload_rounded, size: 15),
                          label: Text('Değiştir',
                              style: TextStyle(
                                  fontFamily: 'Roboto', fontSize: 12)),
                        ),
                        if (_customLogoPath != null) ...[
                          SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _logoSifirla,
                            style: TextButton.styleFrom(
                              foregroundColor: _scheme.onSurfaceVariant,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 7),
                            ),
                            icon: Icon(Icons.restore_rounded, size: 15),
                            label: Text('Varsayılan',
                                style: TextStyle(
                                    fontFamily: 'Roboto', fontSize: 12)),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8),

          // ── Şablonlar ──
          _sectionCard(
            icon: Icons.receipt_long_outlined,
            title: 'Baskı Şablonları',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: _scheme.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(8)),
                child: const CorporateMenuIcon('Şablonlar', size: 26),
              ),
              title: Text('Şablonları Yönet',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kDark)),
              subtitle: SizedBox.shrink(),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: _scheme.onSurfaceVariant),
              onTap: () => Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const YaziciSablonListesiPage()),
              ),
            ),
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Alt bileşenler ────────────────────────────────────────────────────────

  Widget _permissionBanner() {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _scheme.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _scheme.primary.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _scheme.primary, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bluetooth izni gerekiyor. Uygulama ayarlarından izin verin.',
              style: TextStyle(
                  fontFamily: 'Roboto', fontSize: 12, color: _scheme.primary),
            ),
          ),
          TextButton(
            onPressed: openAppSettings,
            child: Text('Ayarlar',
                style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _emptyPrinter() => Text('Yazıcı seçilmedi',
      style: TextStyle(fontSize: 12, color: _scheme.onSurfaceVariant));

  Widget _savedPrinterCard() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_savedName ?? 'Yazıcı',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text(_savedMac ?? '',
                    style: TextStyle(
                        fontSize: 11, color: _scheme.onSurfaceVariant))
              ])),
          Text(_isConnected ? 'Bağlı' : 'Bağlı Değil',
              style: TextStyle(fontSize: 11, color: _scheme.onSurfaceVariant)),
          PopupMenuButton<String>(
              tooltip: 'Yazıcı İşlemleri',
              onSelected: (_) => _removePrinter(),
              itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'remove', child: Text('Yazıcıyı Kaldır'))
                  ]),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          OutlinedButton.icon(
              onPressed: _isConnecting
                  ? null
                  : _isConnected
                      ? _disconnect
                      : _connect,
              icon: const Icon(Icons.bluetooth_rounded, size: 16),
              label: Text(_isConnecting
                  ? 'Bağlanıyor'
                  : _isConnected
                      ? 'Bağlantıyı Kes'
                      : 'Bağlan')),
          TextButton.icon(
              onPressed: _isConnected && !_isPrinting ? _testPrint : null,
              icon: const Icon(Icons.print_outlined, size: 16),
              label: Text(_isPrinting ? 'Yazdırılıyor' : 'Test Yazdır')),
        ]),
      ]);

  Widget _pairedList() {
    if (_isLoadingDevices) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: _kRed, strokeWidth: 2),
        ),
      );
    }

    if (_pairedDevices.isEmpty)
      return Text('Eşleştirilmiş cihaz yok',
          style: TextStyle(fontSize: 12, color: _scheme.onSurfaceVariant));

    return Column(
      children: _pairedDevices.map((device) {
        final isSelected = device.macAdress == _savedMac;
        return InkWell(
          onTap: () => _selectDevice(device),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? _kRed.withOpacity(0.06)
                  : _scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? _kRed.withOpacity(0.3)
                    : _scheme.outlineVariant,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kRed.withOpacity(0.1)
                        : _scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const CorporateMenuIcon('Bluetooth', size: 26),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name.isNotEmpty
                            ? device.name
                            : 'Bilinmeyen Cihaz',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? _kRed : _kDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        device.macAdress,
                        style: TextStyle(
                          fontSize: 11,
                          color: _scheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Seçili',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kRed,
                      ),
                    ),
                  )
                else
                  Icon(Icons.chevron_right_rounded,
                      color: _scheme.outlineVariant, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) => Material(
        color: onTap != null
            ? _kRed.withOpacity(0.08)
            : _scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon,
                size: 18,
                color: onTap != null ? _kRed : _scheme.onSurfaceVariant),
          ),
        ),
      );

  Widget _sectionCard(
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
                CorporateMenuIcon(title, size: 25, fallback: icon),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(title,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kDark)))
              ]),
              const SizedBox(height: 8),
              child,
            ])),
      );
}
