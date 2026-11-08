import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../theme/app_theme.dart';
import '../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../widgets/erp_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/entities/cari/cari_dto_full.dart';
import '../../models/entities/cari/cari_dto.dart';
import '../../services/cari/cari_service.dart';
import '../../helpers/ui_feedback.dart';
import 'cari_ekle_page.dart';

class CariDetayPage extends StatefulWidget {
  final int cariId;
  const CariDetayPage({super.key, required this.cariId});

  @override
  State<CariDetayPage> createState() => _CariDetayPageState();
}

class _CariDetayPageState extends State<CariDetayPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _accent => _scheme.primary;
  Color get _ink => _scheme.onSurface;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;

  CariDtoFull? cari;
  bool loading = true;
  String? error;
  bool deleting = false;

  @override
  void initState() {
    super.initState();
    _loadCari();
  }

  Future<void> _loadCari() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final result = await CariService().getCariFullById(token, widget.cariId);
      if (!mounted) return;
      setState(() {
        cari = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "Cari bilgileri alınamadı";
        loading = false;
      });
    }
  }

  CariDto _toEditDto(CariDtoFull c) => c.toEditDto();

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    if (error != null || cari == null) {
      return Scaffold(
        backgroundColor: _background,
        appBar: ErpPageAppBar(
          context: context,
          backgroundColor: _scheme.surface,
          foregroundColor: _ink,
          elevation: 0,
          title: const Text("Cari Detay"),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 56, color: _scheme.outlineVariant),
              const SizedBox(height: 16),
              Text(error ?? "Cari bulunamadı",
                  style: TextStyle(color: _scheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadCari,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Tekrar dene"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _infoCard("Temel Bilgiler", Icons.badge_outlined, [
                  _row(Icons.tag_rounded, "Cari Kodu", cari!.Kod),
                  _row(Icons.business_outlined, "Cari Ünvan", cari!.Ad),
                  _row(Icons.receipt_long_outlined, "Vergi No", cari!.Vergino),
                  _row(Icons.account_balance_outlined, "Vergi Dairesi",
                      cari!.Vergidairesi),
                  _row(Icons.credit_card_outlined, "TC Kimlik", cari!.Tckimlik),
                ]),
                const SizedBox(height: 12),
                _infoCard("Adres", Icons.location_on_outlined, [
                  _row(Icons.flag_outlined, "Ülke", cari!.Ulke?.Ad),
                  _row(Icons.location_city_outlined, "İl", cari!.Il?.Ad),
                  _row(Icons.location_on_outlined, "İlçe", cari!.Ilce?.Ad),
                  _row(Icons.home_outlined, "Açık Adres", cari!.Adres,
                      multiline: true),
                  _row(Icons.map_outlined, "Bölge", cari!.Bolge),
                ]),
                const SizedBox(height: 12),
                _infoCard("İletişim", Icons.phone_outlined, [
                  _row(Icons.business_outlined, "Kurumsal Tel",
                      cari!.Kurumsaltel),
                  _row(Icons.smartphone_outlined, "Yetkili Mobil",
                      cari!.Yetkilimobil),
                ]),
                const SizedBox(height: 12),
                _infoCard("Ticari Koşullar", Icons.handshake_outlined, [
                  _row(Icons.calendar_today_outlined, "Vade Günü",
                      cari!.Vadegunu?.toString()),
                  _row(
                      Icons.percent_rounded,
                      "İskonto Oranı",
                      cari!.Iskontoorani != null
                          ? "%${cari!.Iskontoorani!.toStringAsFixed(2)}"
                          : null),
                  _row(Icons.currency_exchange_rounded, "Döviz",
                      cari!.Doviz?.Birim),
                  _row(Icons.person_outlined, "Plasiyer",
                      cari!.Plasiyer?.Adsoyad),
                  _row(Icons.category_outlined, "Kategori",
                      cari!.Carikategori?.Ad),
                ]),
                if (_hasRaporData()) ...[
                  const SizedBox(height: 12),
                  _infoCard("Kodlar & Gruplama", Icons.label_outline_rounded, [
                    _row(Icons.folder_outlined, "Grup Kodu", cari!.Grupkodu),
                    _row(Icons.tag_rounded, "Kod 1", cari!.Kod1),
                    _row(Icons.tag_rounded, "Kod 2", cari!.Kod2),
                    _row(Icons.tag_rounded, "Kod 3", cari!.Kod3),
                    _row(Icons.tag_rounded, "Kod 4", cari!.Kod4),
                    _row(Icons.tag_rounded, "Kod 5", cari!.Kod5),
                  ]),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasRaporData() => [
        cari!.Grupkodu,
        cari!.Kod1,
        cari!.Kod2,
        cari!.Kod3,
        cari!.Kod4,
        cari!.Kod5
      ].any((v) => v != null && v.isNotEmpty);

  Widget _buildSliverHeader() => ErpDetailHeader(
        pageTitle: 'Cari Detay',
        title: cari!.Ad ?? 'Adsız Cari',
        code: cari!.Kod ?? '',
        icon: Icons.business_outlined,
        actions: [
          PermissionAction(
              modules: [201],
              access: Access.update,
              child: IconButton(
                  tooltip: 'Düzenle',
                  icon: const Icon(Icons.edit_outlined, size: 21),
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                        context,
                        PermissionMaterialPageRoute(
                            builder: (_) =>
                                CariEklePage(editCari: _toEditDto(cari!))));
                    if (result == true && mounted) await _loadCari();
                  })),
          PermissionAction(
              modules: [201],
              access: Access.delete,
              child: IconButton(
                  tooltip: 'Sil',
                  onPressed: deleting ? null : _confirmAndDelete,
                  icon: deleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.delete_outline_rounded,
                          size: 21, color: _scheme.error))),
        ],
      );

  Widget _infoCard(String title, IconData icon, List<Widget> rows) {
    // Boş satırları filtrele (value null veya boş olanlar)
    final visibleRows = rows
        .whereType<_InfoRow>()
        .where((r) => r.value != null && r.value!.isNotEmpty)
        .toList();
    if (visibleRows.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: _scheme.surface,
        border:
            Border.all(color: _scheme.outlineVariant.withValues(alpha: .45)),
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  width: 30,
                  height: 30,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: _scheme.surfaceContainerLow, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: visibleRows.map((r) => _buildRow(r)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_InfoRow r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment:
            r.multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(r.icon, size: 15, color: _scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              r.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              r.value ?? "-",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
              textAlign: TextAlign.right,
              maxLines: r.multiline ? 4 : 1,
              overflow:
                  r.multiline ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  _InfoRow _row(IconData icon, String label, String? value,
      {bool multiline = false}) {
    return _InfoRow(
        icon: icon, label: label, value: value, multiline: multiline);
  }

  Future<void> _confirmAndDelete() async {
    final ok = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: _accent, size: 22),
                const SizedBox(width: 8),
                const Text("Cari Sil", style: TextStyle(fontSize: 17)),
              ],
            ),
            content: Text(
              "\"${cari!.Ad ?? 'Bu cari'}\" kaydını silmek istediğinize emin misiniz?\nBu işlem geri alınamaz.",
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              ErpDialogAction(
                secondary: true,
                onPressed: () => Navigator.pop(context, false),
                child: Text("Vazgeç",
                    style: TextStyle(color: _scheme.onSurfaceVariant)),
              ),
              PermissionAction(
                  modules: [201],
                  access: Access.delete,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: _scheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Sil"),
                  )),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    setState(() => deleting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await CariService().deleteCari(token, widget.cariId);
      if (!mounted) return;
      await UiFeedback.showSuccess(context, "Cari hesap başarıyla silindi");
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      await UiFeedback.showError(
          context, e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }
}

// Yardımcı veri sınıfı — _infoCard içinde tip güvenli filtreleme için
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool multiline;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
