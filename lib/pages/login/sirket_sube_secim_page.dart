import 'package:FilERP/widgets/permission_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/entities/yonetim/sirket_dto.dart';
import '../../models/entities/yonetim/sube_dto.dart';
import '../../models/entities/yonetim/kullanici_dto.dart';
import '../../services/login/login_service.dart';
import '../../services/update/update_service.dart';
import '../home_page.dart';
import 'login_page.dart';
import '../../widgets/erp_auth_layout.dart';
import '../../services/offline/offline_service.dart';

class SirketSubeSecimPage extends StatefulWidget {
  final List<SirketDto> sirketler;
  final List<SubeDto> subeler;
  final KullaniciDto kullaniciDetay;
  final bool switchBranch;
  final int? initialCompanyId, initialBranchId;

  const SirketSubeSecimPage({
    super.key,
    required this.sirketler,
    required this.subeler,
    required this.kullaniciDetay,
    this.switchBranch = false,
    this.initialCompanyId,
    this.initialBranchId,
  });

  @override
  State<SirketSubeSecimPage> createState() => _SirketSubeSecimPageState();
}

class _SirketSubeSecimPageState extends State<SirketSubeSecimPage> {
  ColorScheme get _scheme => ErpAuthLayout.themeFor(context).colorScheme;
  SirketDto? seciliSirket;
  SubeDto? seciliSube;
  bool isLoading = false;
  List<SubeDto> filtreliSubeler = [];

  @override
  void initState() {
    super.initState();
    baslangicAyarla();
  }

  void baslangicAyarla() {
    seciliSirket = widget.sirketler
            .where((s) => s.id == widget.initialCompanyId)
            .firstOrNull ??
        widget.sirketler.firstOrNull;

    filtreliSubeler =
        widget.subeler.where((x) => x.sirketId == seciliSirket?.id).toList();

    seciliSube = filtreliSubeler
            .where((s) => s.id == widget.initialBranchId)
            .firstOrNull ??
        filtreliSubeler.firstOrNull;

    setState(() {});
  }

  void sirketDegisti(SirketDto yeni) {
    seciliSirket = yeni;

    filtreliSubeler =
        widget.subeler.where((x) => x.sirketId == yeni.id).toList();

    seciliSube = filtreliSubeler.isNotEmpty ? filtreliSubeler.first : null;

    setState(() {});
  }

  Future<void> devamEt() async {
    if (isLoading) return;
    if (seciliSirket == null || seciliSube == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen şirket ve şube seçin.")),
      );
      return;
    }

    if (widget.switchBranch &&
        seciliSirket!.id == widget.initialCompanyId &&
        seciliSube!.id == widget.initialBranchId) {
      Navigator.pop(context);
      return;
    }
    if (OfflineService.instance.isSyncing.value) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kayıtlar gönderiliyor. Bitince tekrar deneyin.')));
      return;
    }
    setState(() => isLoading = true);

    try {
      final service = LoginService();
      final result = await service.loginSirketSube(
        seciliSirket!.id!,
        seciliSube!.id!,
      );

      if (result == null ||
          result["Data"] == null ||
          result["Data"]["Token"] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Şube girişi başarısız.")),
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token_final", result["Data"]["Token"]);
      await prefs.setString("firma_adi", widget.kullaniciDetay.firma?.ad ?? "");
      await prefs.setString("sirket_adi", seciliSirket?.ad ?? "");
      await prefs.setString("sube_adi", seciliSube?.ad ?? "");
      await prefs.setString(
          "kullanici_adi", widget.kullaniciDetay.kullaniciAdi ?? "");

      if (!mounted) return;

      if (widget.switchBranch) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            PermissionMaterialPageRoute(builder: (_) => const HomePage()),
            (_) => false);
        return;
      }

      // ── Güncelleme kontrolü (arka planda, hata olursa sessizce geç) ───────
      UpdateInfo? updateInfo;
      try {
        updateInfo = await UpdateService.instance
            .checkForUpdate()
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        // Ağ hatası veya timeout — güncelleme kontrolünü atla
      }

      if (!mounted) return;

      // Güncelleme varsa kullanıcıya sor
      if (updateInfo != null) {
        final userWantsUpdate = await _showUpdateDialog(updateInfo);
        if (userWantsUpdate == true) {
          UpdateService.instance.pendingAutoInstall = updateInfo;
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PermissionMaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.switchBranch
                ? 'Şube değiştirilemedi. Tekrar deneyin.'
                : 'Şube girişi başarısız.')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _girisEkraninaDon() {
    if (widget.switchBranch) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      PermissionMaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<bool?> _showUpdateDialog(UpdateInfo info) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Theme(
          data: ErpAuthLayout.themeFor(context),
          child: Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _scheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.system_update_rounded,
                        color: _scheme.primary, size: 30),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Yeni Versiyon Mevcut",
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _scheme.onSurface),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "v${info.versionName} sürümü hazır.",
                    style: TextStyle(
                        fontSize: 13, color: _scheme.onSurfaceVariant),
                  ),
                  if (info.releaseNotes.isNotEmpty) ...[
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _scheme.primary.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        info.releaseNotes,
                        style: TextStyle(
                            fontSize: 12, color: _scheme.primary, height: 1.5),
                      ),
                    ),
                  ],
                  SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _scheme.onSurfaceVariant,
                          side: BorderSide(color: _scheme.onSurfaceVariant),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text("Şimdi Değil"),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _scheme.primary,
                          foregroundColor: _scheme.onPrimary,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text("Güncelle",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          )),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !isLoading,
      child: Theme(
          data: ErpAuthLayout.themeFor(context),
          child: ErpAuthLayout(
            footer: TextButton.icon(
                onPressed: isLoading ? null : _girisEkraninaDon,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text(widget.switchBranch ? 'Vazgeç' : 'Giriş Ekranı')),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Şirket ve Şube',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _scheme.onSurface)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SirketDto>(
                      value: seciliSirket,
                      isExpanded: true,
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: _scheme.onSurface),
                      decoration: const InputDecoration(
                          labelText: 'Şirket',
                          isDense: true,
                          prefixIcon: Icon(Icons.business_outlined, size: 20)),
                      items: widget.sirketler
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.ad ?? 'Şirket',
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: isLoading
                          ? null
                          : (s) {
                              if (s != null) sirketDegisti(s);
                            }),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SubeDto>(
                      value: seciliSube,
                      isExpanded: true,
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: _scheme.onSurface),
                      decoration: const InputDecoration(
                          labelText: 'Şube',
                          isDense: true,
                          prefixIcon: Icon(Icons.store_outlined, size: 20)),
                      items: filtreliSubeler
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.ad ?? 'Şube',
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: isLoading
                          ? null
                          : (s) => setState(() => seciliSube = s)),
                  const SizedBox(height: 20),
                  FilledButton(
                      onPressed: isLoading ? null : devamEt,
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(widget.switchBranch
                              ? 'Şubeyi Değiştir'
                              : 'Devam Et')),
                ]),
          )));
}
