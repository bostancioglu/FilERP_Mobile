import '../../widgets/cari/cari_extra_sections.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../helpers/ui_feedback.dart';
import '../../services/offline/offline_service.dart';
import '../../models/entities/cari/cari_dto.dart';
import '../../models/entities/adres/ulke_dto.dart';
import '../../models/entities/adres/il_dto.dart';
import '../../models/entities/adres/ilce_dto.dart';
import '../../services/cari/cari_service.dart';
import '../../services/helper/adres_service.dart';
import '../../models/entities/helper/doviz_dto.dart';
import '../../services/helper/doviz_service.dart';
import '../../models/entities/plasiyer/plasiyer_dto.dart';
import '../../services/plasiyer/plasiyer_service.dart';
import '../../helpers/lookups.dart';

class CariEklePage extends StatefulWidget {
  final CariDto? editCari;

  const CariEklePage({super.key, this.editCari});

  @override
  State<CariEklePage> createState() => _CariEklePageState();
}

class _CariEklePageState extends State<CariEklePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _extra = CariExtraController();
  void _extraChanged() {
    if (mounted) setState(() {});
  }

  Widget _extraSection(CariExtraSection section) => CariExtraSections(
      controller: _extra, section: section, customerId: widget.editCari?.Id);
  late TabController _tabController;

  bool get isEdit => widget.editCari != null;
  ColorScheme get _scheme => Theme.of(context).colorScheme;

  // Controllers
  final kodCtrl = TextEditingController();
  final unvanCtrl = TextEditingController();
  final vergiDairesiCtrl = TextEditingController();
  final vergiNoCtrl = TextEditingController();
  final tcCtrl = TextEditingController();
  final adresCtrl = TextEditingController();
  final kurumsalTelCtrl = TextEditingController();
  final yetkiliTelCtrl = TextEditingController();
  final bolgeCtrl = TextEditingController();
  final vadeCtrl = TextEditingController();
  final iskontoCtrl = TextEditingController();
  final grupKoduCtrl = TextEditingController();
  final kod1Ctrl = TextEditingController();
  final kod2Ctrl = TextEditingController();
  final kod3Ctrl = TextEditingController();
  final kod4Ctrl = TextEditingController();
  final kod5Ctrl = TextEditingController();

  // Adres
  List<UlkeDto> ulkeler = [];
  List<IlDto> iller = [];
  List<IlceDto> ilceler = [];
  int? ulkeId, ilId, ilceId;
  bool loadingIller = false, loadingIlceler = false;

  // Lookup data
  List<PlasiyerDto> plasiyerler = [];
  int? plasiyerId;
  bool loadingPlasiyer = false;

  List<DovizDto> dovizler = [];
  int? dovizId;
  bool loadingDoviz = false;

  // Tab hata işaretleri
  bool genelTabHata = false;
  bool adresTabHata = false;
  bool muhasebeTabHata = false;

  int firmaTipi = 1;
  bool saving = false;
  int? kartTuru = 1;
  int? efaturaTipi = 1;

  @override
  void initState() {
    super.initState();
    _extra.addListener(_extraChanged);
    _tabController = TabController(length: 6, vsync: this);

    if (isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fillForm(widget.editCari!);
      });
    }

    _loadUlkeler();
    _loadDovizler();
    _loadPlasiyerler();
  }

  @override
  void dispose() {
    _extra.removeListener(_extraChanged);
    _extra.dispose();
    _tabController.dispose();
    kodCtrl.dispose();
    unvanCtrl.dispose();
    vergiDairesiCtrl.dispose();
    vergiNoCtrl.dispose();
    tcCtrl.dispose();
    adresCtrl.dispose();
    kurumsalTelCtrl.dispose();
    yetkiliTelCtrl.dispose();
    bolgeCtrl.dispose();
    vadeCtrl.dispose();
    iskontoCtrl.dispose();
    grupKoduCtrl.dispose();
    kod1Ctrl.dispose();
    kod2Ctrl.dispose();
    kod3Ctrl.dispose();
    kod4Ctrl.dispose();
    kod5Ctrl.dispose();
    super.dispose();
  }

  // ── API ──────────────────────────────────────────────────────────────────

  Future<void> _loadUlkeler() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final data = await AdresService().getUlkeler(token);
    if (!mounted || data.isEmpty) return;
    final int? editUlkeId = widget.editCari?.Ulkeid;
    setState(() {
      ulkeler = data;
      ulkeId = (editUlkeId != null && data.any((x) => x.Id == editUlkeId))
          ? editUlkeId
          : (data.any((x) => x.Id == 1) ? 1 : data.first.Id);
    });
    if (ulkeId != null) await _loadIller(ulkeId!);
  }

  Future<void> _loadIller(int id) async {
    if (!mounted) return;
    setState(() {
      loadingIller = true;
      iller.clear();
      ilceler.clear();
      ilId = null;
      ilceId = null;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final data = await AdresService().getIller(token, id);
    if (!mounted) return;
    if (data.isEmpty) {
      setState(() => loadingIller = false);
      return;
    }
    final int? editIlId = widget.editCari?.Ilid;
    setState(() {
      iller = data;
      ilId = (editIlId != null && data.any((x) => x.Id == editIlId))
          ? editIlId
          : data.first.Id;
      loadingIller = false;
    });
    if (ilId != null) await _loadIlceler(ilId!);
  }

  Future<void> _loadIlceler(int id) async {
    if (!mounted) return;
    setState(() {
      loadingIlceler = true;
      ilceler.clear();
      ilceId = null;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final data = await AdresService().getIlceler(token, id);
    if (!mounted) return;
    final int? editIlceId = widget.editCari?.Ilceid;
    setState(() {
      ilceler = data;
      ilceId = (editIlceId != null && data.any((x) => x.Id == editIlceId))
          ? editIlceId
          : (data.isNotEmpty ? data.first.Id : null);
      loadingIlceler = false;
    });
  }

  Future<void> _loadDovizler() async {
    if (!mounted) return;
    setState(() => loadingDoviz = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final data = await DovizService().getDovizler(token);
    if (!mounted) return;
    if (data.isEmpty) {
      setState(() => loadingDoviz = false);
      return;
    }
    final int? editDovizId = widget.editCari?.Dovizid;
    setState(() {
      dovizler = data;
      dovizId = (editDovizId != null && data.any((x) => x.Id == editDovizId))
          ? editDovizId
          : data.first.Id;
      loadingDoviz = false;
    });
  }

  Future<void> _loadPlasiyerler() async {
    if (!mounted) return;
    setState(() => loadingPlasiyer = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final data = await PlasiyerService().getPlasiyerler(token);
    if (!mounted) return;
    if (data.isEmpty) {
      setState(() => loadingPlasiyer = false);
      return;
    }
    final int? editPlasiyerId = widget.editCari?.Plasiyerid;
    setState(() {
      plasiyerler = data;
      plasiyerId =
          (editPlasiyerId != null && data.any((x) => x.Id == editPlasiyerId))
              ? editPlasiyerId
              : data.first.Id;
      loadingPlasiyer = false;
    });
  }

  void _fillForm(CariDto c) {
    _extra.load(c);
    final parsedFirmaTipi = c.Firmatipi == null
        ? 1
        : int.tryParse(c.Firmatipi.toString().split('.').first) ?? 1;
    setState(() {
      kodCtrl.text = c.Kod ?? "";
      unvanCtrl.text = c.Ad ?? "";
      vergiDairesiCtrl.text = c.Vergidairesi ?? "";
      vergiNoCtrl.text = c.Vergino ?? "";
      tcCtrl.text = c.Tckimlik ?? "";
      adresCtrl.text = c.Adres ?? "";
      kurumsalTelCtrl.text = c.Kurumsaltel ?? "";
      yetkiliTelCtrl.text = c.Yetkilimobil ?? "";
      bolgeCtrl.text = c.Bolge ?? "";
      vadeCtrl.text = c.Vadegunu?.toString() ?? "";
      iskontoCtrl.text = c.Iskontoorani?.toString() ?? "";
      grupKoduCtrl.text = c.Grupkodu ?? "";
      kod1Ctrl.text = c.Kod1 ?? "";
      kod2Ctrl.text = c.Kod2 ?? "";
      kod3Ctrl.text = c.Kod3 ?? "";
      kod4Ctrl.text = c.Kod4 ?? "";
      kod5Ctrl.text = c.Kod5 ?? "";
      firmaTipi = parsedFirmaTipi;
      kartTuru = c.Kartturu ?? kartTuru;
      efaturaTipi = c.Efaturatip ?? efaturaTipi;
      ulkeId = c.Ulkeid ?? ulkeId;
      ilId = c.Ilid ?? ilId;
      ilceId = c.Ilceid ?? ilceId;
      dovizId = c.Dovizid ?? dovizId;
      plasiyerId = c.Plasiyerid ?? plasiyerId;
    });
  }

  void _validateTabs() {
    setState(() {
      genelTabHata =
          kodCtrl.text.trim().isEmpty || unvanCtrl.text.trim().isEmpty;
      adresTabHata = ulkeId == null || ilId == null || ilceId == null;
      muhasebeTabHata = false;
    });
  }

  Future<void> kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    _validateTabs();

    if (genelTabHata) {
      _tabController.animateTo(0);
      _showError("Genel bilgiler zorunludur");
      return;
    }
    if (adresTabHata) {
      _tabController.animateTo(2);
      _showError("Adres bilgileri zorunludur");
      return;
    }

    final vergiNo = vergiNoCtrl.text.trim();
    final tcNo = tcCtrl.text.trim();
    final vergiDairesi = vergiDairesiCtrl.text.trim();

    if (vergiNo.isEmpty && tcNo.isEmpty) {
      _tabController.animateTo(0);
      _showError("Vergi No veya TC Kimlik alanlarından biri zorunludur");
      return;
    }
    if (vergiNo.isNotEmpty && tcNo.isNotEmpty) {
      _tabController.animateTo(0);
      _showError("Vergi No ve TC Kimlik aynı anda dolu olamaz");
      return;
    }
    if (vergiNo.isNotEmpty && vergiDairesi.isEmpty) {
      _tabController.animateTo(0);
      _showError("Vergi Dairesi zorunludur, çünkü Vergi No girildi");
      return;
    }

    setState(() => saving = true);

    try {
      final token =
          (await SharedPreferences.getInstance()).getString("token_final") ??
              "";

      final cari = CariDto(
        Id: widget.editCari?.Id,
        Kod: isEdit ? widget.editCari!.Kod : kodCtrl.text.trim(),
        Ad: unvanCtrl.text.trim(),
        Vergidairesi: vergiDairesi,
        Vergino: vergiNo,
        Tckimlik: tcNo,
        Adres: adresCtrl.text.trim(),
        Kurumsaltel: kurumsalTelCtrl.text.trim(),
        Yetkilimobil: yetkiliTelCtrl.text.trim(),
        Bolge: bolgeCtrl.text.trim(),
        Vadegunu: int.tryParse(vadeCtrl.text),
        Iskontoorani: double.tryParse(iskontoCtrl.text.replaceAll(',', '.')),
        Grupkodu: grupKoduCtrl.text.trim(),
        Kod1: kod1Ctrl.text.trim(),
        Kod2: kod2Ctrl.text.trim(),
        Kod3: kod3Ctrl.text.trim(),
        Kod4: kod4Ctrl.text.trim(),
        Kod5: kod5Ctrl.text.trim(),
        Firmatipi: firmaTipi,
        Kartturu: kartTuru,
        Dovizid: dovizId,
        Ulkeid: ulkeId,
        Ilid: ilId,
        Ilceid: ilceId,
        Plasiyerid: plasiyerId,
        Kilit: isEdit ? widget.editCari!.Kilit : 4,
        Hesaptipi: isEdit ? widget.editCari!.Hesaptipi : 2,
        Efaturatip: efaturaTipi,
        Ortakkoduvar: isEdit ? widget.editCari!.Ortakkoduvar : false,
        Carikategoriid: isEdit ? widget.editCari!.Carikategoriid : 7,
        Sirketortak: isEdit ? widget.editCari!.Sirketortak : true,
      );

      final body = isEdit
          ? cari.toJson(includeKod: true, includeId: true)
          : cari.toJson(includeKod: true, includeId: false);

      body.addAll(_extra.toJson());

      final manuelOffline = await OfflineService.instance.getOfflineMode();
      final internetYok = !OfflineService.instance.isOnline.value;
      if (manuelOffline || internetYok) {
        await OfflineService.instance.enqueue('single_full', {
          'endpoint': '/Cari',
          'method': isEdit ? 'PUT' : 'POST',
          'body': body,
        });
        if (!mounted) return;
        await UiFeedback.showSuccess(
          context,
          internetYok
              ? "İnternet yok — kayıt kuyruğa alındı, bağlantı gelince gönderilecek"
              : "Kayıt kuyruğa eklendi — online olunca gönderilecek",
        );
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }

      if (isEdit) {
        await CariService().updateCari(token, body);
      } else {
        await CariService().addCari(token, body);
      }

      if (!mounted) return;
      await UiFeedback.showSuccess(
        context,
        isEdit
            ? "Cari başarıyla güncellendi"
            : "Cari kayıt başarıyla oluşturuldu",
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      await UiFeedback.showError(
          context, e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg.replaceAll("Exception:", "").trim()),
      backgroundColor: Theme.of(context).colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: saving
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _scheme.primary),
                  SizedBox(height: 16),
                  Text("Kaydediliyor...",
                      style: TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _genelTab(),
                  _muhasebeTab(),
                  _adresTab(),
                  _iletisimTab(),
                  _ekTab(),
                  _raporTab(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ErpPageAppBar(
      context: context,
      toolbarHeight: 56,
      backgroundColor: _scheme.surface,
      foregroundColor: _scheme.onSurface,
      elevation: 0,
      title: Text(isEdit ? 'Cari Güncelle' : 'Yeni Cari',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: _scheme.onSurface)),
      bottom: ErpAdaptiveTabs(
          context: context,
          tabBar: TabBar(
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: _scheme.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 15),
            controller: _tabController,
            isScrollable: true,
            labelColor: _scheme.primary,
            unselectedLabelColor: _scheme.onSurfaceVariant,
            indicatorColor: _scheme.primary,
            indicatorWeight: 2.5,
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontSize: 12),
            tabs: [
              _tab(Icons.info_outline_rounded, "Genel", genelTabHata),
              _tab(Icons.account_balance_outlined, "Muhasebe", muhasebeTabHata),
              _tab(Icons.location_on_outlined, "Adres", adresTabHata),
              _tab(Icons.phone_outlined, "İletişim", false),
              _tab(Icons.tune_rounded, "Ek", false),
              _tab(Icons.bar_chart_rounded, "Rapor", false),
            ],
          )),
    );
  }

  Tab _tab(IconData icon, String label, bool hasError) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          SizedBox(width: 5),
          Text(label),
          if (hasError) ...[
            SizedBox(width: 4),
            Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: _scheme.primary, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
          color: _scheme.surface,
          border: Border(
              top: BorderSide(
                  color: _scheme.outlineVariant.withValues(alpha: 0.45)))),
      child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: PermissionAction(
                modules: [201],
                access: Access.write,
                child: FilledButton.icon(
                  onPressed: saving ? null : kaydet,
                  style: FilledButton.styleFrom(
                      minimumSize: Size(double.infinity, 52)),
                  icon: saving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _scheme.onSurfaceVariant))
                      : Icon(Icons.save_outlined, size: 21),
                  label: Text(
                      saving
                          ? "Kaydediliyor..."
                          : isEdit
                              ? "Değişiklikleri kaydet"
                              : "Cari kartını oluştur",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                )),
          )),
    );
  }

  // ── TABS ─────────────────────────────────────────────────────────────────

  Widget _genelTab() => _tabScroll([
        _section("Temel Bilgiler", Icons.badge_outlined, [
          TextFormField(
            controller: kodCtrl,
            enabled: !isEdit,
            decoration:
                _dec("Cari kodu *", Icons.tag_rounded, hint: "Cari Kodu"),
            validator: (v) => v == null || v.isEmpty ? "Zorunlu alan" : null,
          ),
          _input(unvanCtrl, "Cari Ünvan", Icons.business_outlined),
        ]),
        _section("Vergi Bilgileri", Icons.receipt_long_outlined, [
          _input(vergiNoCtrl, "Vergi No", Icons.numbers_rounded,
              required: false),
          _input(
              vergiDairesiCtrl, "Vergi Dairesi", Icons.account_balance_outlined,
              required: false),
          _input(tcCtrl, "TC Kimlik No", Icons.credit_card_outlined,
              required: false),
        ]),
      ]);

  Widget _muhasebeTab() => _tabScroll([
        _section("Muhasebe Ayarları", Icons.account_balance_outlined, [
          DropdownButtonFormField<int>(
            decoration: _dec("E-Fatura Tipi", Icons.receipt_outlined),
            value: LookupHelper.efaturaTipleri.any((x) => x.id == efaturaTipi)
                ? efaturaTipi
                : null,
            items: LookupHelper.efaturaTipleri
                .map((x) =>
                    DropdownMenuItem<int>(value: x.id, child: Text(x.ad)))
                .toList(),
            onChanged: (v) => setState(() => efaturaTipi = v),
            validator: (v) => v == null ? "Zorunlu alan" : null,
          ),
          DropdownButtonFormField<int>(
            isExpanded: true,
            decoration: _dec("Döviz Tipi", Icons.currency_exchange_rounded),
            value: dovizId,
            items: dovizler
                .map((d) => DropdownMenuItem<int>(
                      value: d.Id,
                      child: Text(
                        d.Ad != null ? "${d.Birim} - ${d.Ad}" : d.Birim ?? "-",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: loadingDoviz ? null : (v) => setState(() => dovizId = v),
            validator: (v) => v == null ? "Döviz tipi zorunludur" : null,
          ),
        ]),
        _extraSection(CariExtraSection.bank),
        _extraSection(CariExtraSection.electronic),
        _extraSection(CariExtraSection.accounts),
      ]);

  Widget _adresTab() => _tabScroll([
        _section("Konum", Icons.map_outlined, [
          DropdownSearch<UlkeDto>(
            items: ulkeler,
            itemAsString: (u) => u.Ad,
            selectedItem: ulkeler.where((x) => x.Id == ulkeId).isNotEmpty
                ? ulkeler.firstWhere((x) => x.Id == ulkeId)
                : null,
            popupProps: const PopupProps.menu(
                showSearchBox: true,
                constraints: BoxConstraints(maxHeight: 280)),
            dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: _dec("Ülke", Icons.flag_outlined)),
            onChanged: (val) async {
              if (val == null) return;
              setState(() => ulkeId = val.Id);
              await _loadIller(val.Id);
            },
          ),
          DropdownSearch<IlDto>(
            items: iller,
            enabled: !loadingIller && ulkeId != null,
            itemAsString: (i) => i.Ad,
            selectedItem: iller.where((x) => x.Id == ilId).isNotEmpty
                ? iller.firstWhere((x) => x.Id == ilId)
                : null,
            popupProps: const PopupProps.menu(
                showSearchBox: true,
                constraints: BoxConstraints(maxHeight: 280)),
            dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration:
                    _dec("İl", Icons.location_city_outlined)),
            onChanged: (val) async {
              if (val == null) return;
              setState(() => ilId = val.Id);
              await _loadIlceler(val.Id);
            },
          ),
          DropdownSearch<IlceDto>(
            items: ilceler,
            enabled: !loadingIlceler && ilId != null,
            itemAsString: (i) => i.Ad,
            selectedItem: ilceler.where((x) => x.Id == ilceId).isNotEmpty
                ? ilceler.firstWhere((x) => x.Id == ilceId)
                : null,
            popupProps: const PopupProps.menu(
                showSearchBox: true,
                constraints: BoxConstraints(maxHeight: 280)),
            dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration:
                    _dec("İlçe", Icons.location_on_outlined)),
            onChanged: (val) => setState(() => ilceId = val?.Id),
          ),
        ]),
        _section("Adres Detayı", Icons.home_outlined, [
          _input(adresCtrl, "Açık Adres", Icons.edit_location_outlined,
              required: false, maxLines: 3),
        ]),
      ]);

  Widget _iletisimTab() => _tabScroll([
        _section("İletişim Bilgileri", Icons.phone_outlined, [
          _input(kurumsalTelCtrl, "Kurumsal Tel", Icons.business_outlined,
              required: false),
          _input(yetkiliTelCtrl, "Yetkili GSM", Icons.smartphone_outlined,
              required: false),
        ]),
        _extraSection(CariExtraSection.corporate),
        _extraSection(CariExtraSection.contact),
      ]);

  Widget _ekTab() => _tabScroll([
        _section("Firma Sınıflandırma", Icons.corporate_fare_outlined, [
          _firmaTipiWidget(),
          DropdownButtonFormField<int>(
            decoration: _dec("Kart Türü", Icons.credit_card_outlined),
            value: LookupHelper.kartTurleri.any((x) => x.id == kartTuru)
                ? kartTuru
                : null,
            items: LookupHelper.kartTurleri
                .map((x) =>
                    DropdownMenuItem<int>(value: x.id, child: Text(x.ad)))
                .toList(),
            onChanged: (v) => setState(() => kartTuru = v),
            validator: (v) => v == null ? "Zorunlu alan" : null,
          ),
          DropdownButtonFormField<int>(
            isExpanded: true,
            decoration: _dec("Plasiyer", Icons.person_outlined),
            value: plasiyerId,
            items: plasiyerler
                .map((p) => DropdownMenuItem<int>(
                      value: p.Id,
                      child: Text(p.Adsoyad ?? p.Kod ?? "-",
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged:
                loadingPlasiyer ? null : (v) => setState(() => plasiyerId = v),
            validator: (v) => v == null ? "Plasiyer zorunludur" : null,
          ),
        ]),
        _section("Ticari Koşullar", Icons.handshake_outlined, [
          _input(bolgeCtrl, "Bölge", Icons.map_outlined, required: false),
          _input(vadeCtrl, "Vade Günü", Icons.calendar_today_outlined,
              required: false),
          _input(iskontoCtrl, "İskonto Oranı (%)", Icons.percent_rounded,
              required: false),
        ]),
        _extraSection(CariExtraSection.relations),
      ]);

  Widget _raporTab() => _tabScroll([
        _section("Gruplama & Kodlar", Icons.label_outline_rounded, [
          _input(grupKoduCtrl, "Grup Kodu", Icons.folder_outlined,
              required: false),
          _input(kod1Ctrl, "Kod 1", Icons.tag_rounded, required: false),
          _input(kod2Ctrl, "Kod 2", Icons.tag_rounded, required: false),
          _input(kod3Ctrl, "Kod 3", Icons.tag_rounded, required: false),
          _input(kod4Ctrl, "Kod 4", Icons.tag_rounded, required: false),
          _input(kod5Ctrl, "Kod 5", Icons.tag_rounded, required: false),
        ]),
        _extraSection(CariExtraSection.sharedCodes),
      ]);

  // ── HELPERS ──────────────────────────────────────────────────────────────

  Widget _tabScroll(List<Widget> sections) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: sections
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: s,
                ))
            .toList(),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> fields) {
    return Container(
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: _scheme.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 17, color: _scheme.primary),
                ),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          Divider(
              color: _scheme.outlineVariant.withValues(alpha: 0.45), height: 1),

          // Fields
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: fields
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: f,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: [kurumsalTelCtrl, yetkiliTelCtrl].contains(ctrl)
          ? TextInputType.phone
          : [vergiNoCtrl, tcCtrl, vadeCtrl].contains(ctrl)
              ? TextInputType.number
              : ctrl == iskontoCtrl
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : maxLines > 1
                      ? TextInputType.multiline
                      : TextInputType.text,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: _dec(required ? "$label *" : label, icon),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? "Zorunlu alan" : null
          : null,
    );
  }

  Widget _firmaTipiWidget() {
    const options = [
      (label: "Tüzel", value: 1),
      (label: "Gerçek", value: 2),
      (label: "Kamu", value: 3),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Firma Tipi",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final selected = firmaTipi == opt.value;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => firmaTipi = opt.value),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: opt.value < 3 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? _scheme.primary.withValues(alpha: 0.08)
                        : _scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          selected ? _scheme.primary : _scheme.outlineVariant,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    opt.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          selected ? _scheme.primary : _scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  InputDecoration _dec(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      prefixIcon: Icon(icon, size: 18, color: _scheme.onSurfaceVariant),
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      labelStyle: TextStyle(fontSize: 13, color: _scheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _scheme.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
    );
  }
}
