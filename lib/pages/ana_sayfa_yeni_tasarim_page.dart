import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/services/auth/menu_access.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/corporate_menu_icon.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/kullanici_plasiyer_helper.dart';
import '../services/depo/dat/dat_service.dart';
import '../services/fatura/fatura_service.dart';
import '../services/irsaliye/irsaliye_service.dart';
import '../services/offline/offline_service.dart';
import '../services/rapor/rapor_api.dart';
import '../services/siparis/siparis_service.dart';
import 'rapor/ortak/rapor_modelleri.dart';

/// FilERP Modern ana sayfası; modül işlemleri HomePage üzerinden açılır.
class AnaSayfaYeniTasarimPage extends StatefulWidget {
  final String kullanici;
  final String firma;
  final String sube;
  final Map<String, VoidCallback> aksiyonlar;

  const AnaSayfaYeniTasarimPage({
    super.key,
    required this.kullanici,
    required this.firma,
    required this.sube,
    required this.aksiyonlar,
  });

  @override
  State<AnaSayfaYeniTasarimPage> createState() =>
      _AnaSayfaYeniTasarimPageState();
}

class _Modul {
  final String ad, alt, ikon;
  final Color renk;
  const _Modul(this.ad, this.alt, this.ikon, this.renk);
}

class _Grup {
  final String baslik;
  final List<_Modul> moduller;
  const _Grup(this.baslik, this.moduller);
}

/// Hızlı düğme görünümü (modül adı → etiket, ikon, renk)
class _Hizli {
  final String etiket;
  final IconData ikon;
  final Color renk;
  const _Hizli(this.etiket, this.ikon, this.renk);
}

/// Açık / koyu tema renkleri
class _Renk {
  final bool koyu;
  final Color zemin, kart, yazi, soluk, ayrac;
  const _Renk._(
      this.koyu, this.zemin, this.kart, this.yazi, this.soluk, this.ayrac);

  factory _Renk.of(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? const _Renk._(true, Color(0xFF0F1420), Color(0xFF1B2233),
          Color(0xFFF3F4F6), Color(0xFF9CA3AF), Color(0xFF2A3347))
      : const _Renk._(false, Color(0xFFF4F6FB), Colors.white, Color(0xFF111827),
          Color(0xFF6B7280), Color(0xFFE5E7EB));
}

const _lacivert = Color(0xFF14213D);
const _indigo = Color(0xFF3949AB);

const _gruplar = <_Grup>[
  _Grup('Satış', [
    _Modul('Fatura', 'Satış ve alış faturaları', 'fatura', Color(0xFF2563EB)),
    _Modul('İrsaliye', 'Sevk ve alış irsaliyeleri', 'satis_irsaliyesi',
        Color(0xFF0EA5A4)),
    _Modul(
        'Sipariş', 'Alış / satış siparişleri', 'siparisler', Color(0xFF7C3AED)),
    _Modul(
        'Teklif', 'Satış ve alış teklifleri', 'siparisler', Color(0xFF3949AB)),
  ]),
  _Grup('Stok ve Depo', [
    _Modul('Stok', 'Stok kartları ve bakiye', 'stok', Color(0xFFF59E0B)),
    _Modul('Depo', 'DAT ve araç yükleme', 'dat', Color(0xFF16A34A)),
    _Modul('Ambar G/Ç', 'Ambar giriş / çıkış', 'ambargc', Color(0xFFEA580C)),
  ]),
  _Grup('Finans ve Cari', [
    _Modul('Finans', 'Kasa, banka, çek, senet', 'finansnew', Color(0xFF0891B2)),
    _Modul('Cari', 'Müşteri / tedarikçi', 'cari', Color(0xFFDB2777)),
  ]),
  _Grup('Analiz', [
    _Modul('Raporlama', 'Plasiyer özeti, ekstre, Z raporu', 'raporlama',
        Color(0xFF4F46E5)),
  ]),
];

const _hizliTanim = <String, _Hizli>{
  'Fatura': _Hizli('Fatura', Icons.receipt_long_rounded, Color(0xFF2563EB)),
  'Finans': _Hizli('Finans', Icons.payments_rounded, Color(0xFF0891B2)),
  'Depo': _Hizli('Depo', Icons.local_shipping_rounded, Color(0xFF16A34A)),
  'Raporlama':
      _Hizli('Raporlar', Icons.person_pin_circle_rounded, Color(0xFF4F46E5)),
  'Stok': _Hizli('Stok\nSorgu', Icons.inventory_2_rounded, Color(0xFFF59E0B)),
  'Cari': _Hizli('Cari\nHesaplar', Icons.business_rounded, Color(0xFFDB2777)),
  'İrsaliye':
      _Hizli('İrsaliye', Icons.local_shipping_outlined, Color(0xFF0EA5A4)),
  'Sipariş': _Hizli('Sipariş', Icons.assignment_rounded, Color(0xFF7C3AED)),
  'Teklif': _Hizli('Teklif', Icons.request_quote_outlined, Color(0xFF3949AB)),
  'Ambar G/Ç': _Hizli('Ambar\nG/Ç', Icons.warehouse_rounded, Color(0xFFEA580C)),
};

const _varsayilanHizli = ['Fatura', 'Finans', 'Depo', 'Raporlama'];
const _kullanimAnahtari = 'ana_sayfa_modul_kullanim';

class _AnaSayfaYeniTasarimPageState extends State<AnaSayfaYeniTasarimPage> {
  String _ara = '';
  List<String>? _secilenHizli;
  final _hizliScroll = ScrollController();
  String get _hizliAnahtari => 'modern_quick_access_v1_${widget.kullanici}';

  @override
  void dispose() {
    AuthorizationSession.instance.removeListener(_permissionsChanged);
    _hizliScroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnaSayfaYeniTasarimPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kullanici != widget.kullanici) {
      _secilenHizli = null;
      _hizliYukle();
    }
  }

  Future<void> _hizliYukle() async {
    final key = _hizliAnahtari;
    final prefs = await SharedPreferences.getInstance();
    if (mounted && key == _hizliAnahtari) {
      setState(() => _secilenHizli = prefs.getStringList(key));
    }
  }

  Future<void> _hizliDuzenle() async {
    final key = _hizliAnahtari;
    final chosen = _hizliListe.toSet();
    final available = _hizliTanim.keys
        .where(
            (ad) => widget.aksiyonlar.containsKey(ad) && MenuAccess.visible(ad))
        .toList();
    final result = await showDialog<List<String>>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                  title: const Text('Hızlı Erişim'),
                  content: SizedBox(
                      width: 360,
                      child: SingleChildScrollView(
                          child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final ad in available)
                            CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              secondary: CorporateMenuIcon(ad,
                                  size: 26, fallback: _hizliTanim[ad]!.ikon),
                              title: Text(ad),
                              value: chosen.contains(ad),
                              onChanged: (value) => update(() {
                                value == true
                                    ? chosen.add(ad)
                                    : chosen.remove(ad);
                              }),
                            )
                        ],
                      ))),
                  actions: [
                    ErpDialogAction(
                        secondary: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Vazgeç')),
                    FilledButton(
                        onPressed: () => Navigator.pop(
                            ctx, chosen.where(available.contains).toList()),
                        style: FilledButton.styleFrom(
                            backgroundColor: _indigo,
                            foregroundColor: Colors.white),
                        child: const Text('Kaydet'))
                  ],
                )));
    if (result == null || !mounted || key != _hizliAnahtari) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, result);
    if (mounted && key == _hizliAnahtari)
      setState(() => _secilenHizli = result);
  }

  // Sık kullanılanlar
  Map<String, int> _kullanim = {};

  // Günün özeti (null = alınamadı)
  bool _ozetYukleniyor = true;
  double? _satis, _tahsilat;

  // Rozetler: modül adı → taslak belge sayısı
  final Map<String, int> _taslak = {};

  late _Renk _t;

  @override
  void initState() {
    super.initState();
    _hizliYukle();
    AuthorizationSession.instance.addListener(_permissionsChanged);
    _kullanimYukle();
    _verileriYukle();
  }

  void _permissionsChanged() {
    if (!mounted) return;
    setState(() {
      _satis = null;
      _tahsilat = null;
      _taslak.clear();
    });
    _verileriYukle();
  }

  // ── Sık kullanılanlar ──────────────────────────────────────────────────────
  Future<void> _kullanimYukle() async {
    final p = await SharedPreferences.getInstance();
    final ham = p.getString(_kullanimAnahtari);
    if (ham == null) return;
    try {
      final m = (jsonDecode(ham) as Map)
          .map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      if (mounted) setState(() => _kullanim = m);
    } catch (_) {}
  }

  Future<void> _kullanimKaydet(String ad) async {
    _kullanim[ad] = (_kullanim[ad] ?? 0) + 1;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kullanimAnahtari, jsonEncode(_kullanim));
  }

  /// En çok kullanılan 4 modül; eksikse varsayılanlarla tamamlanır.
  List<String> get _hizliListe {
    if (_secilenHizli != null) {
      return _secilenHizli!
          .where((ad) =>
              _hizliTanim.containsKey(ad) &&
              widget.aksiyonlar.containsKey(ad) &&
              MenuAccess.visible(ad))
          .toList();
    }
    final sirali = _kullanim.entries
        .where((e) => _hizliTanim.containsKey(e.key))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final liste = [for (final e in sirali.take(4)) e.key];
    for (final v in _varsayilanHizli) {
      if (liste.length >= 4) break;
      if (!liste.contains(v)) liste.add(v);
    }
    return liste.where(MenuAccess.visible).toList();
  }

  void _git(String ad) {
    _kullanimKaydet(ad);
    final f = widget.aksiyonlar[ad];
    if (f != null) f();
  }

  // ── Gerçek veri: günün özeti + taslak sayıları ─────────────────────────────
  Future<T?> _g<T>(Future<T> Function() getir) async {
    try {
      return await getir();
    } catch (e) {
      debugPrint('Ana sayfa verisi alınamadı: $e');
      return null;
    }
  }

  Future<void> _verileriYukle() async {
    final revision = AuthorizationSession.instance.revision;
    final p = await SharedPreferences.getInstance();
    final token = p.getString('token_final') ?? '';
    final kp = await KullaniciPlasiyerHelper.getir();
    if (revision != AuthorizationSession.instance.revision) return;
    final now = DateTime.now();
    final bugun = DateTime(now.year, now.month, now.day);
    bool bugunMu(DateTime? d) =>
        d != null &&
        d.year == bugun.year &&
        d.month == bugun.month &&
        d.day == bugun.day;

    final s = await Future.wait<Object?>([
      AuthorizationSession.instance.can(301, Access.read)
          ? _g(() => FaturaService().getSatisFaturaList(token))
          : Future.value(null),
      AuthorizationSession.instance.can(501, Access.read)
          ? _g(() => IrsaliyeService().getList(token))
          : Future.value(null),
      AuthorizationSession.instance.can(401, Access.read)
          ? _g(() => SiparisService().getSatisList(token))
          : Future.value(null),
      AuthorizationSession.instance.can(801, Access.read)
          ? _g(() => DatService().getList(token))
          : Future.value(null),
      AuthorizationSession.instance.can(5101, Access.read)
          ? _g(() => RaporApi.post(
                'VW_Finanskasahareket/Query',
                RaporApi.filtre(
                    tarih1: bugun,
                    tarih2: bugun,
                    plasiyerid: kp.kilitli ? kp.plasiyerid : null),
              ))
          : Future.value(null),
    ]);

    final faturalar = s[0] as List?;
    final irsaliyeler = s[1] as List?;
    final siparisler = s[2] as List?;
    final datlar = s[3] as List?;
    final kasa = s[4] as List<RaporKayit>?;

    // Satış: bugünkü tamamlanmış satış faturaları (liste yetkisi yoksa özet görünümünden)
    double? satis;
    if (faturalar != null) {
      satis = faturalar
          .where((f) => f.belgedurum == 1 && bugunMu(f.tarih))
          .fold<double>(
              0, (t, f) => t + ((f.genelToplam as num?)?.toDouble() ?? 0));
    } else if (AuthorizationSession.instance.can(5103, Access.read)) {
      final v = await _g(() => RaporApi.post('VW_Faturairsaliyeicmali/Query',
          RaporApi.filtre(tarih1: bugun, tarih2: bugun)));
      if (v != null) {
        satis = v
            .where((r) => r.i('belgeturu') == 1)
            .fold<double>(0, (t, r) => t + r.d('geneltoplam'));
      }
    }

    // Tahsilat: bugün kasaya giren tutar
    double? tahsilat;
    if (kasa != null) {
      tahsilat = kasa.where((r) => r.i('giriscikis') == 1).fold<double>(0,
          (t, r) => t + (r.d('tutar') != 0 ? r.d('tutar') : r.d('borctutar')));
    }

    int taslak(List? l) =>
        l == null ? -1 : l.where((x) => x.belgedurum == 0).length;
    final t = {
      'Fatura': taslak(faturalar),
      'İrsaliye': taslak(irsaliyeler),
      'Sipariş': taslak(siparisler),
      'Depo': taslak(datlar)
    };

    if (!mounted) return;
    setState(() {
      if (revision != AuthorizationSession.instance.revision) return;
      _satis = satis;
      _tahsilat = tahsilat;
      _ozetYukleniyor = false;
      _taslak
        ..clear()
        ..addEntries(t.entries.where((e) => e.value > 0));
    });
  }

  // ── Görünüm ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    _t = _Renk.of(context);
    final q = _ara.trim().toLowerCase();
    final gruplar = [
      for (final g in _gruplar)
        _Grup(g.baslik, [
          for (final m in g.moduller)
            if (MenuAccess.visible(m.ad) &&
                (q.isEmpty ||
                    m.ad.toLowerCase().contains(q) ||
                    m.alt.toLowerCase().contains(q)))
              m
        ]),
    ].where((g) => g.moduller.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: _t.zemin,
      bottomNavigationBar: _altCubuk(),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _ust(context)),
        SliverToBoxAdapter(
            child: q.isEmpty ? _gunOzeti() : const SizedBox.shrink()),
        SliverToBoxAdapter(
            child: q.isEmpty ? _hizliIslemler() : const SizedBox.shrink()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              for (final g in gruplar) _grupPaneli(g),
              if (gruplar.isEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                        child: Text('Sonuç yok',
                            style: TextStyle(color: _t.soluk)))),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => widget.aksiyonlar['Çıkış']?.call(),
                icon: const CorporateMenuIcon('Çıkış', size: 22),
                label: const Text('Çıkış Yap'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Üst alan ───────────────────────────────────────────────────────────────
  Widget _ust(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
            14, MediaQuery.of(context).padding.top + 8, 14, 12),
        decoration: const BoxDecoration(
          color: _lacivert,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Column(children: [
          Row(children: [
            PopupMenuButton<String>(
              tooltip: 'Hesap ve Ayarlar',
              icon: const CorporateMenuIcon('Kullanıcı',
                  size: 26, onColoredSurface: true),
              onSelected: (value) => widget.aksiyonlar[value]?.call(),
              itemBuilder: (_) => [
                for (final title in ['Ayarlar', 'Yazıcı', 'Çıkış'])
                  PopupMenuItem(
                      value: title,
                      child: Row(children: [
                        CorporateMenuIcon(title, size: 24),
                        const SizedBox(width: 10),
                        Text(title)
                      ]))
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo_filerp.png',
                  width: 30, height: 30, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FilERP Mobile',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis),
                    Tooltip(
                        message: 'Şube değiştir',
                        child: InkWell(
                            key: const ValueKey('branch-switch'),
                            onTap: widget.aksiyonlar['Şube Değiştir'],
                            child: Row(children: [
                              Expanded(
                                  child: Text(
                                      '${widget.firma} • ${widget.sube}',
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11.5),
                                      overflow: TextOverflow.ellipsis)),
                              const Icon(Icons.expand_more_rounded,
                                  size: 16, color: Colors.white70)
                            ]))),
                  ]),
            ),
            IconButton(
              tooltip: 'Açık/Koyu Tema',
              visualDensity: VisualDensity.compact,
              icon: Icon(
                  _t.koyu ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: Colors.white),
              onPressed: () => widget.aksiyonlar['Tema']?.call(),
            ),
          ]),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: TextField(
              onChanged: (v) => setState(() => _ara = v),
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: 'Modül ara…',
                hintStyle:
                    TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: Color(0xFF6B7280)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
        ]),
      );

  // ── Günün özeti (gerçek veri) ──────────────────────────────────────────────
  Widget _gunOzeti() {
    final acik =
        (_satis != null && _tahsilat != null) ? _satis! - _tahsilat! : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: _t.kart, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          _ozet('Satış', _satis, Icons.trending_up_rounded,
              const Color(0xFF3B82F6)),
          _ayrac(),
          _ozet('Tahsilat', _tahsilat, Icons.payments_rounded,
              const Color(0xFF22C55E)),
          _ayrac(),
          _ozet('Fark', acik, Icons.hourglass_bottom_rounded,
              const Color(0xFFF59E0B)),
        ]),
      ),
    );
  }

  Widget _ayrac() => Container(width: 1, height: 30, color: _t.ayrac);

  Widget _ozet(String ad, double? deger, IconData ikon, Color renk) => Expanded(
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(ad,
                style: TextStyle(
                    fontSize: 12.5,
                    color: _t.soluk,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          _ozetYukleniyor
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: Padding(
                      padding: EdgeInsets.all(2),
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(deger == null ? '—' : '${rapTutar(deger)} ₺',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: _t.yazi)))),
        ]),
      );

  // ── Sık kullanılanlar (hızlı işlemler) ─────────────────────────────────────
  Widget _hizliIslemler() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: Text('Hızlı Erişim',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _t.yazi))),
            TextButton.icon(
                key: const ValueKey('modern-quick-edit'),
                onPressed: _hizliDuzenle,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ekle / Düzenle'),
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact)),
          ]),
          const SizedBox(height: 4),
          if (_hizliListe.isEmpty)
            Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                    onPressed: _hizliDuzenle,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Kart Ekle')))
          else
            LayoutBuilder(builder: (context, constraints) {
              final count = constraints.maxWidth < 340 ? 3 : 4;
              final width = (constraints.maxWidth - (count - 1) * 10) / count;
              final height = 84.0 +
                  (MediaQuery.textScalerOf(context).scale(12) - 12)
                      .clamp(0.0, 30.0);
              final items = _hizliListe;
              return SizedBox(
                  height: height + 12,
                  child: Scrollbar(
                    controller: _hizliScroll,
                    thumbVisibility: true,
                    child: ListView.separated(
                      key: const ValueKey('modern-quick-list'),
                      controller: _hizliScroll,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 10),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, index) =>
                          SizedBox(width: width, child: _hizli(items[index])),
                    ),
                  ));
            }),
        ]),
      );

  Widget _hizli(String ad) {
    final h = _hizliTanim[ad]!;
    return Material(
      color: _indigo,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _git(ad),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CorporateMenuIcon(ad, size: 30, onColoredSurface: true),
            const SizedBox(height: 6),
            Flexible(
                child: SizedBox(
                    height:
                        MediaQuery.textScalerOf(context).scale(12) * 2.3 + 1,
                    child: Text(h.etiket,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            color: Colors.white)))),
          ]),
        ),
      ),
    );
  }

  // ── Modül kutusu ───────────────────────────────────────────────────────────
  Widget _kart(_Modul m) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        builder: (_, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
                offset: Offset(0, 10 * (1 - t)), child: child)),
        child: _kartGovde(m),
      );

  // ── Grup paneli: her grup kendi düz renk alanında, kendi dizilişiyle ───────
  Widget _grupPaneli(_Grup g) {
    final renk = g.moduller.first.renk;
    final alan =
        Color.alphaBlend(renk.withOpacity(_t.koyu ? 0.18 : 0.11), _t.zemin);
    final m = g.moduller;
    Widget icerik;
    switch (g.baslik) {
      case 'Satış':
        if (m.length < 3) {
          icerik = Column(children: [
            for (final module in m)
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                      height: 74, child: _yatayKart(module, genis: true)))
          ]);
          break;
        }
        icerik = Column(children: [
          SizedBox(
              height: 150,
              child: Row(children: [
                Expanded(flex: 5, child: _buyukKart(m[0])),
                const SizedBox(width: 8),
                Expanded(
                    flex: 6,
                    child: Column(children: [
                      Expanded(child: _yatayKart(m[1])),
                      const SizedBox(height: 8),
                      Expanded(child: _yatayKart(m[2])),
                    ])),
              ])),
          for (final module in m.skip(3))
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                    height: 74, child: _yatayKart(module, genis: true))),
        ]);
        break;
      case 'Stok ve Depo': // üç eşit dikey kutu
        icerik = Row(children: [
          for (var i = 0; i < m.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: AspectRatio(aspectRatio: 1.0, child: _kart(m[i]))),
          ],
        ]);
        break;
      case 'Finans ve Cari': // iki yatay kutu yan yana
        icerik = SizedBox(
          height: 74,
          child: Row(children: [
            for (var i = 0; i < m.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _yatayKart(m[i])),
            ],
          ]),
        );
        break;
      default: // tek tam genişlik bant
        icerik = SizedBox(height: 74, child: _yatayKart(m[0], genis: true));
    }
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration:
          BoxDecoration(color: alan, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 0, 8),
          child: Text(g.baslik,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: _t.yazi)),
        ),
        icerik,
      ]),
    );
  }

  Widget _kartKabuk(_Modul m, Widget child) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        builder: (_, t, c) => Opacity(
            opacity: t,
            child:
                Transform.translate(offset: Offset(0, 10 * (1 - t)), child: c)),
        child: Material(
          color: _t.kart,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: () => _git(m.ad), child: child),
        ),
      );

  Widget _rozet(_Modul m) {
    final n = _taslak[m.ad] ?? 0;
    if (n <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: const Color(0xFFF59E0B),
          borderRadius: BorderRadius.circular(10)),
      child: Text('$n',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Colors.white)),
    );
  }

  /// Satışın ana kutusu: büyük ikon, büyük ad, alt açıklama.
  Widget _buyukKart(_Modul m) => _kartKabuk(
        m,
        Stack(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                      width: 56,
                      height: 56,
                      child: CorporateMenuIcon(m.ad, size: 56)),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.ad,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: _t.yazi)),
                        const SizedBox(height: 2),
                        Text(m.alt,
                            style: TextStyle(fontSize: 11.5, color: _t.soluk),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ]),
                ]),
          ),
          Positioned(top: 8, right: 8, child: _rozet(m)),
        ]),
      );

  /// Yatay kutu: solda ikon, sağda ad ve açıklama.
  Widget _yatayKart(_Modul m, {bool genis = false}) => _kartKabuk(
        m,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            SizedBox(
                width: genis ? 44 : 36,
                height: genis ? 44 : 36,
                child: CorporateMenuIcon(m.ad, size: genis ? 44 : 36)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.ad,
                        style: TextStyle(
                            fontSize: genis ? 16 : 14,
                            fontWeight: FontWeight.w800,
                            color: _t.yazi),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (genis || m.alt.length < 40)
                      Text(m.alt,
                          style: TextStyle(fontSize: 11, color: _t.soluk),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ]),
            ),
            _rozet(m),
            if (genis)
              Icon(Icons.arrow_forward_rounded, size: 20, color: _t.soluk),
          ]),
        ),
      );

  Widget _kartGovde(_Modul m) {
    final taslak = _taslak[m.ad] ?? 0;
    return Container(
      child: Material(
        color: _t.kart,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _git(m.ad),
          child: Stack(children: [
            Positioned.fill(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: CorporateMenuIcon(m.ad, size: 56),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(m.ad,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _t.yazi)),
                      ),
                    ),
                  ]),
            ),
            if (taslak > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Tooltip(
                  message: '$taslak taslak belge',
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('$taslak',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  // ── Alt çubuk ──────────────────────────────────────────────────────────────
  Widget _altCubuk() => Container(
        decoration: BoxDecoration(
          color: _t.kart,
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(children: [
              _altOge(Icons.home_rounded, 'Ana Sayfa', true, () {}),
              if (MenuAccess.visible('Raporlar'))
                _altOge(Icons.bar_chart_rounded, 'Raporlar', false,
                    () => _git('Raporlama')),
              _altOge(Icons.settings_rounded, 'Ayarlar', false,
                  () => _git('Ayarlar')),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: OfflineService.instance.isOnline,
                  builder: (_, online, __) => ValueListenableBuilder<int>(
                    valueListenable: OfflineService.instance.pendingCount,
                    builder: (_, bekleyen, __) {
                      final renk = !online
                          ? const Color(0xFFEF4444)
                          : (bekleyen > 0
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF22C55E));
                      return InkWell(
                        onTap: () => widget.aksiyonlar['Ayarlar']?.call(),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Badge(
                                isLabelVisible: bekleyen > 0,
                                label: Text('$bekleyen',
                                    style: const TextStyle(fontSize: 10)),
                                child: Icon(
                                    online
                                        ? Icons.cloud_done_rounded
                                        : Icons.cloud_off_rounded,
                                    size: 22,
                                    color: renk),
                              ),
                              Text(
                                  !online
                                      ? 'Çevrimdışı'
                                      : (bekleyen > 0 ? 'Bekleyen' : 'Senkron'),
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: renk)),
                            ]),
                      );
                    },
                  ),
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _altOge(IconData ikon, String ad, bool secili, VoidCallback onTap) =>
      Expanded(
        child: InkWell(
          onTap: onTap,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (CorporateMenuIcon.resolve(ad) != null)
              CorporateMenuIcon(ad, size: 24, fallback: ikon)
            else
              Icon(ikon,
                  size: 22,
                  color: secili
                      ? (_t.koyu ? const Color(0xFF93A4FF) : _indigo)
                      : _t.soluk),
            Text(ad,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: secili
                        ? (_t.koyu ? const Color(0xFF93A4FF) : _indigo)
                        : _t.soluk)),
          ]),
        ),
      );
}
