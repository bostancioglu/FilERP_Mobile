import '../../helpers/stock_field_schema.dart';
import '../../widgets/erp_record_fields.dart';
import '../../widgets/stock_card_sections.dart';
import '../../services/stok/stock_card_fields_service.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../theme/app_theme.dart';
import '../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/entities/stok/stok_dto.dart';
import '../../models/entities/olcubirimi/olcubr_dto.dart';
import '../../models/entities/stok/stok_kategori_dto.dart';
import '../../helpers/ui_feedback.dart';
import '../../services/offline/offline_service.dart';
import '../../services/stok/stok_service.dart';
import '../../services/helper/olcubr_service.dart';
import '../../services/stok/stok_kategori_service.dart';
import '../../helpers/stok_couples.dart';

class StokEklePage extends StatefulWidget {
  final StokDto? editStok;

  const StokEklePage({super.key, this.editStok});

  @override
  State<StokEklePage> createState() => _StokEklePageState();
}

class _StokEklePageState extends State<StokEklePage>
    with SingleTickerProviderStateMixin {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _accent => _scheme.primary;
  Color get _ink => _scheme.onSurface;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;

  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  bool get isEdit => widget.editStok != null;
  int? seciliTakipSekli = 1;
  int? seciliKartTuru = 1;
  int? seciliStokTuru = 1;

  // Controllers
  final kodCtrl = TextEditingController();
  final adCtrl = TextEditingController();
  final yabanciAdCtrl = TextEditingController();
  final aciklama1Ctrl = TextEditingController();
  final aciklama2Ctrl = TextEditingController();
  final aciklama3Ctrl = TextEditingController();
  final grupKoduCtrl = TextEditingController();
  final kod1Ctrl = TextEditingController();
  final kod2Ctrl = TextEditingController();
  final kod3Ctrl = TextEditingController();
  final kod4Ctrl = TextEditingController();
  final kod5Ctrl = TextEditingController();
  final kdvAlisCtrl = TextEditingController();
  final kdvSatisCtrl = TextEditingController();
  final tevkifatCtrl = TextEditingController();

  // Dropdown data
  List<OlcubrDto> olcuList = [];
  OlcubrDto? seciliOlcu;

  List<StokkategoriDto> kategoriList = [];
  StokkategoriDto? seciliKategori;

  bool saving = false;
  late final RecordFieldsController extra;
  late final StockRowsController rows;
  late final StockCardFieldsService fieldsService;
  void _extraChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.editStok?.toJson() ??
        {'Sirketortak': true, 'Partiseritakipmodu': 0};
    extra = RecordFieldsController(stockExtraFields, initial: initial)
      ..addListener(_extraChanged);
    rows = StockRowsController(initial);
    fieldsService = StockCardFieldsService(stockId: widget.editStok?.Id);
    _tabController = TabController(length: 5, vsync: this);
    _fillIfEdit();
    _loadOlcu();
    _loadKategori();
  }

  @override
  void dispose() {
    extra.dispose();
    rows.dispose();
    _tabController.dispose();
    kodCtrl.dispose();
    adCtrl.dispose();
    yabanciAdCtrl.dispose();
    aciklama1Ctrl.dispose();
    aciklama2Ctrl.dispose();
    aciklama3Ctrl.dispose();
    grupKoduCtrl.dispose();
    kod1Ctrl.dispose();
    kod2Ctrl.dispose();
    kod3Ctrl.dispose();
    kod4Ctrl.dispose();
    kod5Ctrl.dispose();
    kdvAlisCtrl.dispose();
    kdvSatisCtrl.dispose();
    tevkifatCtrl.dispose();
    super.dispose();
  }

  void _fillIfEdit() {
    final s = widget.editStok;
    if (s == null) return;

    kodCtrl.text = s.Kod ?? "";
    adCtrl.text = s.Ad ?? "";
    yabanciAdCtrl.text = s.Yabanciad ?? "";
    aciklama1Ctrl.text = s.Aciklama1 ?? "";
    aciklama2Ctrl.text = s.Aciklama2 ?? "";
    aciklama3Ctrl.text = s.Aciklama3 ?? "";
    grupKoduCtrl.text = s.Grupkodu ?? "";
    kod1Ctrl.text = s.Kod1 ?? "";
    kod2Ctrl.text = s.Kod2 ?? "";
    kod3Ctrl.text = s.Kod3 ?? "";
    kod4Ctrl.text = s.Kod4 ?? "";
    kod5Ctrl.text = s.Kod5 ?? "";
    kdvAlisCtrl.text = s.Kdvalis?.toString() ?? "";
    kdvSatisCtrl.text = s.Kdvsatis?.toString() ?? "";
    tevkifatCtrl.text = s.Tevkifatorani?.toString() ?? "";
    seciliTakipSekli = s.Takipsekli ?? seciliTakipSekli;
    seciliKartTuru = s.Kartturu ?? seciliKartTuru;
    seciliStokTuru = s.Stokturu ?? seciliStokTuru;
  }

  Future<void> _loadOlcu() async {
    final token =
        (await SharedPreferences.getInstance()).getString("token_final") ?? "";
    final list = await OlcubrService().getAll(token);
    if (!mounted || list.isEmpty) return;
    setState(() {
      olcuList = list;
      seciliOlcu = isEdit
          ? list.firstWhere(
              (x) => x.Id == widget.editStok!.Temelolcubrid,
              orElse: () => OlcubrDto(
                  Id: widget.editStok!.Temelolcubrid,
                  Ad: widget.editStok!.Temelolcubr?.Ad ?? "Mevcut Ölçü Birimi"),
            )
          : list.first;
      if (seciliOlcu != null && !olcuList.contains(seciliOlcu))
        olcuList.add(seciliOlcu!);
    });
  }

  Future<void> _loadKategori() async {
    final token =
        (await SharedPreferences.getInstance()).getString("token_final") ?? "";
    final list = await StokKategoriService().getAll(token);
    if (!mounted || list.isEmpty) return;
    setState(() {
      kategoriList = list;
      seciliKategori = isEdit
          ? list.firstWhere(
              (x) => x.Id == widget.editStok!.Stokkategoriid,
              orElse: () => StokkategoriDto(
                  Id: widget.editStok!.Stokkategoriid,
                  Ad: widget.editStok!.Stokkategori?.Ad ?? "Mevcut Kategori"),
            )
          : list.first;
      if (seciliKategori != null && !kategoriList.contains(seciliKategori))
        kategoriList.add(seciliKategori!);
    });
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);

    try {
      AuthorizationSession.instance
          .require(101, isEdit ? Access.update : Access.create);
      final token =
          (await SharedPreferences.getInstance()).getString("token_final") ??
              "";

      final stok = StokDto(
        Id: widget.editStok?.Id,
        Kod: kodCtrl.text.trim(),
        Ad: adCtrl.text.trim(),
        Yabanciad: yabanciAdCtrl.text.trim(),
        Aciklama1: aciklama1Ctrl.text.trim(),
        Aciklama2: aciklama2Ctrl.text.trim(),
        Aciklama3: aciklama3Ctrl.text.trim(),
        Grupkodu: grupKoduCtrl.text.trim(),
        Kod1: kod1Ctrl.text.trim(),
        Kod2: kod2Ctrl.text.trim(),
        Kod3: kod3Ctrl.text.trim(),
        Kod4: kod4Ctrl.text.trim(),
        Kod5: kod5Ctrl.text.trim(),
        Kdvalis: double.tryParse(kdvAlisCtrl.text.replaceAll(',', '.')),
        Kdvsatis: double.tryParse(kdvSatisCtrl.text.replaceAll(',', '.')),
        Tevkifatorani: double.tryParse(tevkifatCtrl.text.replaceAll(',', '.')),
        Temelolcubrid: seciliOlcu?.Id,
        Stokkategoriid: seciliKategori?.Id,
        Takipsekli: seciliTakipSekli,
        Kartturu: seciliKartTuru,
        Stokturu: seciliStokTuru,
        Sirketortak: true,
      );

      final body = isEdit
          ? stok.toSaveJson(includeId: true)
          : stok.toSaveJson(includeKod: true);

      body.addAll(extra.toJson());
      if (isEdit &&
          widget.editStok!.extraCollections.containsKey('Recetesivar'))
        body['Recetesivar'] = widget.editStok!.extraCollections['Recetesivar'];
      if (!isEdit) body.addAll(rows.createBody());
      final manuelOffline = await OfflineService.instance.getOfflineMode();
      final internetYok = !OfflineService.instance.isOnline.value;
      if (manuelOffline || internetYok) {
        if (isEdit && rows.dirty)
          throw Exception(
              'Satır değişikliklerini kaydetmek için bağlantı gerekli.');
        await OfflineService.instance.enqueue('single_full', {
          'endpoint': '/Stok',
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

      final service = StokService();
      if (isEdit) {
        await service.updateStok(token, body);
        try {
          await fieldsService.sync(rows);
        } catch (e) {
          throw Exception('Ana kart kaydedildi. Satırlar tamamlanamadı: $e');
        }
        if (!mounted) return;
        await UiFeedback.showSuccess(context, "Stok başarıyla güncellendi");
      } else {
        await service.addStok(token, body);
        if (!mounted) return;
        await UiFeedback.showSuccess(context, "Stok başarıyla eklendi");
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      await UiFeedback.showError(
          context, e.toString().replaceFirst("Exception:", "").trim());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: saving
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _accent),
                  const SizedBox(height: 16),
                  Text("Kaydediliyor...",
                      style: TextStyle(color: _scheme.onSurfaceVariant)),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _genelTab(),
                  _aciklamaTab(),
                  _raporTab(),
                  _vergiTab(),
                  _detailsTab(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ErpPageAppBar(
      context: context,
      backgroundColor: _scheme.surface,
      foregroundColor: _ink,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? "Stok Güncelle" : "Yeni Stok",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: _ink,
            ),
          ),
          if (isEdit && widget.editStok?.Ad != null)
            Text(
              widget.editStok!.Ad!,
              style: TextStyle(fontSize: 12, color: _scheme.onSurfaceVariant),
            ),
        ],
      ),
      bottom: ErpAdaptiveTabs(
          context: context,
          tabBar: TabBar(
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
                color: _accent.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12)),
            controller: _tabController,
            isScrollable: true,
            labelColor: _accent,
            unselectedLabelColor: _scheme.onSurfaceVariant,
            indicatorColor: _accent,
            indicatorWeight: 2.5,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: [
              _tab(Icons.inventory_2_outlined, "Genel"),
              _tab(Icons.notes_rounded, "Açıklama"),
              _tab(Icons.bar_chart_rounded, "Rapor"),
              _tab(Icons.percent_rounded, "Vergi"),
              _tab(Icons.view_list_outlined, "Detaylar"),
            ],
          )),
    );
  }

  Tab _tab(IconData icon, String label) {
    return Tab(
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: _scheme.surface,
        border: Border(top: BorderSide(color: _scheme.outlineVariant)),
      ),
      child: SizedBox(
        height: 52,
        child: PermissionAction(
            modules: [101],
            access: isEdit ? Access.update : Access.create,
            child: ElevatedButton.icon(
              onPressed: saving ? null : save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _scheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              icon: Icon(isEdit ? Icons.save_outlined : Icons.check_rounded,
                  size: 20),
              label: Text(
                isEdit ? "Değişiklikleri kaydet" : "Stok kartını oluştur",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )),
      ),
    );
  }

  // ── TABS ──────────────────────────────────────────────────────────────────

  Widget _genelTab() => _tabScroll([
        _section("Temel Bilgiler", Icons.inventory_2_outlined, [
          TextFormField(
            controller: kodCtrl,
            enabled: !isEdit,
            decoration: _dec("Stok Kodu *", Icons.tag_rounded),
            validator: (v) =>
                v == null || v.trim().isEmpty ? "Zorunlu alan" : null,
          ),
          _input(adCtrl, "Stok Adı", Icons.label_outline_rounded),
          _input(yabanciAdCtrl, "Yabancı Ad", Icons.translate_rounded,
              required: false),
        ]),
        _section("Sınıflandırma", Icons.tune_rounded, [
          if (olcuList.isNotEmpty)
            DropdownButtonFormField<OlcubrDto>(
              value: seciliOlcu,
              isExpanded: true,
              decoration: _dec("Temel Ölçü Birimi", Icons.straighten_rounded),
              items: olcuList
                  .map((o) => DropdownMenuItem<OlcubrDto>(
                        value: o,
                        child:
                            Text(o.Ad ?? "-", overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => seciliOlcu = v),
            ),
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: seciliKartTuru,
            decoration: _dec("Kart Türü", Icons.credit_card_outlined),
            items: StokCouples.kartTurleri
                .map((e) => DropdownMenuItem<int>(
                      value: e.value,
                      child: Text(e.text, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => seciliKartTuru = v),
          ),
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: seciliStokTuru,
            decoration: _dec("Stok Türü", Icons.category_outlined),
            items: StokCouples.stokTurleri
                .map((e) => DropdownMenuItem<int>(
                      value: e.value,
                      child: Text(e.text, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => seciliStokTuru = v),
          ),
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: seciliTakipSekli,
            decoration: _dec("Takip Şekli", Icons.track_changes_rounded),
            items: StokCouples.takipSekilleri
                .map((e) => DropdownMenuItem<int>(
                      value: e.value,
                      child: Text(e.text, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => seciliTakipSekli = v),
          ),
        ]),
      ]);

  Widget _aciklamaTab() => _tabScroll([
        _section("Açıklamalar", Icons.notes_rounded, [
          _input(aciklama1Ctrl, "Açıklama 1", Icons.short_text_rounded,
              required: false, maxLines: 3),
          _input(aciklama2Ctrl, "Açıklama 2", Icons.short_text_rounded,
              required: false, maxLines: 3),
          _input(aciklama3Ctrl, "Açıklama 3", Icons.short_text_rounded,
              required: false, maxLines: 3),
        ]),
      ]);

  Widget _raporTab() => _tabScroll([
        _section("Gruplama & Kodlar", Icons.label_outline_rounded, [
          if (kategoriList.isNotEmpty)
            DropdownButtonFormField<StokkategoriDto>(
              value: seciliKategori,
              isExpanded: true,
              decoration: _dec("Stok Kategorisi", Icons.folder_outlined),
              items: kategoriList
                  .map((k) => DropdownMenuItem<StokkategoriDto>(
                        value: k,
                        child:
                            Text(k.Ad ?? "-", overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => seciliKategori = v),
            ),
          _input(grupKoduCtrl, "Grup Kodu", Icons.folder_outlined,
              required: false),
          _input(kod1Ctrl, "Kod 1", Icons.tag_rounded, required: false),
          _input(kod2Ctrl, "Kod 2", Icons.tag_rounded, required: false),
          _input(kod3Ctrl, "Kod 3", Icons.tag_rounded, required: false),
          _input(kod4Ctrl, "Kod 4", Icons.tag_rounded, required: false),
          _input(kod5Ctrl, "Kod 5", Icons.tag_rounded, required: false),
        ]),
      ]);

  Widget _vergiTab() => _tabScroll([
        _section("Vergi Oranları", Icons.receipt_long_outlined, [
          _input(kdvAlisCtrl, "KDV Alış", Icons.percent_rounded,
              required: false),
          _input(kdvSatisCtrl, "KDV Satış", Icons.percent_rounded,
              required: false),
          _input(tevkifatCtrl, "Tevkifat Oranı", Icons.percent_rounded,
              required: false),
          _extraFields(stockExtraFields.take(4)),
        ]),
      ]);

  Widget _extraFields(Iterable<RecordField> fields) => ErpRecordFields(
      controller: extra,
      fields: fields.toList(),
      lookup: fieldsService.choices,
      prefix: 'stock-extra');
  Widget _extraGroup(String title, List<RecordField> fields) => Material(
      color: _scheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
          key: ValueKey('stock-group-$title'),
          maintainState: true,
          title: Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          children: [
            Padding(
                padding: const EdgeInsets.all(14), child: _extraFields(fields))
          ]));
  Widget _detailsTab() => _tabScroll([
        _extraGroup(
            'Kullanım ve Takip',
            stockExtraFields
                .where((f) =>
                    f.type == RecordFieldType.flag ||
                    f.key == 'Partiseritakipmodu')
                .toList()),
        _extraGroup(
            'Ölçüler ve Üretim',
            stockExtraFields
                .where((f) => [
                      'En',
                      'Boy',
                      'Derinlik',
                      'Ebatbr',
                      'Agirlik',
                      'Agirlikbr',
                      'Eticaretmiktar',
                      'Uretimyeri',
                      'Uretimmetodu',
                      'Uretimtarihi',
                      'Etiketolcubrid'
                    ].contains(f.key))
                .toList()),
        _extraGroup('Depolar',
            stockExtraFields.where((f) => f.lookup == 'depot').toList()),
        StockCardRows(
            controller: rows,
            service: fieldsService,
            enabled: AuthorizationSession.instance
                .can(101, isEdit ? Access.update : Access.create)),
        _extraGroup(
            'Muhasebe ve Ortak Kod',
            stockExtraFields
                .where((f) =>
                    f.lookup == 'account' ||
                    ['Muhkodu', 'Ortakkod'].contains(f.key))
                .toList()),
      ]);

  // ── HELPERS ───────────────────────────────────────────────────────────────

  Widget _tabScroll(List<Widget> sections) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      child: Column(
        children: sections
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 17, color: _accent),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: _scheme.surfaceContainerLow, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
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
      keyboardType: maxLines > 1
          ? TextInputType.multiline
          : [kdvAlisCtrl, kdvSatisCtrl, tevkifatCtrl].contains(ctrl)
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: _dec(required ? '$label *' : label, icon),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? "Zorunlu alan" : null
          : null,
    );
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      prefixIcon: Icon(icon, size: 18, color: _scheme.onSurfaceVariant),
      filled: true,
      fillColor: _background,
      labelStyle: TextStyle(fontSize: 13, color: _scheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _accent),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
    );
  }
}
