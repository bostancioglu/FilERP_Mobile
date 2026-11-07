import '../../../widgets/finance_extra_fields.dart';
import '../../../widgets/erp_record_fields.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../../widgets/popup_kapat_basligi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../models/entities/finans/banka/bankahesap_dto.dart';
import '../../../models/entities/finans/banka/bankahesap_create_dto.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../models/entities/helper/banka_master_dto.dart';
import '../../../models/entities/muhasebe/hesapplani_dto.dart';
import '../../../services/finans/bankahesap_service.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../services/helper/banka_master_service.dart';
import '../../../services/muhasebe/hesapplani_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../services/offline/offline_service.dart';
import '../../../helpers/banka_couples.dart';

const _kMuavin = Color(0xFF044DAC);
String _hesapStr(HesapplaniDto? h) =>
    h == null ? '' : '(${h.kod ?? ''}) ${h.ad ?? ''}';

class BankaTanimEklePage extends StatefulWidget {
  final BankahesapDto? editBanka;
  const BankaTanimEklePage({super.key, this.editBanka});

  @override
  State<BankaTanimEklePage> createState() => _BankaTanimEklePageState();
}

class _BankaTanimEklePageState extends State<BankaTanimEklePage> {
  Color get _kRed => Theme.of(context).colorScheme.primary;
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  final _formKey = GlobalKey<FormState>();
  bool get _isEdit => widget.editBanka != null;

  final _kodCtrl = TextEditingController();
  final _adCtrl = TextEditingController();
  final _hesapnoCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _ortakkodCtrl = TextEditingController();
  final _muhasebeOrtakkodCtrl = TextEditingController();

  List<DovizDto> _dovizler = [];
  List<BankaMasterDto> _bankalar = [];
  List<BankasubeMasterDto> _subeler = [];
  List<HesapplaniDto> _hesaplar = [];

  DovizDto? _seciliDoviz;
  BankaMasterDto? _seciliBanka;
  BankasubeMasterDto? _seciliSube;
  int? _seciliHesaptipi;
  HesapplaniDto? _seciliHesap;
  HesapplaniDto? _seciliKomisyon;
  HesapplaniDto? _seciliBsmv;
  HesapplaniDto? _seciliKurGelir;
  HesapplaniDto? _seciliKurGider;

  late final _extraAccounts =
      RecordFieldsController(bankAccountExtraFields, initial: {
    'Faizhesapplaniid': widget.editBanka?.Faizhesapplaniid,
    'Kkdfhesapplaniid': widget.editBanka?.Kkdfhesapplaniid,
    'Cezahesapplaniid': widget.editBanka?.Cezahesapplaniid,
  })
        ..addListener(_extraChanged);
  void _extraChanged() {
    if (mounted) setState(() {});
  }

  bool _ortakkoduvar = false;
  bool _loading = true;
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
    _extraAccounts.dispose();
    _kodCtrl.dispose();
    _adCtrl.dispose();
    _hesapnoCtrl.dispose();
    _ibanCtrl.dispose();
    _ortakkodCtrl.dispose();
    _muhasebeOrtakkodCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';

    final results = await Future.wait([
      DovizService().getDovizler(token).catchError((_) => <DovizDto>[]),
      BankaMasterService()
          .getBankalar(token)
          .catchError((_) => <BankaMasterDto>[]),
      HesapplaniService().getAll(token).catchError((_) => <HesapplaniDto>[]),
    ]);

    if (!mounted) return;
    _dovizler = results[0] as List<DovizDto>;
    _bankalar = results[1] as List<BankaMasterDto>;
    _hesaplar = results[2] as List<HesapplaniDto>;

    setState(() => _loading = false);
    if (_isEdit) {
      _fillEdit();
    } else if (_seciliDoviz == null) {
      setState(() =>
          _seciliDoviz = _dovizler.where((d) => _birimTL(d.Birim)).firstOrNull);
    }
  }

  void _fillEdit() {
    final b = widget.editBanka!;
    _kodCtrl.text = b.Kod ?? '';
    _adCtrl.text = b.Ad ?? '';
    _hesapnoCtrl.text = b.Hesapno ?? '';
    _ibanCtrl.text = b.Iban ?? '';
    _ortakkodCtrl.text = b.Ortakkod ?? '';
    _muhasebeOrtakkodCtrl.text = b.Muhasebeortakkod ?? '';
    _ortakkoduvar = b.Ortakkoduvar ?? false;
    for (final field in bankAccountExtraFields) {
      final account = _hesaplar
          .where((h) => h.id == _extraAccounts.values[field.key])
          .firstOrNull;
      if (account != null)
        _extraAccounts.labels[field.key] = _hesapStr(account);
    }

    setState(() {
      _seciliDoviz = _dovizler.where((d) => d.Id == b.Dovizid).firstOrNull;
      _seciliBanka = _bankalar.where((x) => x.Id == b.Bankaid).firstOrNull;
      _seciliHesaptipi = b.Hesaptipi;
      _seciliHesap = _hesaplar.where((h) => h.id == b.Hesapplaniid).firstOrNull;
      _seciliKomisyon =
          _hesaplar.where((h) => h.id == b.Komisyonhesapplaniid).firstOrNull;
      _seciliBsmv =
          _hesaplar.where((h) => h.id == b.Bsmvhesapplaniid).firstOrNull;
      _seciliKurGelir = _hesaplar
          .where((h) => h.id == b.Kurfarkigelirhesapplaniid)
          .firstOrNull;
      _seciliKurGider = _hesaplar
          .where((h) => h.id == b.Kurfarkigiderhesapplaniid)
          .firstOrNull;
    });

    if (b.Bankaid != null) _loadSubeler(b.Bankaid!, editSubeId: b.Bankasubeid);
  }

  Future<void> _loadSubeler(int bankaid, {int? editSubeId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    try {
      final list =
          await BankaMasterService().getSubeler(token, bankaid: bankaid);
      if (!mounted) return;
      setState(() {
        _subeler = list;
        if (editSubeId != null) {
          _seciliSube = list.where((s) => s.Id == editSubeId).firstOrNull;
        }
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_seciliDoviz == null) {
      UiFeedback.showError(context, 'Lütfen döviz seçiniz.');
      return;
    }
    if (_seciliBanka == null) {
      UiFeedback.showError(context, 'Lütfen banka seçiniz.');
      return;
    }

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final dto = BankahesapCreateDto(
        Id: _isEdit ? widget.editBanka!.Id : null,
        Dovizid: _seciliDoviz!.Id,
        Bankaid: _seciliBanka!.Id,
        Bankasubeid: _seciliSube?.Id,
        Hesapplaniid: _seciliHesap?.id,
        Komisyonhesapplaniid: _seciliKomisyon?.id,
        Bsmvhesapplaniid: _seciliBsmv?.id,
        Faizhesapplaniid: _extraAccounts.values['Faizhesapplaniid'],
        Kkdfhesapplaniid: _extraAccounts.values['Kkdfhesapplaniid'],
        Cezahesapplaniid: _extraAccounts.values['Cezahesapplaniid'],
        Kurfarkigelirhesapplaniid: _isDovizli ? _seciliKurGelir?.id : null,
        Kurfarkigiderhesapplaniid: _isDovizli ? _seciliKurGider?.id : null,
        Ad: _adCtrl.text.trim(),
        Kod: _kodCtrl.text.trim(),
        Hesapno:
            _hesapnoCtrl.text.trim().isEmpty ? null : _hesapnoCtrl.text.trim(),
        Iban: _ibanCtrl.text.trim().isEmpty ? null : _ibanCtrl.text.trim(),
        Hesaptipi: _seciliHesaptipi,
        Ortakkoduvar: _ortakkoduvar,
        Ortakkod: _ortakkoduvar ? _ortakkodCtrl.text.trim() : null,
        Muhasebeortakkod:
            _ortakkoduvar ? _muhasebeOrtakkodCtrl.text.trim() : null,
      );
      final manuelOffline = await OfflineService.instance.getOfflineMode();
      final internetYok = !OfflineService.instance.isOnline.value;
      if (manuelOffline || internetYok) {
        await OfflineService.instance.enqueue('single_full', {
          'endpoint': '/Bankahesap',
          'method': _isEdit ? 'PUT' : 'POST',
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

      final svc = BankahesapService();
      if (_isEdit) {
        await svc.update(token, dto);
      } else {
        await svc.create(token, dto);
      }
      if (!mounted) return;
      UiFeedback.showSuccess(context,
          _isEdit ? 'Banka hesabı güncellendi.' : 'Banka hesabı oluşturuldu.',
          autoPop: true);
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      bottomNavigationBar: _loading
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
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildSection('Temel Bilgiler', [
                    _buildTextField(_kodCtrl, 'Hesap Kodu',
                        required: true, caps: TextCapitalization.characters),
                    SizedBox(height: 10),
                    _buildTextField(_adCtrl, 'Hesap Adı', required: true),
                    SizedBox(height: 10),
                    _buildDovizDropdown(),
                    SizedBox(height: 10),
                    _buildHesaptipiDropdown(),
                  ]),
                  SizedBox(height: 10),
                  _buildSection('Banka Bilgileri', [
                    _buildBankaDropdown(),
                    SizedBox(height: 10),
                    _buildSubeDropdown(),
                    SizedBox(height: 10),
                    _buildTextField(_hesapnoCtrl, 'Hesap Numarası'),
                    SizedBox(height: 10),
                    _buildTextField(_ibanCtrl, 'IBAN'),
                  ]),
                  SizedBox(height: 10),
                  _buildSection('Muhasebe', [
                    ErpRecordFields(
                        controller: _extraAccounts,
                        lookup: financeFieldChoices,
                        prefix: 'bank-account'),
                    _buildHesapDropdown(
                        label: 'Muhasebe Kodu',
                        value: _seciliHesap,
                        onChanged: (v) => setState(() => _seciliHesap = v)),
                    SizedBox(height: 10),
                    _buildHesapDropdown(
                        label: 'Komisyon Hesap Planı',
                        value: _seciliKomisyon,
                        onChanged: (v) => setState(() => _seciliKomisyon = v)),
                    SizedBox(height: 10),
                    _buildHesapDropdown(
                        label: 'BSMV Hesap Planı',
                        value: _seciliBsmv,
                        onChanged: (v) => setState(() => _seciliBsmv = v)),
                    if (_isDovizli) ...[
                      SizedBox(height: 10),
                      _buildHesapDropdown(
                          label: 'Kur Farkı Gelir Hesabı',
                          value: _seciliKurGelir,
                          onChanged: (v) =>
                              setState(() => _seciliKurGelir = v)),
                      SizedBox(height: 10),
                      _buildHesapDropdown(
                          label: 'Kur Farkı Gider Hesabı',
                          value: _seciliKurGider,
                          onChanged: (v) =>
                              setState(() => _seciliKurGider = v)),
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

  PreferredSizeWidget _buildAppBar() => ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isEdit ? 'Banka Hesabı Düzenle' : 'Yeni Banka Hesabı',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _scheme.onSurface)),
        ]),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _scheme.surfaceContainerLow)),
      );

  Widget _buildSection(String title, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: _scheme.surface,
          borderRadius:
              BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .015),
                blurRadius: 10,
                offset: Offset(0, 3))
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

  Widget _buildTextField(TextEditingController ctrl, String label,
          {bool required = false,
          TextCapitalization caps = TextCapitalization.none}) =>
      TextFormField(
        controller: ctrl,
        textCapitalization: caps,
        style: TextStyle(
            fontFamily: 'Roboto', fontSize: 14, color: _scheme.onSurface),
        decoration: _dec(label, required: required),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? '$label boş olamaz' : null
            : null,
      );

  Widget _buildDovizDropdown() => DropdownButtonFormField<DovizDto>(
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
          if (!_isDovizli) {
            _seciliKurGelir = null;
            _seciliKurGider = null;
          }
        }),
        validator: (v) => v == null ? 'Döviz seçiniz' : null,
      );

  Widget _buildHesaptipiDropdown() => DropdownButtonFormField<int>(
        value: _seciliHesaptipi,
        decoration: _dec('Hesap Tipi'),
        style: TextStyle(
            fontFamily: 'Roboto', fontSize: 14, color: _scheme.onSurface),
        isExpanded: true,
        items: BankaHesaptipiCouples.list
            .map((e) => DropdownMenuItem(
                value: e.value,
                child: Text(e.text,
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 13))))
            .toList(),
        onChanged: (v) => setState(() => _seciliHesaptipi = v),
      );

  Widget _buildBankaDropdown() => DropdownSearch<BankaMasterDto>(
        items: _bankalar,
        selectedItem: _seciliBanka,
        itemAsString: (b) => '${b.Ad ?? ''} (${b.Kod ?? ''})',
        compareFn: (a, b) => a.Id == b.Id,
        filterFn: (b, q) =>
            (b.Ad ?? '').toLowerCase().contains(q.toLowerCase()) ||
            (b.Kod ?? '').toLowerCase().contains(q.toLowerCase()),
        onChanged: (v) {
          setState(() {
            _seciliBanka = v;
            _seciliSube = null;
            _subeler = [];
          });
          if (v?.Id != null) _loadSubeler(v!.Id!);
        },
        popupProps: const PopupProps.bottomSheet(
          title: PopupKapatBasligi(),
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                  hintText: 'Banka ara...',
                  prefixIcon: Icon(Icons.search_rounded, size: 18))),
          bottomSheetProps: BottomSheetProps(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              constraints: BoxConstraints(maxHeight: 480)),
        ),
        dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: _dec('Banka', required: true)),
        clearButtonProps: ClearButtonProps(isVisible: true),
      );

  Widget _buildSubeDropdown() => DropdownSearch<BankasubeMasterDto>(
        items: _subeler,
        selectedItem: _seciliSube,
        itemAsString: (s) => '${s.Ad ?? ''} (${s.Kod ?? ''})',
        compareFn: (a, b) => a.Id == b.Id,
        onChanged: (v) => setState(() => _seciliSube = v),
        enabled: _seciliBanka != null,
        popupProps: const PopupProps.bottomSheet(
          title: PopupKapatBasligi(),
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                  hintText: 'Şube ara...',
                  prefixIcon: Icon(Icons.search_rounded, size: 18))),
          bottomSheetProps: BottomSheetProps(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              constraints: BoxConstraints(maxHeight: 420)),
        ),
        dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: _dec('Banka Şubesi')),
        clearButtonProps: ClearButtonProps(isVisible: true),
      );

  Widget _buildHesapDropdown({
    required String label,
    required HesapplaniDto? value,
    required ValueChanged<HesapplaniDto?> onChanged,
  }) =>
      DropdownSearch<HesapplaniDto>(
        items: _hesaplar,
        selectedItem: value,
        itemAsString: _hesapStr,
        compareFn: (a, b) => a.id == b.id,
        filterFn: (h, q) {
          final s = q.toLowerCase();
          return (h.kod ?? '').toLowerCase().contains(s) ||
              (h.ad ?? '').toLowerCase().contains(s);
        },
        onChanged: (selected) {
          if (selected == null) {
            onChanged(null);
            return;
          }
          if (selected.tur != 5) {
            UiFeedback.showError(
                context, 'Muavin Hesap Planı Seçmeniz Gerekmektedir.',
                duration: Duration(seconds: 3));
            onChanged(value);
            return;
          }
          onChanged(selected);
        },
        popupProps: PopupProps.bottomSheet(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                  hintText: 'Hesap kodu veya adı...',
                  prefixIcon: Icon(Icons.search_rounded, size: 18))),
          bottomSheetProps: BottomSheetProps(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              constraints: BoxConstraints(maxHeight: 580)),
          itemBuilder: (ctx, h, isSel) => _buildHesapItem(h, isSel),
          title: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _scheme.onSurface))),
                Builder(
                    builder: (ctx) => IconButton(
                          icon: Icon(Icons.close_rounded),
                          tooltip: 'Kapat',
                          onPressed: () => Navigator.of(ctx).pop(),
                        )),
              ]),
              SizedBox(height: 10),
              Row(children: [
                SizedBox(
                    width: 72,
                    child: Text('Kod',
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _scheme.onSurfaceVariant))),
                SizedBox(width: 10),
                SizedBox(
                    width: 140,
                    child: Text('Hesap Planı Adı',
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _scheme.onSurfaceVariant))),
                Spacer(),
                Text('Tür',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _scheme.onSurfaceVariant)),
              ]),
              Divider(height: 10),
            ]),
          ),
        ),
        dropdownDecoratorProps:
            DropDownDecoratorProps(dropdownSearchDecoration: _dec(label)),
        clearButtonProps: ClearButtonProps(isVisible: true),
      );

  Widget _buildHesapItem(HesapplaniDto h, bool isSelected) {
    final isMuavin = h.tur == 5;
    final itemBg = isSelected
        ? _kRed.withValues(alpha: 0.08)
        : isMuavin
            ? Color(0xFFCCD7FF).withValues(alpha: 0.4)
            : Colors.transparent;
    return Container(
      color: itemBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        SizedBox(
            width: 72,
            child: Text(h.kod ?? '',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isMuavin ? _kMuavin : _scheme.onSurface,
                    fontFamily: 'Roboto'))),
        SizedBox(width: 10),
        Expanded(
            child: Text(h.ad ?? '',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: isMuavin ? _kMuavin : _scheme.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis)),
        SizedBox(width: 8),
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
              color: isMuavin ? Color(0xFFCCD7FF) : _scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6)),
          child: Text(HesapplaniTuruCouples.adByValue(h.tur),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isMuavin ? _kMuavin : _scheme.onSurfaceVariant)),
        ),
      ]),
    );
  }

  Widget _buildOrtakKodSection() => Container(
        decoration: BoxDecoration(
          color: _scheme.surface,
          borderRadius:
              BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .015),
                blurRadius: 10,
                offset: Offset(0, 3))
          ],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(children: [
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
                  ])),
              Switch(
                  value: _ortakkoduvar,
                  activeColor: _kRed,
                  onChanged: (v) => setState(() => _ortakkoduvar = v)),
            ]),
          ),
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
        ]),
      );

  Widget _buildSaveButton() => SizedBox(
        width: double.infinity,
        height: 52,
        child: PermissionAction(
            modules: [1002],
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
                  : Icon(_isEdit ? Icons.save_rounded : Icons.add_rounded,
                      size: 20),
              label: Text(
                  _saving
                      ? 'Kaydediliyor...'
                      : (_isEdit ? 'Güncelle' : 'Hesap Oluştur'),
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              onPressed: _saving ? null : _save,
            )),
      );
}
