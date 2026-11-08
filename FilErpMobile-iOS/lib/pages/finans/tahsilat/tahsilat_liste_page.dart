import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../../widgets/erp_ui.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/finans/tahsilat_service.dart';
import '../../../models/entities/finans/tahsilat/tahsilat_dto.dart';
import '../../../helpers/response.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/kullanici_plasiyer_helper.dart';
import '../../../helpers/tahsilat_couples.dart';
import '../../../widgets/yetki_hatasi_widget.dart';
import 'tahsilat_ekle_page.dart';

// Kurumsal / kompakt renk paleti
const _kGreen = Color(0xFF0E7C5A);
const _kGold = Color(0xFFB07A11);
const _kRed = Color(0xFFC2312B);

class TahsilatListePage extends StatefulWidget {
  /// Bir Sipariş/Fatura üzerinden "Tahsilat" açıldığında dolu gelir — liste
  /// sadece o belgeye ait tahsilatları gösterir ve bakiye kartı eklenir.
  final TahsilatKaynakBelge? kaynakBelge;

  const TahsilatListePage({super.key, this.kaynakBelge});

  @override
  State<TahsilatListePage> createState() => _TahsilatListePageState();
}

class _TahsilatListePageState extends State<TahsilatListePage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  List<TahsilatDto> _all = [];
  List<TahsilatDto> _filtered = [];
  bool _loading = true;
  bool _yetkiHatasi = false;
  String? _hataMesaji;

  final _searchCtrl = TextEditingController();
  final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');
  final _dateFmt = DateFormat('dd.MM.yyyy');

  int? _filtreTip;
  String? _filtreParabirimi;
  String? _filtreCariAd;
  DateTime? _filtreBaslangic;
  DateTime? _filtreBitis;

  double get _toplamTutar =>
      _filtered.fold(0.0, (s, e) => s + (e.Tahsilattutari ?? 0.0));

  bool get _filtreAktif =>
      _filtreTip != null ||
      _filtreParabirimi != null ||
      _filtreCariAd != null ||
      _filtreBaslangic != null ||
      _filtreBitis != null;

  List<String> get _parabirimleri =>
      (_all.map((e) => e.DovizBirim).whereType<String>().toSet().toList())
        ..sort();

  List<String> get _cariler =>
      (_all.map((e) => e.CariAd).whereType<String>().toSet().toList())..sort();

  @override
  void initState() {
    super.initState();
    _plasiyerBugunFiltresi().then((_) => _load());
  }

  /// Plasiyer kullanıcıda liste önce "bugün" filtresiyle açılır (filtre ayarından değiştirilebilir).
  /// Belgeye bağlı (kaynak belge) listede uygulanmaz.
  Future<void> _plasiyerBugunFiltresi() async {
    if (widget.kaynakBelge != null) return;
    final kp = await KullaniciPlasiyerHelper.getir();
    if (!kp.kilitli) return;
    final now = DateTime.now();
    _filtreBaslangic = DateTime(now.year, now.month, now.day);
    _filtreBitis = _filtreBaslangic;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _yetkiHatasi = false;
      _hataMesaji = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final data = widget.kaynakBelge != null
          ? await TahsilatService()
              .getAllByBelgeid(token, widget.kaynakBelge!.belgeId)
          : await TahsilatService().getAll(token);
      data.sort(
          (a, b) => (b.Tarih ?? DateTime(0)).compareTo(a.Tarih ?? DateTime(0)));
      if (!mounted) return;
      setState(() {
        _all = data;
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      if (e is YetkiHatasi) {
        setState(() {
          _yetkiHatasi = true;
          _loading = false;
        });
      } else {
        final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        setState(() {
          _loading = false;
          _hataMesaji = msg;
        });
        UiFeedback.showException(context, e);
      }
    }
  }

  void _applyFilters() {
    final s = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((e) {
        if (s.isNotEmpty &&
            !((e.CariAd ?? '').toLowerCase().contains(s) ||
                (e.Belgeserino ?? '').toLowerCase().contains(s))) return false;
        if (_filtreTip != null && e.Tip != _filtreTip) return false;
        if (_filtreParabirimi != null && e.DovizBirim != _filtreParabirimi)
          return false;
        if (_filtreCariAd != null && e.CariAd != _filtreCariAd) return false;
        if (_filtreBaslangic != null &&
            (e.Tarih == null || e.Tarih!.isBefore(_filtreBaslangic!)))
          return false;
        if (_filtreBitis != null &&
            (e.Tarih == null ||
                e.Tarih!.isAfter(_filtreBitis!
                    .add(const Duration(hours: 23, minutes: 59, seconds: 59)))))
          return false;
        return true;
      }).toList();
    });
  }

  void _search(String text) => _applyFilters();

  void _clearFiltre() {
    setState(() {
      _filtreTip = null;
      _filtreParabirimi = null;
      _filtreCariAd = null;
      _filtreBaslangic = null;
      _filtreBitis = null;
    });
    _applyFilters();
  }

  Future<void> _openFiltreSheet() async {
    int? tip = _filtreTip;
    String? birim = _filtreParabirimi;
    String? cari = _filtreCariAd;
    DateTime? bas = _filtreBaslangic;
    DateTime? bit = _filtreBitis;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _scheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                        color: _scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2))),
              ),
              Row(children: [
                Expanded(
                    child: Text('Filtrele',
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _scheme.onSurface))),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded,
                      color: _scheme.onSurfaceVariant, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ]),
              const SizedBox(height: 4),
              _filtreBaslik('İşlem Tipi'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _filtreChip(
                    'Tümü', tip == null, () => setSheetState(() => tip = null)),
                ...TahsilattipiCouples.list.map((c) => _filtreChip(c.text,
                    tip == c.value, () => setSheetState(() => tip = c.value))),
              ]),
              if (_parabirimleri.isNotEmpty) ...[
                const SizedBox(height: 16),
                _filtreBaslik('Para Birimi'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _filtreChip('Tümü', birim == null,
                      () => setSheetState(() => birim = null)),
                  ..._parabirimleri.map((b) => _filtreChip(
                      b, birim == b, () => setSheetState(() => birim = b))),
                ]),
              ],
              if (_cariler.isNotEmpty) ...[
                const SizedBox(height: 16),
                _filtreBaslik('Cari'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: _scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: cari,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Text('Tümü',
                              style: TextStyle(
                                  fontFamily: 'Roboto', fontSize: 13))),
                      items: [
                        const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tümü',
                                style: TextStyle(
                                    fontFamily: 'Roboto', fontSize: 13))),
                        ..._cariler.map((c) => DropdownMenuItem<String?>(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(
                                    fontFamily: 'Roboto', fontSize: 13)))),
                      ],
                      onChanged: (v) => setSheetState(() => cari = v),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _filtreBaslik('Tarih Aralığı'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: _filtreDateField(
                        'Başlangıç', bas, (d) => setSheetState(() => bas = d))),
                const SizedBox(width: 8),
                Expanded(
                    child: _filtreDateField(
                        'Bitiş', bit, (d) => setSheetState(() => bit = d))),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setSheetState(() {
                      tip = null;
                      birim = null;
                      cari = null;
                      bas = null;
                      bit = null;
                    }),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: _scheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: Text('Temizle',
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            color: _scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _filtreTip = tip;
                        _filtreParabirimi = birim;
                        _filtreCariAd = cari;
                        _filtreBaslangic = bas;
                        _filtreBitis = bit;
                      });
                      _applyFilters();
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _scheme.primary,
                        foregroundColor: _scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: const Text('Uygula',
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _filtreBaslik(String text) => Text(text,
      style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: _scheme.onSurfaceVariant,
          letterSpacing: 0.4));

  Widget _filtreChip(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _scheme.primary : _scheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? _scheme.primary : _scheme.outlineVariant),
          ),
          child: Text(label,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? _scheme.onPrimary : _scheme.onSurfaceVariant)),
        ),
      );

  Widget _filtreDateField(
          String label, DateTime? value, ValueChanged<DateTime?> onChanged) =>
      InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          onChanged(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
              border: Border.all(color: _scheme.outlineVariant),
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(Icons.calendar_today_rounded,
                size: 14, color: _scheme.onSurfaceVariant),
            const SizedBox(width: 7),
            Expanded(
                child: Text(value != null ? _dateFmt.format(value) : label,
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12.5,
                        color: value != null
                            ? _scheme.onSurface
                            : _scheme.onSurfaceVariant))),
            if (value != null)
              GestureDetector(
                  onTap: () => onChanged(null),
                  child: Icon(Icons.close_rounded,
                      size: 14, color: _scheme.onSurfaceVariant)),
          ]),
        ),
      );

  Future<void> _delete(TahsilatDto e) async {
    final onay = await UiFeedback.confirm(context,
        title: 'Tahsilat Sil',
        message:
            'Bu tahsilat kaydı ve ilişkili kasa/banka ve cari hareketleri silinecek. Emin misiniz?',
        confirmLabel: 'Sil',
        cancelLabel: 'Vazgeç',
        destructive: true);
    if (!onay || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      await TahsilatService().delete(token, e.Id!);
      if (!mounted) return;
      UiFeedback.showDeleted(context, 'Tahsilat silindi.');
      _load();
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: _yetkiHatasi
          ? const YetkiHatasiWidget()
          : _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
              : _hataMesaji != null
                  ? _buildHataDurumu()
                  : Column(children: [
                      if (widget.kaynakBelge != null) _buildBakiyeKarti(),
                      _buildSearchBar(),
                      _buildOzetBar(),
                      Expanded(child: _buildList()),
                    ]),
      floatingActionButton: PermissionAction(
          modules: [1025],
          access: Access.create,
          child: FloatingActionButton.extended(
            backgroundColor: _scheme.primary,
            foregroundColor: _scheme.onPrimary,
            elevation: 1,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Yeni Tahsilat',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5)),
            onPressed: () async {
              await Navigator.push(
                  context,
                  PermissionMaterialPageRoute(
                      builder: (_) =>
                          TahsilatEklePage(kaynakBelge: widget.kaynakBelge)));
              _load();
            },
          )),
    );
  }

  Widget _buildBakiyeKarti() {
    final kaynak = widget.kaynakBelge!;
    final yapilmis = _all.fold(0.0, (s, e) => s + (e.Tahsilattutari ?? 0));
    final bakiye = kaynak.toplamTutar - yapilmis;
    final bakiyeRenk = bakiye > 0 ? _kGreen : _scheme.onSurfaceVariant;
    return Container(
      color: _scheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(children: [
        Expanded(
            child: _bakiyeItem(
                'BELGE TOPLAMI', kaynak.toplamTutar, _scheme.onSurface)),
        _dikeyAyrac(),
        Expanded(
            child: _bakiyeItem(
                'TAHSİL EDİLEN', yapilmis, _scheme.onSurfaceVariant)),
        _dikeyAyrac(),
        Expanded(child: _bakiyeItem('BAKİYE', bakiye, bakiyeRenk)),
      ]),
    );
  }

  Widget _dikeyAyrac() => Container(
      width: 1,
      height: 30,
      color: _scheme.outlineVariant,
      margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _bakiyeItem(String label, double tutar, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3)),
          const SizedBox(height: 4),
          Text(_moneyFmt.format(tutar),
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      );

  PreferredSizeWidget _buildAppBar() => ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tahsilat',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 19,
                      fontWeight: FontWeight.w700)),
              if (widget.kaynakBelge?.belgeserino != null)
                Text(widget.kaynakBelge!.belgeserino!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        color: _scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w400)),
            ]),
        actions: [
          IconButton(
              tooltip: 'Yenile',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded))
        ],
      );

  Widget _buildSearchBar() => Container(
        color: _scheme.surface,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchCtrl,
                onChanged: _search,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13.5,
                    color: _scheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Cari adı veya belge no...',
                  hintStyle: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12.5,
                      color: _scheme.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: _scheme.onSurfaceVariant, size: 19),
                  prefixIconConstraints: const BoxConstraints(minWidth: 38),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.close_rounded,
                              size: 16, color: _scheme.onSurfaceVariant),
                          onPressed: () {
                            _searchCtrl.clear();
                            _search('');
                          })
                      : null,
                  filled: true,
                  fillColor: _background,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _scheme.outlineVariant)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _scheme.outlineVariant)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: _scheme.primary, width: 1.3)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _filtreAktif ? _scheme.primary : _scheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _filtreAktif
                        ? _scheme.primary
                        : _scheme.outlineVariant),
              ),
              child: IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: Icon(Icons.tune_rounded,
                    color: _filtreAktif
                        ? _scheme.onPrimary
                        : _scheme.onSurfaceVariant,
                    size: 19),
                onPressed: _openFiltreSheet,
              ),
            ),
            if (_filtreAktif)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                        color: _kGold,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: _scheme.surface, width: 1.5))),
              ),
          ]),
        ]),
      );

  Widget _buildOzetBar() => Container(
        width: double.infinity,
        color: _scheme.surface,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Text(
                _filtreAktif || _searchCtrl.text.isNotEmpty
                    ? '${_filtered.length} sonuç bulundu'
                    : '${_all.length} tahsilat',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11.5,
                    color: _scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Text('Toplam ${_moneyFmt.format(_toplamTutar)} ₺',
                style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kGreen)),
          ]),
          if (_filtreAktif) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_filtreTip != null)
                      _aktifFiltreChip(
                          TahsilattipiCouples.adByValue(_filtreTip), () {
                        setState(() => _filtreTip = null);
                        _applyFilters();
                      }),
                    if (_filtreParabirimi != null)
                      _aktifFiltreChip(_filtreParabirimi!, () {
                        setState(() => _filtreParabirimi = null);
                        _applyFilters();
                      }),
                    if (_filtreCariAd != null)
                      _aktifFiltreChip(_filtreCariAd!, () {
                        setState(() => _filtreCariAd = null);
                        _applyFilters();
                      }),
                    if (_filtreBaslangic != null || _filtreBitis != null)
                      _aktifFiltreChip(
                        '${_filtreBaslangic != null ? _dateFmt.format(_filtreBaslangic!) : '…'} - ${_filtreBitis != null ? _dateFmt.format(_filtreBitis!) : '…'}',
                        () {
                          setState(() {
                            _filtreBaslangic = null;
                            _filtreBitis = null;
                          });
                          _applyFilters();
                        },
                      ),
                    GestureDetector(
                      onTap: _clearFiltre,
                      child: Text('Tümünü temizle',
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10.5,
                              color: _scheme.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]),
            ),
          ],
        ]),
      );

  Widget _aktifFiltreChip(String label, VoidCallback onRemove) => Container(
        padding: const EdgeInsets.only(left: 9, right: 3, top: 3, bottom: 3),
        decoration: BoxDecoration(
            color: _scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _scheme.primary.withValues(alpha: 0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10.5,
                  color: _scheme.primary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 2),
          GestureDetector(
              onTap: onRemove,
              child:
                  Icon(Icons.close_rounded, size: 13, color: _scheme.primary)),
        ]),
      );

  Widget _buildList() {
    if (_filtered.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 96),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        try {
          return _buildCard(_filtered[i], i);
        } catch (err) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200)),
            child: Text('Kayıt gösterilemedi: $err',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    color: Colors.red.shade700)),
          );
        }
      },
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: _scheme.surfaceContainerLow, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_outlined,
                size: 26, color: _scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Text(
              _filtreAktif || _searchCtrl.text.isNotEmpty
                  ? 'Filtreye uyan kayıt bulunamadı'
                  : 'Henüz tahsilat kaydı yok',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13.5,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _buildHataDurumu() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: _kRed.withValues(alpha: 0.08), shape: BoxShape.circle),
              child:
                  const Icon(Icons.cloud_off_rounded, size: 28, color: _kRed),
            ),
            const SizedBox(height: 16),
            Text('Tahsilat listesi yüklenemedi',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _scheme.onSurface)),
            const SizedBox(height: 6),
            Text(_hataMesaji ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12.5,
                    color: _scheme.onSurfaceVariant,
                    height: 1.4)),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar Dene',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _scheme.primary,
                foregroundColor: _scheme.onPrimary,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ),
      );

  Widget _buildCard(TahsilatDto e, int index) {
    final target =
        e.Tip == 1 ? (e.KasaAd ?? 'Kasa') : (e.BankahesapAd ?? 'Banka');
    final fx =
        !['TL', 'TRY', '₺', ''].contains((e.DovizBirim ?? '').toUpperCase());
    return ErpSwipeDelete(
      key: ValueKey('${e.Id ?? 'collection'}_$index'),
      onDelete: !AuthorizationSession.instance.any([1025], Access.delete)
          ? null
          : () => _delete(e),
      child: ErpFinanceCard(
        title: e.CariAd ?? 'Cari',
        icon: _tipIcon(e.Tip),
        metadata: [
          e.Tarih == null ? '-' : _dateFmt.format(e.Tarih!),
          TahsilattipiCouples.adByValue(e.Tip),
          target,
          e.Belgeserino ?? ''
        ],
        amount: '${_moneyFmt.format(e.Tahsilattutari ?? 0)} ₺',
        amountColor: _kGreen,
        secondaryAmount: fx && (e.Doviztutar ?? 0) != 0
            ? '${_moneyFmt.format(e.Doviztutar)} ${e.DovizBirim}'
            : null,
        onDelete: !AuthorizationSession.instance.any([1025], Access.delete)
            ? null
            : () => _delete(e),
        onTap: () async {
          await Navigator.push(
              context,
              PermissionMaterialPageRoute(
                  builder: (_) => TahsilatEklePage(editTahsilat: e)));
          if (mounted) _load();
        },
      ),
    );
  }

  IconData _tipIcon(int? tip) {
    switch (tip) {
      case 2:
        return Icons.account_balance_rounded;
      case 3:
        return Icons.credit_card_rounded;
      default:
        return Icons.payments_rounded;
    }
  }
}
