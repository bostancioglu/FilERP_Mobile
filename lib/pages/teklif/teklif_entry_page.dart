import '../../widgets/commercial_document_fields.dart';
import '../../widgets/document_extra_notes.dart';
import '../../widgets/fatura/fatura_genel_iskonto_sheet.dart';
import 'package:FilERP/services/auth/menu_access.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../widgets/erp_page_style.dart';
import '../../models/entities/stok/stok_dto.dart';
import 'package:flutter/services.dart';
import '../../models/entities/cari/cariadres_dto.dart';
import '../../helpers/stokhareket_couples.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/belge_turu_couples.dart';
import '../../helpers/fatura_hesap_helper.dart';
import '../../helpers/number_format_helper.dart';
import '../../helpers/oncelik_couples.dart';
import '../../helpers/ui_feedback.dart';
import '../../helpers/varsayilan_proje_helper.dart';
import '../../models/entities/cari/cari_dto_lite.dart';
import '../../models/entities/depo/depo_dto.dart';
import '../../models/entities/helper/doviz_dto.dart';
import '../../models/entities/plasiyer/plasiyer_dto.dart';
import '../../models/entities/proje/proje_dto.dart';
import '../../models/entities/stok/stok_list_dto.dart';
import '../../models/entities/teklif/teklif_codec.dart';
import '../../models/entities/teklif/teklif_dto.dart';
import '../../models/entities/teklif/teklifhareket_dto.dart';
import '../../models/entities/yonetim/belge_seri_dto.dart';
import '../../services/cari/cari_service.dart';
import '../../services/depo/depo_service.dart';
import '../../services/helper/doviz_service.dart';
import '../../services/offline/offline_service.dart';
import '../../services/plasiyer/plasiyer_service.dart';
import '../../services/proje/proje_service.dart';
import '../../services/stok/stok_service.dart';
import '../../services/teklif/teklif_service.dart';
import '../../services/yonetim/belgeseri_service.dart';
import '../../widgets/erp_selector.dart';
import '../../widgets/erp_ui.dart';
import '../../widgets/siparis/siparis_kalem_form_sheet.dart';

class TeklifEntryPage extends StatefulWidget {
  final bool sales;
  final String? quoteId;
  const TeklifEntryPage({super.key, required this.sales, this.quoteId});
  @override
  State<TeklifEntryPage> createState() => _TeklifEntryPageState();
}

class _TeklifEntryPageState extends State<TeklifEntryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _number = TextEditingController();
  final _note = TextEditingController();
  final _rate = TextEditingController();
  final _deleted = <int>[];
  TeklifDto _quote = TeklifDto();
  List<CariDtoLite> _customers = [];
  List<CariadresDto> _addresses = [];
  List<StokListDto> _products = [];
  List<ProjeDto> _projects = [];
  List<DepoDto> _warehouses = [];
  List<PlasiyerDto> _representatives = [];
  List<DovizDto> _currencies = [];
  List<BelgeSeriDto> _series = [];
  bool _loading = true, _saving = false, _dirty = false, _failed = false;
  int _numberRequest = 0;
  TeklifService get _service => TeklifService(sales: widget.sales);
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  bool get _readOnly => (_quote.belgedurum ?? 0) != 0;
  List<TeklifhareketDto> get _lines => _quote.teklifhareket ??= [];
  String get _kind => widget.sales ? 'Satış' : 'Alış';
  DovizDto? get _currency =>
      _currencies.where((d) => d.Id == _quote.dovizid).firstOrNull;
  bool get _foreign =>
      !['', 'TL', 'TRY', '₺'].contains((_currency?.Birim ?? '').toUpperCase());

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this)..addListener(_tabChanged);
    final now = DateTime.now();
    _quote
      ..tarih = now
      ..fiilitarih = now
      ..teslimtarihi = now
      ..tahsilattarihi = now
      ..vadetarihi = now
      ..doviztarih = now
      ..vadegunu = 0
      ..belgetipi = 1
      ..odemesekli = 1
      ..oncelik = 4
      ..gecerliliktarihi = now.add(const Duration(days: 30))
      ..belgeyil = now.year
      ..belgeturu = widget.sales
          ? BelgeTuruCouples.satisTeklif
          : BelgeTuruCouples.alisTeklif
      ..belgedurum = 0
      ..kdvdahil = false
      ..kur = 1
      ..teklifhareket = [];
    _rate.text = '1,0000';
    _load();
  }

  void _tabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabs.removeListener(_tabChanged);
    _tabs.dispose();
    _number.dispose();
    _note.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<String> _token() async =>
      (await SharedPreferences.getInstance()).getString('token_final') ?? '';
  void _change(VoidCallback update) => setState(() {
        update();
        _dirty = true;
      });

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final data = await Future.wait<Object>([
        CariService().getCariler(token),
        StokService().getStokList(token),
        ProjeService().getProjeList(token),
        DepoService().getAllBySubeId(token, prefs.getInt('sube_id') ?? 0),
        PlasiyerService().getPlasiyerler(token),
        DovizService().getDovizler(token),
        BelgeSeriService().getAll(
            token,
            widget.sales
                ? BelgeTuruCouples.satisTeklif
                : BelgeTuruCouples.alisTeklif),
      ]);
      final existing = widget.quoteId == null
          ? null
          : await _service.getFull(token, widget.quoteId!);
      if (!mounted) return;
      _customers = data[0] as List<CariDtoLite>;
      _products = data[1] as List<StokListDto>;
      _projects = (data[2] as List<ProjeDto>).where((p) => p.tur == 3).toList();
      _warehouses = data[3] as List<DepoDto>;
      _representatives = data[4] as List<PlasiyerDto>;
      _currencies = data[5] as List<DovizDto>;
      _series = data[6] as List<BelgeSeriDto>;
      if (existing != null) {
        _quote = existing;
      } else {
        _quote.belgeseri = _series.firstOrNull?.seri;
        _quote.dovizid = _currencies
            .where((d) =>
                ['TL', 'TRY', '₺'].contains((d.Birim ?? '').toUpperCase()))
            .firstOrNull
            ?.Id;
        _quote.plasiyerid = _representatives.firstOrNull?.Id;
        _quote.projeid = await VarsayilanProjeHelper.pickFrom(_projects);
        if (_quote.belgeseri != null) {
          _quote.belgeno = await _service.nextNumber(
              token, _quote.belgeseri!, _quote.belgeyil!);
        }
      }
      if (_quote.cariid != null) {
        _addresses = await CariService().getCariAdres(token, _quote.cariid!);
      }
      _number.text = _quote.belgeno ?? '';
      _note.text = _quote.aciklama ?? '';
      _rate.text = NumberFormatHelper.format(_quote.kur ?? 1, decimal: 4);
    } catch (e) {
      if (mounted) {
        _failed = true;
        UiFeedback.showException(context, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _nextNumber() async {
    final request = ++_numberRequest;
    if (_quote.belgeseri == null) return;
    try {
      final number = await _service.nextNumber(await _token(),
          _quote.belgeseri!, _quote.belgeyil ?? DateTime.now().year);
      if (mounted && request == _numberRequest) {
        _change(() {
          _quote.belgeno = number;
          _number.text = number;
        });
      }
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    }
  }

  Future<void> _pickCustomer() async {
    final selected = await showErpSelector<CariDtoLite>(
        context: context,
        title: 'Cari Seç',
        hintText: 'Cari',
        items: _customers,
        itemText: (c) => '${c.Kod ?? ''} - ${c.Ad ?? ''}');
    if (selected == null || !mounted) return;
    _change(() {
      _quote.cariid = selected.Id;
      _quote.cariadresid = null;
    });
    try {
      final addresses =
          await CariService().getCariAdres(await _token(), selected.Id!);
      if (mounted && _quote.cariid == selected.Id) {
        setState(() => _addresses = addresses);
      }
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    }
  }

  Future<void> _addLine(
      {bool barcode = false, bool camera = false, bool manual = false}) async {
    if (_readOnly || _saving) return;
    if (_quote.cariid == null) {
      UiFeedback.showWarning(context, 'Lütfen cari seçiniz.');
      return;
    }
    TeklifhareketDto? initial;
    if (barcode || camera || manual) {
      final product = await showErpSelector<StokListDto>(
          context: context,
          title: 'Stok Seç',
          hintText: 'Barkod',
          items: _products,
          itemText: (p) => '${p.Kod ?? ''} - ${p.Ad ?? ''}',
          getBarcodes: (p) => p.getBarkodListesi(),
          startWithCamera: camera,
          startWithScanner: barcode);
      if (product == null || !mounted) return;
      initial = TeklifhareketDto()
        ..stokid = product.Id
        ..stok = StokDto(Id: product.Id, Kod: product.Kod, Ad: product.Ad);
    }
    await _editLine(initial);
  }

  Future<void> _editLine(TeklifhareketDto? line, [int? index]) async {
    if (_readOnly) return;
    final result = await showSiparisKalemForm(context,
        kalem: line == null ? null : teklifKalemToEditor(line),
        actionLabel: index == null ? 'Ekle' : 'Güncelle',
        stoklar: _products,
        projeler: _projects,
        depolar: _warehouses,
        kdvDahil: _quote.kdvdahil ?? false);
    if (result == null || !mounted) return;
    _change(() {
      final value = teklifKalemFromEditor(result, original: line)
        ..id = line?.id
        ..teklifid = _quote.id
        ..talephareketid = line?.talephareketid
        ..referansid = line?.referansid
        ..onaydurum = line?.onaydurum
        ..acikkapali = line?.acikkapali
        ..kapanisnedeni = line?.kapanisnedeni;
      if (index == null) {
        _lines.add(value);
      } else {
        _lines[index] = value;
      }
      _calculate();
    });
    _tabs.animateTo(1);
  }

  Future<void> _deleteLine(int index) async {
    final approved = await UiFeedback.confirm(context,
        title: 'Kalemi Sil',
        message: 'Bu kalem tekliften çıkarılacak.',
        confirmLabel: 'Sil',
        destructive: true);
    if (!approved || !mounted) return;
    _change(() {
      final line = _lines.removeAt(index);
      if (line.id != null) _deleted.add(line.id!);
      _calculate();
    });
  }

  void _calculate() {
    for (final k in _lines) {
      final result = FaturaHesapHelper.hesaplaKalem(
          miktar: k.miktar ?? 0,
          fiyat: k.fiyat ?? 0,
          iskontoTutar: k.iskontotutar ?? 0,
          kdvOrani: k.kdvorani ?? 0,
          tevkifatOrani: k.tevkifatorani ?? 0,
          kdvDahil: _quote.kdvdahil ?? false,
          malFazlasiAdet: k.malfazlasiiskonto ?? 0);
      k
        ..bruttutar = result.bruttutar
        ..kdvtutar = result.kdvtutar
        ..tevkifattutar = result.tevkifattutar
        ..tevkifatmatrahi = result.tevkifatmatrahi
        ..tutar = result.tutar;
      k.doviziskontotutari1 =
          _foreign && (_quote.kur ?? 0) > 0 && k.iskontotutari1 != null
              ? k.iskontotutari1! / _quote.kur!
              : null;
      k.doviziskontotutari2 =
          _foreign && (_quote.kur ?? 0) > 0 && k.iskontotutari2 != null
              ? k.iskontotutari2! / _quote.kur!
              : null;
      k.doviziskontotutari3 =
          _foreign && (_quote.kur ?? 0) > 0 && k.iskontotutari3 != null
              ? k.iskontotutari3! / _quote.kur!
              : null;
      k.doviziskontotutari4 =
          _foreign && (_quote.kur ?? 0) > 0 && k.iskontotutari4 != null
              ? k.iskontotutari4! / _quote.kur!
              : null;
      k.doviziskontotutari5 =
          _foreign && (_quote.kur ?? 0) > 0 && k.iskontotutari5 != null
              ? k.iskontotutari5! / _quote.kur!
              : null;
      k.doviziskontotutari6 =
          _foreign && (_quote.kur ?? 0) > 0 && k.iskontotutari6 != null
              ? k.iskontotutari6! / _quote.kur!
              : null;
      k.dovizfiyat = _foreign && (_quote.kur ?? 0) > 0
          ? (k.fiyat ?? 0) / _quote.kur!
          : null;
    }
    final total = FaturaHesapHelper.hesaplaFaturaToplam(
        kalemler: _lines
            .map((k) => KalemTutar(
                bruttutar: k.bruttutar ?? 0,
                kdvtutar: k.kdvtutar ?? 0,
                tevkifattutar: k.tevkifattutar))
            .toList(),
        genelIskontoOrani: _quote.geneliskontooran,
        genelIskontoTutar: (_quote.geneliskontooran ?? 0) > 0
            ? null
            : _quote.geneliskontotutar);
    _quote
      ..geneliskontotutar = total.iskontotutar
      ..dovizgeneliskontotutar = total.iskontotutar /
          (_foreign && (_quote.kur ?? 0) > 0 ? _quote.kur! : 1)
      ..bruttutar = _lines.fold<double>(
          0, (s, k) => s + ((k.miktar ?? 0) * (k.fiyat ?? 0)))
      ..iskontotutar =
          _lines.fold<double>(0, (s, k) => s + (k.iskontotutar ?? 0))
      ..malfazlasitutar =
          _lines.fold<double>(0, (s, k) => s + (k.malfazlasitutar ?? 0))
      ..aratoplam = total.aratoplam
      ..kdvtoplam = total.kdvtoplam
      ..geneltoplam = total.geneltoplam
      ..tevkifattutar =
          _lines.fold<double>(0, (s, k) => s + (k.tevkifattutar ?? 0))
      ..doviztoplam = _foreign && (_quote.kur ?? 0) > 0
          ? total.geneltoplam / _quote.kur!
          : null;
  }

  Future<void> _save({bool complete = false}) async {
    if (_saving || _readOnly) return;
    if (_quote.cariid == null) {
      UiFeedback.showWarning(context, 'Lütfen cari seçiniz.');
      return;
    }
    if (_quote.dovizid == null ||
        _quote.projeid == null ||
        _quote.plasiyerid == null) {
      UiFeedback.showWarning(context, 'Döviz, proje ve plasiyer seçiniz.');
      _tabs.animateTo(0);
      return;
    }
    if (_lines.any(
        (k) => k.depoid == null || k.projeid == null || k.olcubrid == null)) {
      UiFeedback.showWarning(
          context, 'Kalemlerin depo, proje ve birim bilgilerini tamamlayınız.');
      return;
    }
    if (_lines.isEmpty) {
      UiFeedback.showWarning(context, 'En az bir kalem ekleyiniz.');
      return;
    }
    if (_quote.belgeseri == null || _number.text.trim().isEmpty) {
      UiFeedback.showWarning(context, 'Belge seri ve numarasını giriniz.');
      _tabs.animateTo(0);
      return;
    }
    if (_foreign && NumberFormatHelper.parse(_rate.text) <= 0) {
      UiFeedback.showWarning(context, 'Kur sıfırdan büyük olmalıdır.');
      _tabs.animateTo(0);
      return;
    }
    setState(() => _saving = true);
    var stored = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      _quote
        ..subeid = prefs.getInt('sube_id') ?? 0
        ..belgeno = _number.text.trim()
        ..aciklama = _note.text.trim()
        ..kur = _foreign ? NumberFormatHelper.parse(_rate.text) : 1
        ..belgeserino =
            '${_quote.belgeseri}${_quote.belgeyil}${_number.text.trim()}';
      _calculate();
      if (await OfflineService.instance.getOfflineMode() ||
          !OfflineService.instance.isOnline.value) {
        if (_quote.id != null || complete) {
          if (mounted) {
            UiFeedback.showWarning(context, 'Bu işlem için bağlantı gerekli.');
          }
          return;
        }
        await OfflineService.instance.enqueue('single_full', {
          'endpoint': '/${_service.controller}/SaveWithItems',
          'method': 'POST',
          'body': _service.createBody(_quote)
        });
        stored = true;
      } else {
        if (_quote.id == null) {
          _quote.id = await _service.create(token, _quote);
        } else {
          await _service.updateHeader(token, _quote);
          for (final line in _lines) {
            line.teklifid = _quote.id;
            await _service.saveLine(token, line);
          }
          while (_deleted.isNotEmpty) {
            await _service.removeLine(token, _deleted.first);
            _deleted.removeAt(0);
          }
        }
        stored = true;
        if (complete) await _service.changeStatus(token, _quote.id!, true);
      }
      if (mounted) {
        setState(() => _dirty = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      UiFeedback.showException(context, e);
      if (stored) {
        setState(() => _dirty = false);
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _leave() async {
    final discard = await UiFeedback.confirm(context,
        title: 'Kaydedilmemiş Değişiklikler',
        message: 'Kaydetmeden çıkılsın mı?',
        confirmLabel: 'Çık');
    if (discard && mounted) {
      setState(() => _dirty = false);
      Navigator.pop(context);
    }
  }

  Widget _card(List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children))),
      );
  Widget _pair(Widget a, Widget b) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b)
      ]);
  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        labelStyle: TextStyle(fontSize: 12, color: _scheme.onSurfaceVariant),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _scheme.outlineVariant)),
      );
  Widget _dropdown<T>(String label, T? value, List<DropdownMenuItem<T>> items,
          ValueChanged<T?> update) =>
      DropdownButtonFormField<T>(
        value: items.any((e) => e.value == value) ? value : null,
        isExpanded: true,
        style: TextStyle(
            fontFamily: 'Roboto', fontSize: 13, color: _scheme.onSurface),
        decoration: _dec(label),
        iconSize: 18,
        selectedItemBuilder: (_) => items
            .map((e) => DefaultTextStyle.merge(
                maxLines: 1, overflow: TextOverflow.ellipsis, child: e.child))
            .toList(),
        items: items,
        onChanged:
            _readOnly || _saving ? null : (v) => _change(() => update(v)),
      );
  Widget _date(String label, DateTime? date, ValueChanged<DateTime> update) =>
      InkWell(
        onTap: _readOnly || _saving
            ? null
            : () async {
                final selected = await showDatePicker(
                    context: context,
                    initialDate: date ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100));
                if (selected != null && mounted) {
                  _change(() => update(selected));
                }
              },
        child: InputDecorator(
            decoration: _dec(label).copyWith(
                suffixIcon:
                    const Icon(Icons.calendar_today_outlined, size: 17)),
            child: Text(
                date == null ? label : DateFormat('dd.MM.yyyy').format(date),
                style: const TextStyle(fontSize: 13))),
      );

  Widget _header() {
    final customer = _customers.where((c) => c.Id == _quote.cariid).firstOrNull;
    return ListView(padding: const EdgeInsets.all(12), children: [
      _card([
        ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(Icons.business_outlined, color: _scheme.primary),
            title: Text(customer?.Ad ?? _quote.cari?.Ad ?? 'Cari',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: customer?.Kod == null ? null : Text(customer!.Kod!),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _readOnly || _saving ? null : _pickCustomer)
      ]),
      _card([
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              flex: 2,
              child: _dropdown<String>(
                  'Seri',
                  _quote.belgeseri,
                  _series
                      .map((s) => DropdownMenuItem(
                          value: s.seri, child: Text(s.seri ?? '')))
                      .toList(), (v) {
                _quote.belgeseri = v;
                _nextNumber();
              })),
          const SizedBox(width: 8),
          Expanded(
              flex: 2,
              child: _dropdown<int>('Yıl', _quote.belgeyil, [
                for (var y = DateTime.now().year - 5;
                    y <= DateTime.now().year + 2;
                    y++)
                  DropdownMenuItem(value: y, child: Text('$y'))
              ], (v) {
                _quote.belgeyil = v;
                _nextNumber();
              })),
          const SizedBox(width: 8),
          Expanded(
              flex: 3,
              child: TextField(
                  controller: _number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9)
                  ],
                  readOnly: _readOnly || _saving,
                  style: const TextStyle(fontSize: 13),
                  decoration: _dec('Belge No'),
                  onChanged: (_) => _change(() {}))),
        ]),
        const SizedBox(height: 16),
        _pair(
            _date('Tarih', _quote.tarih, (v) => _quote.tarih = v),
            _date('Fiili Tarih', _quote.fiilitarih,
                (v) => _quote.fiilitarih = v)),
        const SizedBox(height: 16),
        _pair(
            _date('Geçerlilik Tarihi', _quote.gecerliliktarihi,
                (v) => _quote.gecerliliktarihi = v),
            _date('Teslim Tarihi', _quote.teslimtarihi,
                (v) => _quote.teslimtarihi = v)),
        const SizedBox(height: 16),
        _pair(
            _dropdown<int>(
                'Döviz',
                _quote.dovizid,
                _currencies
                    .map((d) => DropdownMenuItem(
                        value: d.Id, child: Text(d.Birim ?? d.Ad ?? '')))
                    .toList(), (v) {
              _quote.dovizid = v;
              if (!_foreign) {
                _quote.kur = 1;
                _rate.text = '1,0000';
              }
              _calculate();
            }),
            TextField(
                controller: _rate,
                enabled: !_readOnly && !_saving && _foreign,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec('Kur'),
                onChanged: (v) => _change(() {
                      _quote.kur = NumberFormatHelper.parse(v);
                      _calculate();
                    }))),
        const SizedBox(height: 16),
        _pair(
            _dropdown<int>(
                'Ödeme Şekli',
                _quote.odemesekli,
                StokHareketCouples.odemeSekilleri
                    .map((e) =>
                        DropdownMenuItem(value: e.value, child: Text(e.text)))
                    .toList(),
                (v) => _quote.odemesekli = v),
            _date('Tahsilat Tarihi', _quote.tahsilattarihi,
                (v) => _quote.tahsilattarihi = v)),
        const SizedBox(height: 16),
        _dropdown<int>(
            'Teslim Adresi',
            _quote.cariadresid,
            _addresses
                .map((a) => DropdownMenuItem(
                    value: a.id,
                    child:
                        Text(a.adres ?? '', overflow: TextOverflow.ellipsis)))
                .toList(),
            (v) => _quote.cariadresid = v),
        const SizedBox(height: 16),
        _pair(
            _dropdown<int>(
                'Proje',
                _quote.projeid,
                _projects
                    .map((p) => DropdownMenuItem(
                        value: p.id,
                        child:
                            Text(p.ad ?? '', overflow: TextOverflow.ellipsis)))
                    .toList(),
                (v) => _quote.projeid = v),
            _dropdown<int>(
                'Plasiyer',
                _quote.plasiyerid,
                _representatives
                    .map((p) => DropdownMenuItem(
                        value: p.Id,
                        child: Text(p.Adsoyad ?? '',
                            overflow: TextOverflow.ellipsis)))
                    .toList(),
                (v) => _quote.plasiyerid = v)),
        const SizedBox(height: 16),
        _pair(
            _dropdown<int>(
                'Öncelik',
                _quote.oncelik,
                OncelikCouples.list
                    .map((e) =>
                        DropdownMenuItem(value: e.value, child: Text(e.text)))
                    .toList(),
                (v) => _quote.oncelik = v),
            _date('Vade Tarihi', _quote.vadetarihi,
                (v) => _quote.vadetarihi = v)),
        const SizedBox(height: 10),
        SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('KDV Dahil', style: TextStyle(fontSize: 13)),
            value: _quote.kdvdahil ?? false,
            onChanged: _readOnly || _saving
                ? null
                : (v) => _change(() {
                      _quote.kdvdahil = v;
                      _calculate();
                    })),
        CommercialDocumentFields(
            sales: widget.sales,
            quote: true,
            enabled: !_readOnly && !_saving,
            deliveryType: _quote.teslimattipi,
            referenceNumber: _quote.referansbelgeno,
            documentType: _quote.belgetipi,
            tradeType: _quote.ithalatihracattipi,
            groupNumber: _quote.grupno,
            onDelivery: (v) => _change(() => _quote.teslimattipi = v),
            onReference: (v) => _change(
                () => _quote.referansbelgeno = v.trim().isEmpty ? null : v),
            onDocumentType: (v) => _change(() {
                  _quote.belgetipi = v;
                  if (v != 5 && v != 6) _quote.ithalatihracattipi = null;
                }),
            onTrade: (v) => _change(() => _quote.ithalatihracattipi = v),
            onGroupNumber: (v) => _change(() => _quote.grupno = v)),
        IgnorePointer(
            ignoring: _readOnly || _saving,
            child: DocumentExtraNotesButton(
                values: _quote.extraNotes,
                onChanged: (v) => _change(() => _quote.extraNotes = v))),
        const SizedBox(height: 6),
        TextField(
            controller: _note,
            inputFormatters: [LengthLimitingTextInputFormatter(100)],
            readOnly: _readOnly || _saving,
            maxLines: 2,
            decoration: _dec('Açıklama').copyWith(hintText: 'Açıklama'),
            onChanged: (_) => _change(() {})),
      ]),
    ]);
  }

  Widget _items() => _lines.isEmpty
      ? Center(
          child: Text('Henüz kalem yok',
              style: TextStyle(color: _scheme.onSurfaceVariant)))
      : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _lines.length,
          itemBuilder: (_, i) {
            final line = _lines[i];
            return ErpFinanceCard(
                title: line.stok?.Ad ??
                    _products
                        .where((p) => p.Id == line.stokid)
                        .firstOrNull
                        ?.Ad ??
                    '-',
                icon: Icons.inventory_2_outlined,
                metadata: [
                  '${NumberFormatHelper.format(line.miktar ?? 0)} ${line.olcubr?.Ad ?? ''} × ${NumberFormatHelper.format(line.fiyat ?? 0)} ₺',
                  'KDV %${NumberFormatHelper.format(line.kdvorani ?? 0, decimal: 0)}'
                ],
                amount: '${NumberFormatHelper.format(line.tutar ?? 0)} ₺',
                onTap: _readOnly || _saving ? null : () => _editLine(line, i),
                onDelete: _readOnly || _saving ? null : () => _deleteLine(i));
          });

  Widget _summaryRow(String label, double amount) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style:
                    TextStyle(fontSize: 13, color: _scheme.onSurfaceVariant))),
        const SizedBox(width: 8),
        Text('${NumberFormatHelper.format(amount)} ₺',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))
      ]));
  Widget _summary() => ListView(padding: const EdgeInsets.all(12), children: [
        OutlinedButton.icon(
            onPressed: _readOnly || _saving ? null : _genelIskontoSec,
            icon: const Icon(Icons.percent_rounded, size: 18),
            label: const Text('Genel İskonto')),
        const SizedBox(height: 12),
        _card([
          _summaryRow(
              'Brüt Toplam',
              _quote.bruttutar ??
                  _lines.fold<double>(0, (s, k) => s + (k.bruttutar ?? 0))),
          if ((_quote.iskontotutar ?? 0) > 0)
            _summaryRow('Satır İskontosu', -_quote.iskontotutar!),
          if ((_quote.geneliskontotutar ?? 0) > 0)
            _summaryRow('Genel İskonto', -_quote.geneliskontotutar!),
          _summaryRow(
              'KDV',
              _quote.kdvtoplam ??
                  _lines.fold<double>(0, (s, k) => s + (k.kdvtutar ?? 0))),
          if ((_quote.tevkifattutar ?? 0) > 0)
            _summaryRow('Tevkifat', -_quote.tevkifattutar!),
          Divider(height: 24, color: _scheme.outlineVariant),
          Text('Genel Toplam',
              style: TextStyle(fontSize: 12, color: _scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('${NumberFormatHelper.format(_quote.geneltoplam ?? 0)} ₺',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _scheme.primary)),
          if (_foreign && (_quote.kur ?? 0) > 0)
            Text(
                '${NumberFormatHelper.format((_quote.geneltoplam ?? 0) / _quote.kur!)} ${_currency?.Birim ?? ''}',
                style:
                    TextStyle(fontSize: 14, color: _scheme.onSurfaceVariant)),
        ])
      ]);

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_dirty && !_saving,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !_saving) _leave();
        },
        child: Scaffold(
          appBar: ErpPageAppBar(
              context: context,
              title: Text(
                  widget.quoteId == null
                      ? 'Yeni $_kind Teklifi'
                      : '$_kind Teklifi',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              bottom: ErpAdaptiveTabs(
                  context: context,
                  tabBar: TabBar(controller: _tabs, tabs: [
                    Tab(height: 40, text: 'Belge'),
                    Tab(height: 40, text: 'Kalemler'),
                    Tab(height: 40, text: 'Özet')
                  ]))),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _failed
                  ? Center(
                      child: TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Yeniden Dene')))
                  : TabBarView(
                      controller: _tabs,
                      children: [_header(), _items(), _summary()]),
          bottomNavigationBar: _loading || _failed || _readOnly
              ? null
              : Material(
                  color: _scheme.surface,
                  child: SafeArea(
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: AbsorbPointer(
                              absorbing: _saving,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ErpEntryActions(
                                        onAdd: () => _addLine(),
                                        onBarcode: () =>
                                            _addLine(barcode: true),
                                        onCamera: () => _addLine(camera: true),
                                        onManual: () => _addLine(manual: true)),
                                    if (_tabs.index > 0) ...[
                                      const SizedBox(height: 8),
                                      Row(children: [
                                        Expanded(
                                            child: SizedBox(
                                                height: 44,
                                                child: PermissionAction(
                                                    modules: [
                                                      widget.sales ? 601 : 602
                                                    ],
                                                    access: Access.write,
                                                    child: FilledButton.icon(
                                                        onPressed: _saving
                                                            ? null
                                                            : () => _save(),
                                                        icon: _saving
                                                            ? const SizedBox(
                                                                width: 18,
                                                                height: 18,
                                                                child: CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2))
                                                            : const Icon(
                                                                Icons
                                                                    .save_outlined,
                                                                size: 18),
                                                        label: Text(_saving
                                                            ? 'Kaydediliyor'
                                                            : 'Kaydet'))))),
                                        PopupMenuButton<bool>(
                                            tooltip: 'Kaydetme seçenekleri',
                                            onSelected: (v) =>
                                                _save(complete: v),
                                            itemBuilder: (_) => [
                                                  if (AuthorizationSession
                                                      .instance
                                                      .any([
                                                    widget.sales ? 601 : 602
                                                  ], Access.create))
                                                    const PopupMenuItem(
                                                        value: true,
                                                        child: Text(
                                                            'Kaydet ve Tamamla'))
                                                ]),
                                      ])
                                    ],
                                  ]))))),
        ),
      );

  Future<void> _genelIskontoSec() async {
    final rate = _foreign && (_quote.kur ?? 0) > 0 ? _quote.kur! : 1.0;
    final base = _lines.fold<double>(0, (s, k) => s + (k.bruttutar ?? 0));
    final result = await showFaturaGenelIskontoSheet(context,
        oran: _quote.geneliskontooran,
        tutar: (_quote.geneliskontotutar ?? 0) / rate,
        araToplam: base / rate,
        isDoviz: _foreign,
        kur: rate,
        dovizId: _quote.dovizid);
    if (result == null || !mounted || _readOnly) return;
    _change(() {
      _quote.geneliskontooran = result.oran ??
          ((result.tutar ?? 0) > 0 && base > 0
              ? result.tutar! * rate / base * 100
              : null);
      _quote.geneliskontotutar = (result.tutar ?? 0) * rate;
      _calculate();
    });
  }
}
