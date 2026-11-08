import '../../../widgets/finance_extra_fields.dart';
import '../../../widgets/erp_record_fields.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../models/entities/finans/kasa_islem/kasa_dto.dart';
import '../../../models/entities/finans/kasa_islem/kasa_create_dto.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../models/entities/muhasebe/hesapplani_dto.dart';
import '../../../services/finans/kasa_tanim_service.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../services/muhasebe/hesapplani_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../services/offline/offline_service.dart';

const _kMuavin = Color(0xFF044DAC); // Web'deki muavin mavi rengi

const _turAdlari = <int, String>{
  1: 'Bilanço Ana',
  2: 'Bilanço Grup',
  3: 'Ana',
  4: 'Grup',
  5: 'Muavin',
};

String _turAdi(int? tur) => _turAdlari[tur] ?? '?';

// Seçili değer gösterimi: "(100) Kasa Hesabı"
String _hesapStr(HesapplaniDto? h) =>
    h == null ? '' : '(${h.kod ?? ''}) ${h.ad ?? ''}';

class KasaTanimEklePage extends StatefulWidget {
  final KasaDto? editKasa;

  const KasaTanimEklePage({super.key, this.editKasa});

  @override
  State<KasaTanimEklePage> createState() => _KasaTanimEklePageState();
}

class _KasaTanimEklePageState extends State<KasaTanimEklePage> {
  Color get _kRed => Theme.of(context).colorScheme.primary;
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  final _formKey = GlobalKey<FormState>();

  bool get isEdit => widget.editKasa != null;

  final _kodCtrl = TextEditingController();
  final _adCtrl = TextEditingController();
  final _ortakkodCtrl = TextEditingController();
  final _muhasebeOrtakkodCtrl = TextEditingController();

  List<DovizDto> _dovizler = [];
  List<HesapplaniDto> _hesaplar = [];
  DovizDto? _seciliDoviz;
  HesapplaniDto? _seciliHesap;
  HesapplaniDto? _seciliKurGelir;
  HesapplaniDto? _seciliKurGider;

  late final _salesperson =
      RecordFieldsController(cashSalespersonFields, initial: {
    'Plasiyerkasasi': widget.editKasa?.Plasiyerkasasi,
    'Plasiyerid': widget.editKasa?.Plasiyerid
  })
        ..addListener(_extraChanged);
  void _extraChanged() {
    if (mounted) setState(() {});
  }

  bool _ortakkoduvar = false;
  bool _loadingDoviz = false;
  bool _loadingHesap = false;
  bool _saving = false;

  static bool _birimTL(String? birim) {
    final b = (birim ?? '').trim().toUpperCase();
    return b == 'TL' || b == 'TRY' || b == '₺';
  }

  bool get _isDovizli => _seciliDoviz != null && !_birimTL(_seciliDoviz!.Birim);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _salesperson.dispose();
    _kodCtrl.dispose();
    _adCtrl.dispose();
    _ortakkodCtrl.dispose();
    _muhasebeOrtakkodCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingDoviz = true;
      _loadingHesap = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';

    final results = await Future.wait([
      DovizService().getDovizler(token).catchError((_) => <DovizDto>[]),
      HesapplaniService().getAll(token).catchError((_) => <HesapplaniDto>[]),
    ]);

    if (!mounted) return;

    final dovizler = results[0] as List<DovizDto>;
    final hesaplar = results[1] as List<HesapplaniDto>;

    setState(() {
      _dovizler = dovizler;
      _hesaplar = hesaplar;
      _loadingDoviz = false;
      _loadingHesap = false;
    });

    if (isEdit) {
      _fillEdit();
    } else if (_seciliDoviz == null) {
      setState(() =>
          _seciliDoviz = _dovizler.where((d) => _birimTL(d.Birim)).firstOrNull);
    }
  }

  void _fillEdit() {
    final k = widget.editKasa!;
    _kodCtrl.text = k.Kod ?? '';
    _adCtrl.text = k.Ad ?? '';
    _ortakkodCtrl.text = k.Ortakkod ?? '';
    _muhasebeOrtakkodCtrl.text = k.Muhasebeortakkod ?? '';
    _ortakkoduvar = k.Ortakkoduvar ?? false;

    setState(() {
      _seciliDoviz = _dovizler.where((d) => d.Id == k.Dovizid).firstOrNull;
      _seciliHesap = _hesaplar.where((h) => h.id == k.Hesapplaniid).firstOrNull;
      _seciliKurGelir = _hesaplar
          .where((h) => h.id == k.Kurfarkigelirhesapplaniid)
          .firstOrNull;
      _seciliKurGider = _hesaplar
          .where((h) => h.id == k.Kurfarkigiderhesapplaniid)
          .firstOrNull;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_seciliDoviz == null) {
      UiFeedback.showError(context, 'Lütfen döviz seçiniz.');
      return;
    }

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final dto = KasaCreateDto(
        Id: isEdit ? widget.editKasa!.Id : null,
        Plasiyerkasasi: _salesperson.values['Plasiyerkasasi'] == true,
        Plasiyerid: _salesperson.values['Plasiyerkasasi'] == true
            ? _salesperson.values['Plasiyerid']
            : null,
        Dovizid: _seciliDoviz!.Id,
        Hesapplaniid: _seciliHesap?.id,
        Kurfarkigelirhesapplaniid: _isDovizli ? _seciliKurGelir?.id : null,
        Kurfarkigiderhesapplaniid: _isDovizli ? _seciliKurGider?.id : null,
        Ad: _adCtrl.text.trim(),
        Kod: _kodCtrl.text.trim(),
        Ortakkoduvar: _ortakkoduvar,
        Ortakkod: _ortakkoduvar ? _ortakkodCtrl.text.trim() : null,
        Muhasebeortakkod:
            _ortakkoduvar ? _muhasebeOrtakkodCtrl.text.trim() : null,
      );

      final manuelOffline = await OfflineService.instance.getOfflineMode();
      final internetYok = !OfflineService.instance.isOnline.value;
      if (manuelOffline || internetYok) {
        await OfflineService.instance.enqueue('single_full', {
          'endpoint': '/Kasa',
          'method': isEdit ? 'PUT' : 'POST',
          'body': dto.toJson(),
        });
        if (!mounted) return;
        UiFeedback.showSuccess(
          context,
          internetYok
              ? 'İnternet yok — kayıt kuyruğa alındı, bağlantı gelince gönderilecek'
              : 'Kayıt kuyruğa eklendi — online olunca gönderilecek',
          autoPop: true,
        );
        return;
      }

      final svc = KasaTanimService();
      if (isEdit) {
        await svc.update(token, dto);
      } else {
        await svc.create(token, dto);
      }

      if (!mounted) return;
      UiFeedback.showSuccess(
        context,
        isEdit ? 'Kasa güncellendi.' : 'Kasa oluşturuldu.',
        autoPop: true,
      );
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Dekorasyon ──────────────────────────────────────────────────────────────
  InputDecoration _dec(String label, {bool required = false}) =>
      InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            color: _scheme.onSurfaceVariant),
        filled: true,
        fillColor: _background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _kRed, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
      );

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      bottomNavigationBar: (_loadingDoviz || _loadingHesap)
          ? null
          : Container(
              color: _scheme.surface,
              child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: _buildSaveButton(),
                  )),
            ),
      body: (_loadingDoviz || _loadingHesap)
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildSection('Temel Bilgiler', [
                    _buildTextField(_kodCtrl, 'Kasa Kodu',
                        required: true, caps: TextCapitalization.characters),
                    SizedBox(height: 10),
                    _buildTextField(_adCtrl, 'Kasa Adı', required: true),
                    SizedBox(height: 10),
                    _buildDovizDropdown(),
                    Material(
                        color: Colors.transparent,
                        child: ErpRecordFields(
                            controller: _salesperson,
                            fields: [
                              cashSalespersonFields.first,
                              if (_salesperson.values['Plasiyerkasasi'] == true)
                                cashSalespersonFields.last
                            ],
                            lookup: financeFieldChoices,
                            prefix: 'cash-owner')),
                  ]),
                  SizedBox(height: 10),
                  _buildSection('Muhasebe', [
                    _buildHesapDropdown(
                      label: 'Muhasebe Kodu',
                      value: _seciliHesap,
                      onChanged: (v) => setState(() => _seciliHesap = v),
                    ),
                    if (_isDovizli) ...[
                      SizedBox(height: 10),
                      _buildHesapDropdown(
                        label: 'Kur Farkı Gelir Hesabı',
                        value: _seciliKurGelir,
                        onChanged: (v) => setState(() => _seciliKurGelir = v),
                      ),
                      SizedBox(height: 10),
                      _buildHesapDropdown(
                        label: 'Kur Farkı Gider Hesabı',
                        value: _seciliKurGider,
                        onChanged: (v) => setState(() => _seciliKurGider = v),
                      ),
                    ],
                  ]),
                  SizedBox(height: 10),
                  _buildOrtakKodSection(),
                  SizedBox(height: 4),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ErpPageAppBar(
      context: context,
      backgroundColor: _scheme.surface,
      foregroundColor: _scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? 'Kasa Düzenle' : 'Yeni Kasa',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _scheme.onSurface),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _scheme.surfaceContainerLow),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .015),
              blurRadius: 10,
              offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _scheme.onSurfaceVariant,
                letterSpacing: 0.6)),
        SizedBox(height: 10),
        ...children,
      ]),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextCapitalization caps = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: ctrl,
      textCapitalization: caps,
      style: TextStyle(
          fontFamily: 'Roboto', fontSize: 14, color: _scheme.onSurface),
      decoration: _dec(label, required: required),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label boş olamaz' : null
          : null,
    );
  }

  Widget _buildDovizDropdown() {
    return DropdownButtonFormField<DovizDto>(
      value: _seciliDoviz,
      decoration: _dec('Döviz', required: true),
      style: TextStyle(
          fontFamily: 'Roboto', fontSize: 14, color: _scheme.onSurface),
      isExpanded: true,
      items: _dovizler
          .map((d) => DropdownMenuItem(
                value: d,
                child: Text('${d.Birim ?? ''} — ${d.Ad ?? ''}',
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 14)),
              ))
          .toList(),
      onChanged: (v) => setState(() {
        _seciliDoviz = v;
        // Döviz TL'ye döndüyse kur farkı hesaplarını temizle
        if (!_isDovizli) {
          _seciliKurGelir = null;
          _seciliKurGider = null;
        }
      }),
      validator: (v) => v == null ? 'Döviz seçiniz' : null,
    );
  }

  Widget _buildHesapDropdown({
    required String label,
    required HesapplaniDto? value,
    required ValueChanged<HesapplaniDto?> onChanged,
  }) {
    return DropdownSearch<HesapplaniDto>(
      items: _hesaplar,
      selectedItem: value,
      // Seçili gösterim: "(100) Kasa Hesabı"
      itemAsString: _hesapStr,
      compareFn: (a, b) => a.id == b.id,
      // Kod VE ad'a göre ara
      filterFn: (h, filter) {
        final q = filter.toLowerCase();
        return (h.kod ?? '').toLowerCase().contains(q) ||
            (h.ad ?? '').toLowerCase().contains(q);
      },
      onChanged: (selected) {
        if (selected == null) {
          onChanged(null);
          return;
        }
        // Muavin (Tur=5) zorunlu — web'deki aynı kontrol
        if (selected.tur != 5) {
          UiFeedback.showError(
            context,
            'Muavin Hesap Planı Seçmeniz Gerekmektedir.',
            duration: Duration(seconds: 3),
          );
          // Önceki geçerli değere geri dön
          onChanged(value);
          return;
        }
        onChanged(selected);
      },
      popupProps: PopupProps.bottomSheet(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Hesap kodu veya adı ile ara...',
            prefixIcon: Icon(Icons.search_rounded, size: 18),
          ),
        ),
        bottomSheetProps: BottomSheetProps(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(maxHeight: 580),
        ),
        itemBuilder: (ctx, h, isSelected) => _buildHesapItem(h, isSelected),
        emptyBuilder: (_, __) => Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text('Sonuç bulunamadı',
                style: TextStyle(
                    fontFamily: 'Roboto', color: Colors.grey, fontSize: 13)),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _scheme.onSurface)),
                ),
                Builder(
                    builder: (ctx) => IconButton(
                          icon: Icon(Icons.close_rounded),
                          tooltip: 'Kapat',
                          onPressed: () => Navigator.of(ctx).pop(),
                        )),
              ]),
              SizedBox(height: 10),
              // Sabit genişlikli sütun başlıkları (Expanded yok)
              Row(children: [
                SizedBox(
                  width: 72,
                  child: Text('Kod',
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _scheme.onSurfaceVariant)),
                ),
                SizedBox(width: 10),
                SizedBox(
                  width: 140,
                  child: Text('Hesap Planı Adı',
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _scheme.onSurfaceVariant)),
                ),
                Spacer(),
                Text('Tür',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _scheme.onSurfaceVariant)),
              ]),
              Divider(height: 10),
            ],
          ),
        ),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: _dec(label),
      ),
      clearButtonProps: ClearButtonProps(isVisible: true),
    );
  }

  Widget _buildHesapItem(HesapplaniDto h, bool isSelected) {
    final isMuavin = h.tur == 5;
    final itemBg = isSelected
        ? _kRed.withValues(alpha: 0.08)
        : isMuavin
            ? Color(0xFFCCD7FF).withValues(alpha: 0.4)
            : Colors.transparent;
    final kodColor = isMuavin ? _kMuavin : _scheme.onSurface;
    final adColor = isMuavin ? _kMuavin : _scheme.onSurface;
    final turAdi = _turAdi(h.tur);
    final turColor = isMuavin ? _kMuavin : _scheme.onSurfaceVariant;
    final turBg = isMuavin ? Color(0xFFCCD7FF) : _scheme.surfaceContainerLow;

    return Container(
      color: itemBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Hesap Kodu
          SizedBox(
            width: 72,
            child: Text(
              h.kod ?? '',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kodColor,
                  fontFamily: 'Roboto'),
            ),
          ),
          SizedBox(width: 10),
          // Hesap Adı
          Expanded(
            child: Text(
              h.ad ?? '',
              style:
                  TextStyle(fontFamily: 'Roboto', fontSize: 13, color: adColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          // Tür rozeti
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: turBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              turAdi,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: turColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrtakKodSection() {
    return Container(
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .015),
              blurRadius: 10,
              offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Switch satırı
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ortak Kod',
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _scheme.onSurface)),
                    ],
                  ),
                ),
                Switch(
                  value: _ortakkoduvar,
                  activeColor: _kRed,
                  onChanged: (v) => setState(() => _ortakkoduvar = v),
                ),
              ],
            ),
          ),

          // Koşullu alanlar
          if (_ortakkoduvar) ...[
            Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                _buildTextField(_ortakkodCtrl, 'Ortak Kod'),
                SizedBox(height: 10),
                _buildTextField(_muhasebeOrtakkodCtrl, 'Muhasebe Ortak Kodu'),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: PermissionAction(
          modules: [1001],
          access: Access.write,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _scheme.primary,
              foregroundColor: _scheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: _saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(isEdit ? Icons.save_rounded : Icons.add_rounded,
                    size: 20),
            label: Text(
              _saving
                  ? 'Kaydediliyor...'
                  : (isEdit ? 'Güncelle' : 'Kasa Oluştur'),
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            onPressed: _saving ? null : _save,
          )),
    );
  }
}
