import '../widgets/admin_dashboard_button.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:FilERP/widgets/corporate_menu_icon.dart';
import '../widgets/erp_module_menu.dart';
import '../theme/theme_controller.dart';
import 'ana_sayfa_yeni_tasarim_page.dart';
import 'teklif/teklif_list_page.dart';
import 'package:flutter/material.dart';
import '../widgets/mobile_dashboard.dart';
import 'package:flutter/services.dart';
import '../helpers/ui_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/offline/offline_service.dart';
import '../services/update/update_service.dart';
import '../services/plasiyer/plasiyer_konum_broadcaster.dart';
import 'ayarlar/ayarlar_page.dart';
import 'login/login_page.dart';
import 'login/sirket_sube_secim_page.dart';
import '../services/login/login_service.dart';
import 'cari/cari_list_page.dart';
import 'stok/stok_list_page.dart';
import 'fatura/Satisfaturasi/satisfatura_list.dart';
import 'fatura/Alisfaturasi/alisfatura_list.dart';
import 'depo/dat/dat_list_page.dart';
import 'irsaliye/irsaliye_list_page.dart';
import 'irsaliye/Alis/alisirsaliye_list.dart';
import 'siparis/Satis/satissiparis_list.dart';
import 'depo/ambargc/ambargc_list.dart';
import 'rapor/rapor_merkezi_page.dart';
import 'siparis/Alis/alissiparis_list.dart';
import 'ayarlar/yazici_ayarlar_page.dart';
import 'finans/kasa/kasa_islem_list_page.dart';
import 'finans/kasa/kasahareket_ekle_page.dart';
import '../helpers/kullanici_plasiyer_helper.dart';
import 'finans/kasa/kasa_tanim_list_page.dart';
import 'rapor/kasa/kasa_sondurum_raporu.dart';
import 'finans/banka/banka_tanim_list_page.dart';
import 'finans/banka/banka_islem_list_page.dart';
import 'finans/cek/cekalinan_liste_page.dart';
// import 'finans/cek/cekalinanciro_liste_page.dart';
// import 'finans/cek/cekalinantahsil_liste_page.dart';
// import 'finans/cek/cekalinanprotesto_liste_page.dart';
// import 'finans/cek/cekalinaniade_liste_page.dart';
// import 'finans/cek/cekalinanportfoydentahsil_liste_page.dart';
import 'finans/cek/cekalinan_rapor_page.dart';
import '../services/finans/vw_finanscekalinan_service.dart';
import 'finans/borc/cekverilen_liste_page.dart';
// import 'finans/borc/cekverilenodeme_liste_page.dart';
// import 'finans/borc/cekverileniade_liste_page.dart';
import 'finans/borc/cekverilen_rapor_genel_page.dart';
import 'finans/tahsilat/tahsilat_liste_page.dart';
import 'finans/borc/cekverilen_rapor_odenecek_page.dart';
import 'finans/senet/senetalinan_liste_page.dart';
import 'finans/senet/senetalinan_rapor_page.dart';
import '../services/finans/vw_finanssenetalinan_service.dart';
import '../models/entities/finans/senet/vw_finanssenetalinan_dto.dart';
import 'finans/borc/senetverilen_liste_page.dart';
import 'finans/borc/senetverilen_rapor_genel_page.dart';
import 'finans/borc/senetverilen_rapor_odenecek_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String firmaAdi = "";
  String sirketAdi = "";
  String subeAdi = "";
  String kullaniciAdi = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Plasiyer konum gönderimi şimdilik kapalı (Ayarlar'daki seçim kaldırıldı).
    // PlasiyerKonumBroadcaster.instance.start();
    loadUserInfo();
    AuthorizationSession.instance.addListener(_permissionsChanged);
    // Giriş akışında güncelleme onaylandıysa Ayarlar sayfasını aç
    if (UpdateService.instance.pendingAutoInstall != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.push(
          context,
          PermissionMaterialPageRoute(builder: (_) => const AyarlarPage()),
        );
      });
    }
  }

  void _permissionsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AuthorizationSession.instance.removeListener(_permissionsChanged);
    WidgetsBinding.instance.removeObserver(this);
    PlasiyerKonumBroadcaster.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sadece uygulama ön plandayken ("resumed") konum gönder — arka plana
    // düştüğünde (paused/inactive/detached) durdur.
    if (state == AppLifecycleState.resumed) {
      // PlasiyerKonumBroadcaster.instance.start(); // şimdilik kapalı
    } else {
      PlasiyerKonumBroadcaster.instance.stop();
    }
  }

  ///  SharedPreferences'tan kullanıcı bilgilerini yükle
  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      firmaAdi = prefs.getString("firma_adi") ?? "";
      sirketAdi = prefs.getString("sirket_adi") ?? "";
      subeAdi = prefs.getString("sube_adi") ?? "";
      kullaniciAdi = prefs.getString("kullanici_adi") ?? "";
    });
  }

  bool _loggingOut = false;
  bool _switchingBranch = false;
  Future<void> _switchBranch() async {
    if (_switchingBranch || _loggingOut) return;
    _switchingBranch = true;
    try {
      final service = LoginService();
      final user = await service.branchSelectionUser();
      final lists = service.extractSirketSubeLists(user);
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      await Navigator.push(
          context,
          PermissionMaterialPageRoute(
              builder: (_) => SirketSubeSecimPage(
                  sirketler: lists['Sirketler'],
                  subeler: lists['Subeler'],
                  kullaniciDetay: user,
                  switchBranch: true,
                  initialCompanyId: prefs.getInt('sirket_id'),
                  initialBranchId: prefs.getInt('sube_id'))));
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    } finally {
      _switchingBranch = false;
    }
  }

  /// Oturumu kapat; kayıtlı giriş bilgilerini ve uygulama ayarlarını koru.
  Future<void> logout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      final confirmed = await UiFeedback.confirm(context,
          title: 'Çıkış Yap',
          message: 'Oturumu kapatmak istediğinize emin misiniz?',
          confirmLabel: 'Çıkış Yap',
          cancelLabel: 'Vazgeç');
      if (!confirmed || !mounted) return;
      final navigator = Navigator.of(context, rootNavigator: true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      if (!navigator.mounted) return;
      // Navigate before revoking permissions: the protected Home route may be
      // disposed as soon as the session resets. Never navigate from its context
      // after awaiting server logout.
      navigator.pushAndRemoveUntil(
          PageRouteBuilder<void>(
              pageBuilder: (_, __, ___) => const LoginPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero),
          (_) => false);
      await LoginService().logout(token);
    } finally {
      _loggingOut = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final onay = await UiFeedback.confirm(
          context,
          title: "Uygulamadan Çık",
          message: "Uygulamadan çıkmak istediğinize emin misiniz?",
          confirmLabel: "Çık",
          cancelLabel: "Vazgeç",
        );
        if (onay && context.mounted) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        //  Üst Bar
        appBar: designNotifier.value == ErpDesign.modern
            ? null
            : AppBar(
                title: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        "assets/images/logo_filerp.png",
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "FilERP Mobile",
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Tooltip(
                              message: 'Şube değiştir',
                              child: InkWell(
                                  key: const ValueKey('branch-switch'),
                                  onTap: _switchBranch,
                                  child: Row(children: [
                                    Expanded(
                                        child: Text(
                                      "$firmaAdi • $sirketAdi / $subeAdi — $kullaniciAdi",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurfaceVariant),
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                    Icon(Icons.expand_more_rounded,
                                        size: 16,
                                        color: scheme.onSurfaceVariant)
                                  ]))),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: scheme.surface,
                elevation: 0,
                iconTheme: IconThemeData(color: scheme.onSurface),
                actions: [
                  const AdminDashboardButton(),
                  // Bekleyen offline kayıt sayısı
                  ValueListenableBuilder<int>(
                    valueListenable: OfflineService.instance.pendingCount,
                    builder: (_, count, __) => count > 0
                        ? IconButton(
                            tooltip: "$count offline kayıt bekliyor",
                            onPressed: () => Navigator.push(
                                context,
                                PermissionMaterialPageRoute(
                                    builder: (_) => const AyarlarPage())),
                            icon: Badge(
                              label: Text("$count",
                                  style: const TextStyle(fontSize: 10)),
                              child: const Icon(Icons.cloud_upload_outlined),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "logout") {
                        logout();
                      } else if (value == "theme") {
                        ThemeController.setMode(
                            themeNotifier.value == ThemeMode.light
                                ? ThemeMode.dark
                                : ThemeMode.light);
                      } else if (value == "ayarlar") {
                        Navigator.push(
                            context,
                            PermissionMaterialPageRoute(
                                builder: (_) => const AyarlarPage()));
                      } else if (value == "yazici") {
                        Navigator.push(
                            context,
                            PermissionMaterialPageRoute(
                                builder: (_) => const YaziciAyarlarPage()));
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "theme",
                        child: Row(children: [
                          CorporateMenuIcon('Tema', size: 22),
                          SizedBox(width: 10),
                          Text("Açık/Koyu Tema"),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: "yazici",
                        child: Row(children: [
                          CorporateMenuIcon('Yazıcı', size: 22),
                          SizedBox(width: 10),
                          Text("Yazıcı Ayarları"),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: "ayarlar",
                        child: Row(children: [
                          CorporateMenuIcon('Ayarlar', size: 22),
                          SizedBox(width: 10),
                          Text("Ayarlar"),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: "logout",
                        child: Row(children: [
                          CorporateMenuIcon('Çıkış', size: 22),
                          SizedBox(width: 10),
                          Text("Çıkış"),
                        ]),
                      ),
                    ],
                    icon: CircleAvatar(
                      backgroundColor: scheme.primary,
                      child: const CorporateMenuIcon('Kullanıcı',
                          size: 24, onColoredSurface: true),
                    ),
                  ),
                ],
              ),

        body: Column(children: [
          _buildOfflineBanner(),
          Expanded(
              child: designNotifier.value == ErpDesign.modern
                  ? AnaSayfaYeniTasarimPage(
                      kullanici: kullaniciAdi,
                      firma: sirketAdi.isEmpty ? firmaAdi : sirketAdi,
                      sube: subeAdi,
                      aksiyonlar: {
                        'Şube Değiştir': _switchBranch,
                        'Fatura': () => _openFaturaDialog(context),
                        'Sipariş': () => _openSiparisDialog(context),
                        'İrsaliye': () => _openIrsaliyeDialog(context),
                        'Teklif': () => _openTeklifDialog(context),
                        'Stok': () => Navigator.push(
                            context,
                            PermissionMaterialPageRoute(
                                builder: (_) => const StokListPage())),
                        'Cari': () => Navigator.push(
                            context,
                            PermissionMaterialPageRoute(
                                builder: (_) => const CariListPage())),
                        'Depo': () => _openDepoDialog(context),
                        'Ambar G/Ç': () => Navigator.push(
                            context,
                            PermissionMaterialPageRoute(
                                builder: (_) => const AmbargcList())),
                        'Finans': () => _openFinansDialog(context),
                        'Raporlama': () => _openRaporDialog(context),
                        'Ayarlar': () => Navigator.push(
                            context,
                            PermissionMaterialPageRoute(
                                builder: (_) => const AyarlarPage())),
                        'Tema': () => ThemeController.setMode(
                            themeNotifier.value == ThemeMode.dark
                                ? ThemeMode.light
                                : ThemeMode.dark),
                        'Yazıcı': () => Navigator.push(
                            context,
                            PermissionMaterialPageRoute(
                                builder: (_) => const YaziciAyarlarPage())),
                        'Çıkış': logout,
                      },
                    )
                  : MobileDashboard(
                      userName: kullaniciAdi,
                      company: sirketAdi.isEmpty ? firmaAdi : sirketAdi,
                      branch: subeAdi,
                      sales: [
                        DashboardModule(
                            'Fatura',
                            'Satış ve alış faturaları',
                            Icons.receipt_long_outlined,
                            () => _openFaturaDialog(context)),
                        DashboardModule(
                            'Sipariş',
                            'Satış ve alış siparişleri',
                            Icons.shopping_bag_outlined,
                            () => _openSiparisDialog(context)),
                        DashboardModule(
                            'İrsaliye',
                            'Sevkiyat ve teslimat belgeleri',
                            Icons.local_shipping_outlined,
                            () => _openIrsaliyeDialog(context)),
                        DashboardModule(
                            'Teklif',
                            'Satış ve alış teklifleri',
                            Icons.request_quote_outlined,
                            () => _openTeklifDialog(context)),
                      ],
                      inventory: [
                        DashboardModule(
                            'Stok',
                            'Ürün ve hizmet kartları',
                            Icons.inventory_2_outlined,
                            () => Navigator.push(
                                context,
                                PermissionMaterialPageRoute(
                                    builder: (_) => const StokListPage()))),
                        DashboardModule(
                            'Depo',
                            'Depolar arası transferler',
                            Icons.warehouse_outlined,
                            () => _openDepoDialog(context)),
                        DashboardModule(
                            'Ambar G/Ç',
                            'Ambar giriş ve çıkış fişleri',
                            Icons.swap_vert_rounded,
                            () => Navigator.push(
                                context,
                                PermissionMaterialPageRoute(
                                    builder: (_) => const AmbargcList()))),
                      ],
                      finance: [
                        DashboardModule(
                            'Finans',
                            'Kasa, banka, çek ve senet',
                            Icons.account_balance_wallet_outlined,
                            () => _openFinansDialog(context)),
                        DashboardModule(
                            'Cari',
                            'Müşteri ve tedarikçi kartları',
                            Icons.people_outline_rounded,
                            () => Navigator.push(
                                context,
                                PermissionMaterialPageRoute(
                                    builder: (_) => const CariListPage()))),
                      ],
                      onReports: () => _openRaporDialog(context),
                    )),
        ]),
      ), // Scaffold
    ); // PopScope
  }

  Widget _buildOfflineBanner() {
    return ValueListenableBuilder<bool>(
      valueListenable: OfflineService.instance.offlineMode,
      builder: (_, isOffline, __) => ValueListenableBuilder<bool>(
        valueListenable: OfflineService.instance.isOnline,
        builder: (_, online, __) {
          // Banner sadece: offline mod açıksa VEYA internet yoksa göster
          if (!isOffline && online) return const SizedBox.shrink();
          final color =
              isOffline ? Colors.orange.shade700 : Colors.red.shade600;
          final bg = isOffline ? Colors.orange.shade50 : Colors.red.shade50;
          final icon =
              isOffline ? Icons.cloud_off_rounded : Icons.wifi_off_rounded;
          final message = isOffline
              ? "Offline Mod Aktif — kayıtlar kuyruğa alınıyor"
              : "İnternet bağlantısı yok";
          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const AyarlarPage())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: bg,
              child: Row(children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(message,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color))),
                Icon(Icons.chevron_right_rounded, size: 16, color: color),
              ]),
            ),
          );
        },
      ),
    );
  }

// MODAL ALT MENÜ
  void _openSiparisDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => _dialogShell(title: 'Siparişler', items: [
              _modalMenuItem(
                context,
                title: "Satış Siparişi",
                iconPath: "assets/icons/new/satis_siparis.png",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      PermissionMaterialPageRoute(
                          builder: (_) => const SatisSiparisList()));
                },
              ),
              _modalMenuItem(
                context,
                title: "Alış Siparişi",
                iconPath: "assets/icons/new/alis_siparis.png",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      PermissionMaterialPageRoute(
                          builder: (_) => const AlisSiparisList()));
                },
              ),
            ]));
  }

  void _openRaporDialog(BuildContext context) {
    // Tüm raporlar (numaralı, gruplu) Rapor Merkezi sayfasında; eski dialog devre dışı.
    Navigator.push(context,
        PermissionMaterialPageRoute(builder: (_) => const RaporMerkeziPage()));
  }

  void _openTeklifDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) => _dialogShell(title: 'Teklifler', items: [
              _modalMenuItem(ctx,
                  title: 'Satış Teklifi',
                  iconPath: 'assets/icons/new/satis_teklif.png', onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                    context,
                    PermissionMaterialPageRoute(
                        builder: (_) => const TeklifListPage(sales: true)));
              }),
              _modalMenuItem(ctx,
                  title: 'Alış Teklifi',
                  iconPath: 'assets/icons/new/alis_teklif.png', onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                    context,
                    PermissionMaterialPageRoute(
                        builder: (_) => const TeklifListPage(sales: false)));
              }),
            ]));
  }

  void _openFaturaDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => _dialogShell(title: 'Faturalar', items: [
              _modalMenuItem(
                context,
                title: "Satış Faturası",
                iconPath: "assets/icons/new/satis_faturasi.png",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    PermissionMaterialPageRoute(
                      builder: (_) => const SatisFaturaListPage(),
                    ),
                  );
                },
              ),
              _modalMenuItem(
                context,
                title: "Alış Faturası",
                iconPath: "assets/icons/new/alis_faturasi.png",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      PermissionMaterialPageRoute(
                        builder: (_) => const AlisFaturaList(),
                      ));
                },
              ),
            ]));
  }

  void _openIrsaliyeDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => _dialogShell(title: 'İrsaliyeler', items: [
              _modalMenuItem(
                context,
                title: "Satış İrsaliyesi",
                iconPath: "assets/icons/new/satis_irsaliyesi.png",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      PermissionMaterialPageRoute(
                          builder: (_) => const IrsaliyeListPage()));
                },
              ),
              _modalMenuItem(
                context,
                title: "Alış İrsaliyesi",
                iconPath: "assets/icons/new/alis_irsaliyesi.png",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      PermissionMaterialPageRoute(
                          builder: (_) => const AlisIrsaliyeList()));
                },
              ),
            ]));
  }

  /// Close the menu stack before opening an operational page.

  void _closeAllMenuDialogs(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _dialogShell({required String title, required List<Widget> items}) =>
      ErpModuleMenu(title: title, items: items, design: designNotifier.value);

  void _openFinansDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _dialogShell(title: "Finans", items: [
        _modalMenuItem(
          context,
          title: "Kasa",
          iconPath: "assets/icons/finans/kasa.png",
          onTap: () => _openKasaDialog(context),
        ),
        _modalMenuItem(
          context,
          title: "Banka",
          iconPath: "assets/icons/finans/banka.png",
          onTap: () => _openBankaDialog(context),
        ),
        _modalMenuItem(
          context,
          title: "Çek",
          iconPath: "assets/icons/finans/musteri_ceki.png",
          onTap: () => _openCekDialog(context),
        ),
        _modalMenuItem(
          context,
          title: "Senet",
          iconPath: "assets/icons/finans/musteri_ceki.png",
          onTap: () => _openSenetDialog(context),
        ),
        _modalMenuItem(
          context,
          title: "Tahsilat",
          iconPath: "assets/icons/finans/tahsilat.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const TahsilatListePage()));
          },
        ),
      ]),
    );
  }

  void _openCekDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _dialogShell(title: "Çek", items: [
        _modalMenuItem(
          context,
          title: "Müşteri Çekleri",
          iconPath: "assets/icons/finans/musteri_ceki.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const CekalinanListePage()));
          },
        ),
        _modalMenuItem(
          context,
          title: "Borç Çekleri",
          iconPath: "assets/icons/finans/borc_ceki.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const CekverilenListePage()));
          },
        ),
        _modalMenuItem(
          context,
          title: "Müşteri Çek Raporları",
          iconPath: "assets/icons/finans/rapor.png",
          onTap: () => _openCekRaporDialog(context),
        ),
        _modalMenuItem(
          context,
          title: "Borç Çek Raporları",
          iconPath: "assets/icons/finans/rapor.png",
          onTap: () => _openBorcCekRaporDialog(context),
        ),
      ]),
    );
  }

  void _openSenetDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _dialogShell(title: "Senet", items: [
        _modalMenuItem(
          context,
          title: "Müşteri Senetleri",
          iconPath: "assets/icons/finans/musteri_ceki.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const SenetalinanListePage()));
          },
        ),
        _modalMenuItem(
          context,
          title: "Borç Senetleri",
          iconPath: "assets/icons/finans/borc_ceki.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const SenetverilenListePage()));
          },
        ),
        _modalMenuItem(
          context,
          title: "Müşteri Senet Raporları",
          iconPath: "assets/icons/finans/rapor.png",
          onTap: () => _openSenetRaporDialog(context),
        ),
        _modalMenuItem(
          context,
          title: "Borç Senet Raporları",
          iconPath: "assets/icons/finans/rapor.png",
          onTap: () => _openBorcSenetRaporDialog(context),
        ),
      ]),
    );
  }

  void _openBorcCekRaporDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _dialogShell(title: "Borç Çek Raporları", items: [
        _modalMenuItem(
          context,
          title: "Genel Rapor",
          iconPath: "assets/icons/finans/rapor.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const CekverilenRaporGenelPage()));
          },
        ),
        _modalMenuItem(
          context,
          title: "Ödenecek Çekler",
          iconPath: "assets/icons/finans/rapor.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const CekverilenRaporOdenecekPage()));
          },
        ),
      ]),
    );
  }

  void _openCekRaporDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          _dialogShell(title: "Müşteri Çek Raporları", items: [
        _modalMenuItem(
          context,
          title: "Genel Çek Listesi",
          iconPath: "assets/icons/finans/rapor.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => CekalinanRaporPage(
                          title: "Genel Çek Listesi",
                          fetcher: (token) =>
                              VwFinanscekalinanService().getGenel(token),
                          showAsilBorclu: false,
                        )));
          },
        ),
        _modalMenuItem(
          context,
          title: "Verilene Göre Çek Listesi",
          iconPath: "assets/icons/finans/musteri_cek_cirosu.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => CekalinanRaporPage(
                          title: "Verilene Göre Çek Listesi",
                          fetcher: (token) =>
                              VwFinanscekalinanService().getVerilenegore(token),
                        )));
          },
        ),
        _modalMenuItem(
          context,
          title: "Portföydeki Çekler",
          iconPath: "assets/icons/finans/musteri_ceki.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => CekalinanRaporPage(
                          title: "Portföydeki Çekler",
                          fetcher: (token) =>
                              VwFinanscekalinanService().getPortfoy(token),
                        )));
          },
        ),
        _modalMenuItem(
          context,
          title: "Tahsildeki Çekler",
          iconPath: "assets/icons/finans/musteri_cek_tahsil.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => CekalinanRaporPage(
                          title: "Tahsildeki Çekler",
                          fetcher: (token) =>
                              VwFinanscekalinanService().getTahsil(token),
                        )));
          },
        ),
        _modalMenuItem(
          context,
          title: "Teminattaki Çekler",
          iconPath: "assets/icons/finans/musteri_ceki.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => CekalinanRaporPage(
                          title: "Teminattaki Çekler",
                          fetcher: (token) =>
                              VwFinanscekalinanService().getTeminat(token),
                        )));
          },
        ),
        _modalMenuItem(
          context,
          title: "Karşılıksız Çekler",
          iconPath: "assets/icons/finans/musteri_cek_protesto.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => CekalinanRaporPage(
                          title: "Karşılıksız Çekler",
                          fetcher: (token) =>
                              VwFinanscekalinanService().getKarsiliksiz(token),
                        )));
          },
        ),
      ]),
    );
  }

  void _openBorcSenetRaporDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _dialogShell(title: "Borç Senet Raporları", items: [
        _modalMenuItem(
          context,
          title: "Genel Rapor",
          iconPath: "assets/icons/finans/rapor.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const SenetverilenRaporGenelPage()));
          },
        ),
        _modalMenuItem(
          context,
          title: "Ödenecek Senetler",
          iconPath: "assets/icons/finans/rapor.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const SenetverilenRaporOdenecekPage()));
          },
        ),
      ]),
    );
  }

  void _openSenetRaporDialog(BuildContext context) {
    void ac(String baslik,
        Future<List<VwFinanssenetalinanDto>> Function(String token) fetcher,
        {bool showAsilBorclu = true}) {
      _closeAllMenuDialogs(context);
      Navigator.push(
          context,
          PermissionMaterialPageRoute(
              builder: (_) => SenetalinanRaporPage(
                    title: baslik,
                    fetcher: fetcher,
                    showAsilBorclu: showAsilBorclu,
                  )));
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          _dialogShell(title: "Müşteri Senet Raporları", items: [
        _modalMenuItem(
          context,
          title: "Genel Senet Listesi",
          iconPath: "assets/icons/finans/rapor.png",
          onTap: () => ac("Genel Senet Listesi",
              (t) => VwFinanssenetalinanService().getGenel(t),
              showAsilBorclu: false),
        ),
        _modalMenuItem(
          context,
          title: "Verilene Göre Senet Listesi",
          iconPath: "assets/icons/finans/musteri_cek_cirosu.png",
          onTap: () => ac("Verilene Göre Senet Listesi",
              (t) => VwFinanssenetalinanService().getVerilenegore(t)),
        ),
        _modalMenuItem(
          context,
          title: "Portföydeki Senetler",
          iconPath: "assets/icons/finans/musteri_ceki.png",
          onTap: () => ac("Portföydeki Senetler",
              (t) => VwFinanssenetalinanService().getPortfoy(t)),
        ),
        _modalMenuItem(
          context,
          title: "Tahsildeki Senetler",
          iconPath: "assets/icons/finans/musteri_cek_tahsil.png",
          onTap: () => ac("Tahsildeki Senetler",
              (t) => VwFinanssenetalinanService().getTahsil(t)),
        ),
        _modalMenuItem(
          context,
          title: "Teminattaki Senetler",
          iconPath: "assets/icons/finans/musteri_ceki.png",
          onTap: () => ac("Teminattaki Senetler",
              (t) => VwFinanssenetalinanService().getTeminat(t)),
        ),
        _modalMenuItem(
          context,
          title: "Karşılıksız Senetler",
          iconPath: "assets/icons/finans/musteri_cek_protesto.png",
          onTap: () => ac("Karşılıksız Senetler",
              (t) => VwFinanssenetalinanService().getKarsiliksiz(t)),
        ),
      ]),
    );
  }

  void _openDepoDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _dialogShell(title: "Depo", items: [
        _modalMenuItem(
          context,
          title: "DAT",
          iconPath: "assets/icons/new/dat.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const DatListPage()));
          },
        ),
        _modalMenuItemIcon(
          context,
          title: "Araç Yükle",
          icon: Icons.local_shipping_rounded,
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const DatListPage(aracYukleme: true)));
          },
        ),
      ]),
    );
  }

  void _openKasaDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _dialogShell(title: "Kasa", items: [
        _modalMenuItem(
          context,
          title: "Kasa Tanımları",
          iconPath: "assets/icons/finans/kasa_tanimlari.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const KasaTanimListPage()));
          },
        ),
        _modalMenuItem(
          context,
          title: "Kasa İşlem",
          iconPath: "assets/icons/finans/kasa_islemleri.png",
          onTap: () async {
            // Plasiyer kullanıcısı yalnızca kendi kasasına işlem girer: liste yerine direkt yeni hareket.
            final kp = await KullaniciPlasiyerHelper.getir();
            if (!context.mounted) return;
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => kp.kilitli
                        ? const KasahareketEklePage()
                        : const KasaIslemListPage()));
          },
        ),
        _modalMenuItem(
          context,
          title: "Son Durum Raporu",
          iconPath: "assets/icons/finans/rapor.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const KasaSondurumRaporu()));
          },
        ),
      ]),
    );
  }

  void _openBankaDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _dialogShell(title: "Banka", items: [
        _modalMenuItem(
          context,
          title: "Banka Tanımları",
          iconPath: "assets/icons/finans/banka_tanimlari.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const BankaTanimListPage()));
          },
        ),
        _modalMenuItem(
          context,
          title: "Banka İşlem",
          iconPath: "assets/icons/finans/banka_islemleri.png",
          onTap: () {
            _closeAllMenuDialogs(context);
            Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => const BankaIslemListPage()));
          },
        ),
      ]),
    );
  }

  Widget _modalMenuItem(
    BuildContext context, {
    required String title,
    required String iconPath,
    required VoidCallback onTap,
  }) =>
      ErpModuleMenuTile(
          title: title,
          asset: iconPath,
          onTap: onTap,
          design: designNotifier.value);

  Widget _modalMenuItemIcon(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      ErpModuleMenuTile(
          title: title, icon: icon, onTap: onTap, design: designNotifier.value);
}
