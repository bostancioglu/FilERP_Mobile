import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../theme/app_theme.dart';
import '../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../widgets/erp_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/ui_feedback.dart';
import '../../models/entities/stok/stok_dto.dart';
import '../../models/entities/stok/stokolcubr_dto.dart';
import '../../services/stok/barcode_print_service.dart';
import '../../services/stok/stok_service.dart';
import '../../models/yazici/yazici_sablon.dart';
import '../../services/yazici/bluetooth_print_service.dart';
import '../../services/yazici/yazici_sablon_service.dart';
import 'stok_ekle_page.dart';

enum _PrintMethod { pdf, bluetooth }

class StokDetayPage extends StatefulWidget {
  final int stokId;

  const StokDetayPage({
    super.key,
    required this.stokId,
  });

  @override
  State<StokDetayPage> createState() => _StokDetayPageState();
}

class _StokDetayPageState extends State<StokDetayPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _accent => _scheme.primary;
  Color get _ink => _scheme.onSurface;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;

  StokDto? stok;
  bool loading = true;
  bool deleting = false;
  bool printing = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadStok();
  }

  Future<void> _loadStok() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final result = await StokService().getStokFullById(token, widget.stokId);

      if (!mounted) return;

      setState(() {
        stok = result;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'Stok bilgileri alınamadı';
        loading = false;
      });
    }
  }

  Future<void> _editStok() async {
    final result = await Navigator.push<bool>(
      context,
      PermissionMaterialPageRoute(
        builder: (_) => StokEklePage(editStok: stok),
      ),
    );

    if (result == true && mounted) {
      await _loadStok();
    }
  }

  Future<void> _deleteStok() async {
    final ok = await UiFeedback.confirm(
      context,
      title: 'Stok Sil',
      message: 'Bu stok silinecek. Bu işlem geri alınamaz.',
      confirmLabel: 'Sil',
      destructive: true,
    );

    if (!ok) return;
    if (!mounted) return;

    setState(() => deleting = true);

    try {
      final navigator = Navigator.of(context);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';

      await StokService().deleteStok(token, widget.stokId);

      if (!mounted) return;

      await UiFeedback.showSuccess(context, 'Stok başarıyla silindi');
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      await UiFeedback.showError(
        context,
        e.toString().replaceFirst('Exception:', '').trim(),
      );
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  void _showIslemlerMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'İşlemler',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _scheme.onSurfaceVariant,
              ),
            ),
          ),
          _menuItem(
            Icons.print_rounded,
            'Barkod Yazdır',
            Colors.orange.shade700,
            () {
              Navigator.pop(context);
              _showBarkodYazdirSheet();
            },
            enabled: !printing,
            trailing: printing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          _menuItem(
            Icons.edit_outlined,
            'Stoğu Düzenle',
            Colors.blue.shade700,
            () {
              Navigator.pop(context);
              _editStok();
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _menuItem(
            Icons.delete_outline_rounded,
            'Stoğu Sil',
            Colors.red.shade700,
            () {
              Navigator.pop(context);
              _deleteStok();
            },
            enabled: !deleting,
            trailing: deleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _showBarkodYazdirSheet() async {
    final currentStok = stok;
    if (currentStok == null) return;

    final barcodeOptions = _barcodeOptions(currentStok);
    if (barcodeOptions.isEmpty) {
      await UiFeedback.showWarning(
          context, 'Bu stok için yazdırılabilir barkod bulunamadı.');
      return;
    }

    final adetController = TextEditingController(text: '1');
    var selected = barcodeOptions.first;
    var printMethod = _PrintMethod.pdf;
    bool btConnected = await BluetoothPrintService.instance.isConnected;
    final btName = await BluetoothPrintService.instance.getSavedName();
    final sablonlar = await YaziciSablonService.instance.getSablonlar();
    final kagitEni = await YaziciSablonService.instance.getKagitEni();
    final satirGen = await YaziciSablonService.instance.getSatirGenisligi();
    YaziciSablon? secilenSablon = sablonlar.isNotEmpty ? sablonlar.first : null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final mq = MediaQuery.of(ctx);
            return Padding(
              padding:
                  EdgeInsets.fromLTRB(20, 0, 20, mq.viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Başlık ──
                  const Text('Barkod Yazdır',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${currentStok.Kod ?? '-'} — ${currentStok.Ad ?? '-'}',
                      style: TextStyle(
                          fontSize: 13, color: _scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),

                  const SizedBox(height: 16),

                  // ── Yazıcı seçimi ──
                  Row(children: [
                    Expanded(
                      child: _methodBtn(
                        icon: Icons.picture_as_pdf_outlined,
                        label: 'PDF / Sistem',
                        selected: printMethod == _PrintMethod.pdf,
                        onTap: () =>
                            setModal(() => printMethod = _PrintMethod.pdf),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _methodBtn(
                        icon: Icons.bluetooth_rounded,
                        label: btName != null
                            ? btName.length > 14
                                ? '${btName.substring(0, 14)}…'
                                : btName
                            : 'Bluetooth',
                        selected: printMethod == _PrintMethod.bluetooth,
                        connected: btConnected,
                        onTap: () => setModal(
                            () => printMethod = _PrintMethod.bluetooth),
                      ),
                    ),
                  ]),

                  // BT bağlı değilse uyarı
                  if (printMethod == _PrintMethod.bluetooth && !btConnected)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            btName == null
                                ? 'Yazıcı Ayarları\'ndan önce bir yazıcı kaydedin.'
                                : 'Yazıcı bağlı değil. "Bağlan" tuşuna basın.',
                            style: TextStyle(
                                fontSize: 11, color: Colors.orange.shade800),
                          ),
                        ),
                      ]),
                    ),

                  const SizedBox(height: 14),

                  // ── Şablon seçimi (sadece Bluetooth modunda) ──
                  if (printMethod == _PrintMethod.bluetooth &&
                      sablonlar.isNotEmpty) ...[
                    DropdownButtonFormField<YaziciSablon>(
                      value: secilenSablon,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Şablon',
                        prefixIcon: Icon(Icons.receipt_long_outlined,
                            size: 18, color: _scheme.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                      ),
                      items: sablonlar
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child:
                                  Text(s.ad, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModal(() => secilenSablon = v);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Barkod seçimi ──
                  DropdownButtonFormField<_BarcodeOption>(
                    initialValue: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Ölçü Birimi / Barkod',
                        border: OutlineInputBorder()),
                    items: barcodeOptions
                        .map((o) => DropdownMenuItem(
                              value: o,
                              child: Text('${o.olcuBirimi} • ${o.barkod}',
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModal(() => selected = v);
                    },
                  ),

                  const SizedBox(height: 12),

                  // ── Adet ──
                  TextField(
                    controller: adetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Adet', border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 16),

                  // ── Yazdır butonu ──
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: printMethod == _PrintMethod.bluetooth
                            ? Colors.blue.shade700
                            : _accent,
                      ),
                      onPressed: () async {
                        final adet =
                            int.tryParse(adetController.text.trim()) ?? 0;
                        if (adet <= 0) {
                          await UiFeedback.showWarning(
                              ctx, 'Lütfen geçerli bir adet girin.');
                          return;
                        }
                        if (printMethod == _PrintMethod.bluetooth &&
                            !btConnected) {
                          await UiFeedback.showWarning(
                              ctx, 'Bluetooth yazıcı bağlı değil.');
                          return;
                        }
                        Navigator.pop(sheetContext);
                        if (printMethod == _PrintMethod.bluetooth) {
                          await _printBarcodeViaBluetooth(
                            barkod: selected.barkod,
                            olcuBirimi: selected.olcuBirimi,
                            adet: adet,
                            sablon: secilenSablon,
                            kagitEni: kagitEni,
                            satirGen: satirGen,
                          );
                        } else {
                          await _printBarcode(
                            barkod: selected.barkod,
                            olcuBirimi: selected.olcuBirimi,
                            adet: adet,
                          );
                        }
                      },
                      icon: Icon(printMethod == _PrintMethod.bluetooth
                          ? Icons.bluetooth_rounded
                          : Icons.print_rounded),
                      label: Text(printMethod == _PrintMethod.bluetooth
                          ? 'Bluetooth\'a Yazdır'
                          : 'Yazdır / Paylaş'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _methodBtn({
    required IconData icon,
    required String label,
    required bool selected,
    bool connected = true,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withValues(alpha: 0.08)
              : _scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _accent : _scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: selected ? _accent : _scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    color: selected ? _accent : _scheme.onSurfaceVariant,
                  )),
            ),
            if (!connected && icon == Icons.bluetooth_rounded) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: Colors.orange, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _printBarcodeViaBluetooth({
    required String barkod,
    required String olcuBirimi,
    required int adet,
    YaziciSablon? sablon,
    int kagitEni = 80,
    int? satirGen,
  }) async {
    final currentStok = stok;
    if (currentStok == null) return;
    setState(() => printing = true);
    try {
      bool ok;
      if (sablon != null) {
        ok = await BluetoothPrintService.instance.printWithTemplate(
          sablon: sablon,
          stokAd: currentStok.Ad ?? '',
          stokKod: currentStok.Kod ?? '',
          barkod: barkod,
          olcuBirimi: olcuBirimi,
          adet: adet,
          kagitEniMm: kagitEni,
          satirGenisligi: satirGen,
        );
      } else {
        ok = await BluetoothPrintService.instance.printBarkodLabel(
          stokAd: currentStok.Ad ?? '',
          stokKod: currentStok.Kod ?? '',
          barkod: barkod,
          olcuBirimi: olcuBirimi,
          adet: adet,
        );
      }
      if (!mounted) return;
      if (ok) {
        await UiFeedback.showSuccess(context, 'Barkod yazıcıya gönderildi');
      } else {
        await UiFeedback.showError(context, 'Bluetooth yazıcıya gönderilemedi');
      }
    } catch (e) {
      if (!mounted) return;
      await UiFeedback.showError(
          context, e.toString().replaceFirst('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => printing = false);
    }
  }

  Future<void> _printBarcode({
    required String barkod,
    required String olcuBirimi,
    required int adet,
  }) async {
    final currentStok = stok;
    if (currentStok == null) return;

    setState(() => printing = true);
    try {
      await BarcodePrintService.printLabels(
        stok: currentStok,
        barkod: barkod,
        olcuBirimi: olcuBirimi,
        adet: adet,
      );

      if (!mounted) return;
      await UiFeedback.showSuccess(context, 'Barkodlar yazdırıldı');
    } catch (_) {
      try {
        await BarcodePrintService.shareLabels(
          stok: currentStok,
          barkod: barkod,
          olcuBirimi: olcuBirimi,
          adet: adet,
        );

        if (!mounted) return;
        await UiFeedback.showInfo(
          context,
          'Yazdırma başarısız, PDF paylaşılacak.',
        );
      } catch (e) {
        if (!mounted) return;
        await UiFeedback.showError(
          context,
          e.toString().replaceFirst('Exception:', '').trim(),
        );
      }
    } finally {
      if (mounted) setState(() => printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: _background,
        appBar: ErpPageAppBar(
          context: context,
          title: const Text('Stok Detay'),
          backgroundColor: _scheme.surface,
          foregroundColor: _ink,
        ),
        body: Center(child: Text(error!)),
      );
    }

    if (stok == null) {
      return Scaffold(
        backgroundColor: _background,
        body: const Center(child: Text('Stok bulunamadı')),
      );
    }

    final s = stok!;
    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        slivers: [
          ErpDetailHeader(
            pageTitle: 'Stok Detay',
            title: s.Ad ?? 'Adsız Stok',
            code: s.Kod ?? '',
            icon: Icons.inventory_2_outlined,
            actions: [
              PermissionAction(
                  modules: [101],
                  access: Access.update,
                  child: IconButton(
                      tooltip: 'Düzenle',
                      onPressed: _editStok,
                      icon: const Icon(Icons.edit_outlined, size: 21))),
              IconButton(
                  tooltip: 'Stok işlemleri',
                  onPressed: _showIslemlerMenu,
                  icon: const Icon(Icons.more_horiz_rounded)),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'Genel Bilgiler',
                    rows: [
                      _InfoRow('Stok Kodu', s.Kod),
                      _InfoRow('Stok Adı', s.Ad),
                      _InfoRow('Yabancı Ad', s.Yabanciad),
                    ],
                  ),
                  if (s.Stokolcubr.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _olcuBirimleriCard(s),
                  ],
                  const SizedBox(height: 14),
                  _sectionCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Vergiler',
                    rows: [
                      _InfoRow('KDV Alış', _percent(s.Kdvalis)),
                      _InfoRow('KDV Satış', _percent(s.Kdvsatis)),
                      _InfoRow('Tevkifat', _percent(s.Tevkifatorani)),
                    ],
                  ),
                  if (s.Stokbarkod.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _barkodlarCard(s),
                  ],
                  if (s.Stokfiyat.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _fiyatlarCard(s),
                  ],
                  const SizedBox(height: 14),
                  _sectionCard(
                    icon: Icons.category_outlined,
                    title: 'Gruplama & Kodlar',
                    rows: [
                      _InfoRow('Kategori', s.Stokkategori?.Ad),
                      _InfoRow('Grup Kodu', s.Grupkodu),
                      _InfoRow('Kod 1', s.Kod1),
                      _InfoRow('Kod 2', s.Kod2),
                      _InfoRow('Kod 3', s.Kod3),
                      _InfoRow('Kod 4', s.Kod4),
                      _InfoRow('Kod 5', s.Kod5),
                    ],
                  ),
                  if (_hasAciklama(s)) ...[
                    const SizedBox(height: 14),
                    _sectionCard(
                      icon: Icons.notes_rounded,
                      title: 'Açıklamalar',
                      rows: [
                        _InfoRow('Açıklama 1', s.Aciklama1),
                        _InfoRow('Açıklama 2', s.Aciklama2),
                        _InfoRow('Açıklama 3', s.Aciklama3),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<_InfoRow> rows,
  }) {
    final visible =
        rows.where((r) => r.value != null && r.value!.isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: _scheme.surface,
        border:
            Border.all(color: _scheme.outlineVariant.withValues(alpha: .45)),
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: _accent),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _scheme.surfaceContainerLow),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children:
                  visible.map((r) => _buildRow(r.label, r.value)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value ?? '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _olcuBirimleriCard(StokDto s) {
    return Container(
      decoration: BoxDecoration(
        color: _scheme.surface,
        border:
            Border.all(color: _scheme.outlineVariant.withValues(alpha: .45)),
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.straighten_rounded, size: 16, color: _accent),
                ),
                const SizedBox(width: 10),
                Text(
                  'Ölçü Birimleri',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _scheme.surfaceContainerLow),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: s.Stokolcubr.map((o) {
                final isDefault = o == _defaultOlcu(s.Stokolcubr);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            Text(
                              o.Olcubr?.Ad ?? '-',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isDefault
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color:
                                    isDefault ? _ink : _scheme.onSurfaceVariant,
                              ),
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Varsayılan',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          _olcuDetay(o),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barkodlarCard(StokDto s) {
    return Container(
      decoration: BoxDecoration(
        color: _scheme.surface,
        border:
            Border.all(color: _scheme.outlineVariant.withValues(alpha: .45)),
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.qr_code_rounded, size: 16, color: _accent),
                ),
                const SizedBox(width: 10),
                Text(
                  'Barkodlar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _scheme.surfaceContainerLow),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: s.Stokbarkod.map((b) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          b.Olcubr?.Ad ?? 'Barkod',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Text(
                          b.Barkod ?? '-',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fiyatlarCard(StokDto s) {
    return Container(
      decoration: BoxDecoration(
        color: _scheme.surface,
        border:
            Border.all(color: _scheme.outlineVariant.withValues(alpha: .45)),
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.attach_money_rounded,
                      size: 16, color: _accent),
                ),
                const SizedBox(width: 10),
                Text(
                  'Fiyatlar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _scheme.surfaceContainerLow),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: () {
                final widgets = <Widget>[];
                for (int i = 0; i < s.Stokfiyat.length; i++) {
                  final f = s.Stokfiyat[i];
                  if (i > 0) {
                    widgets.add(Divider(
                        height: 16, color: _scheme.surfaceContainerLow));
                  }
                  if (f.Doviz?.Birim != null)
                    widgets.add(_buildRow('Döviz', f.Doviz?.Birim));
                  if (f.Alisfiyat != null)
                    widgets
                        .add(_buildRow('Alış Fiyatı', f.Alisfiyat?.toString()));
                  if (f.Satisfiyat != null)
                    widgets.add(
                        _buildRow('Satış Fiyatı', f.Satisfiyat?.toString()));
                }
                return widgets;
              }(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap, {
    bool enabled = true,
    Widget? trailing,
  }) {
    if (!ActionAccess.allowed([101], title)) return const SizedBox.shrink();

    return ListTile(
      enabled: enabled,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
          fontSize: 14,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: _scheme.outlineVariant,
            size: 20,
          ),
      onTap: enabled ? onTap : null,
    );
  }

  List<_BarcodeOption> _barcodeOptions(StokDto currentStok) {
    final options = <_BarcodeOption>[];
    final seen = <String>{};

    for (final barkod in currentStok.Stokbarkod) {
      final value = barkod.Barkod?.trim();
      if (value == null || value.isEmpty) continue;

      final label = barkod.Olcubr?.Ad?.trim() ??
          _olcuAdiById(currentStok, barkod.Olcubrid) ??
          'Varsayılan';
      final key = '$label|$value';

      if (seen.add(key)) {
        options.add(
          _BarcodeOption(
            barkod: value,
            olcuBirimi: label,
          ),
        );
      }
    }

    if (options.isEmpty) {
      final kod = currentStok.Kod?.trim();
      if (kod != null && kod.isNotEmpty) {
        options.add(
          _BarcodeOption(
            barkod: kod,
            olcuBirimi: currentStok.Stokolcubr.isNotEmpty
                ? (_defaultOlcu(currentStok.Stokolcubr).Olcubr?.Ad ??
                    'Varsayılan')
                : 'Varsayılan',
          ),
        );
      }
    }

    return options;
  }

  String? _olcuAdiById(StokDto currentStok, int? olcuBrId) {
    if (olcuBrId == null) return null;
    for (final olcu in currentStok.Stokolcubr) {
      if (olcu.Olcubrid == olcuBrId) {
        return olcu.Olcubr?.Ad;
      }
    }
    return null;
  }

  String _percent(double? value) {
    if (value == null) return '';
    return '%${(value * 100).toStringAsFixed(0)}';
  }

  String _olcuDetay(StokolcubrDto o) {
    final parts = <String>[];
    if (o.Pay != null && o.Payda != null) {
      parts.add('${o.Pay}/${o.Payda}');
    }
    if (o.Carpim != null) {
      parts.add('Çarpım: ${o.Carpim}');
    }
    return parts.isEmpty ? '-' : parts.join('  •  ');
  }

  StokolcubrDto _defaultOlcu(List<StokolcubrDto> list) {
    return list.firstWhere(
      (x) => x.Sira == 1,
      orElse: () => list.first,
    );
  }

  bool _hasAciklama(StokDto s) {
    return (s.Aciklama1 != null && s.Aciklama1!.isNotEmpty) ||
        (s.Aciklama2 != null && s.Aciklama2!.isNotEmpty) ||
        (s.Aciklama3 != null && s.Aciklama3!.isNotEmpty);
  }
}

class _InfoRow {
  final String label;
  final String? value;
  const _InfoRow(this.label, this.value);
}

class _BarcodeOption {
  final String barkod;
  final String olcuBirimi;

  const _BarcodeOption({
    required this.barkod,
    required this.olcuBirimi,
  });
}
