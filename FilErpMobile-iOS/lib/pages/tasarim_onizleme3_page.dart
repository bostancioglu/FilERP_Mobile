import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// TASARIM ÖNİZLEME 3 — iki yeni yön (açık tema, mevcut mavi ile uyumlu):
///  D) Gruplu liste (bankacılık uygulaması tarzı)   E) Kategori çipli kartlar + hızlı işlem düğmesi
/// Veriler örnektir. Beğenilmezse bu dosya + home_page'deki menü satırı silinir.
class TasarimOnizleme3Page extends StatefulWidget {
  const TasarimOnizleme3Page({super.key});

  @override
  State<TasarimOnizleme3Page> createState() => _TasarimOnizleme3PageState();
}

const _bg = Color(0xFFF2F4F8);
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _brand = Color(0xFF044DAC);
const _line = Color(0xFFE5E7EB);

class _M {
  final String ad, alt, asset, grup;
  final Color renk;
  const _M(this.ad, this.alt, this.asset, this.grup, this.renk);
}

const _moduller = [
  _M('Fatura', 'Satış ve alış faturaları', 'assets/icons/new/fatura.png',
      'Satış', Color(0xFF2F7BFF)),
  _M('İrsaliye', 'Satış ve alış irsaliyeleri',
      'assets/icons/new/satis_irsaliyesi.png', 'Satış', Color(0xFFEC4899)),
  _M('Sipariş', 'Satış ve alış siparişleri', 'assets/icons/new/siparisler.png',
      'Satış', Color(0xFFEF4444)),
  _M('Stok', 'Ürün kartları ve hareketler', 'assets/icons/new/stok.png', 'Stok',
      Color(0xFFF59E0B)),
  _M('Depo', 'Depo transfer (DAT)', 'assets/icons/new/dat.png', 'Stok',
      Color(0xFF10B981)),
  _M('Ambar G/Ç', 'Ambar giriş / çıkış fişleri', 'assets/icons/new/ambargc.png',
      'Stok', Color(0xFF8B5CF6)),
  _M('Finans', 'Kasa, banka, çek, senet', 'assets/icons/new/finansnew.png',
      'Finans', Color(0xFF0EA5A4)),
  _M('Cari', 'Müşteri ve tedarikçi kartları', 'assets/icons/new/cari.png',
      'Finans', Color(0xFF6366F1)),
  _M('Raporlama', 'Cari, stok, günlük özet', 'assets/icons/new/raporlama.png',
      'Rapor', Color(0xFF14B8A6)),
];

class _TasarimOnizleme3PageState extends State<TasarimOnizleme3Page> {
  int _stil = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        Container(
          color: _stil == 1 ? _brand : _bg,
          padding: EdgeInsets.fromLTRB(
              8, MediaQuery.of(context).padding.top + 6, 16, 6),
          child: Row(children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_rounded,
                  color: _stil == 1 ? Colors.white : _ink),
            ),
            const Spacer(),
            SegmentedButton<int>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.white,
              ),
              segments: const [
                ButtonSegment(value: 0, label: Text('D • Gruplu liste')),
                ButtonSegment(value: 1, label: Text('E • Çipli kartlar')),
              ],
              selected: {_stil},
              onSelectionChanged: (s) => setState(() => _stil = s.first),
            ),
          ]),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: 250.ms,
            child: _stil == 0
                ? const _GrupluListe(key: ValueKey('d'))
                : const _CipliKartlar(key: ValueKey('e')),
          ),
        ),
      ]),
    );
  }
}

Widget _squircle(_M m, {double boyut = 44}) => Container(
      width: boyut,
      height: boyut,
      padding: EdgeInsets.all(boyut * 0.2),
      decoration: BoxDecoration(
          color: m.renk.withOpacity(0.12),
          borderRadius: BorderRadius.circular(boyut * 0.32)),
      child: Image.asset(m.asset, fit: BoxFit.contain),
    );

// ══════════════════════════════════════════════════════════════════════════
//  D) GRUPLU LİSTE — zenginleştirilmiş
//   • canlı arama   • özet şeridi   • yıldızla favori (Sık Kullanılanlar güncellenir)
//   • daralan gruplar + grup sayacı   • satır rozetleri   • Liste/Izgara görünümü
//   • Son İşlemler
// ══════════════════════════════════════════════════════════════════════════
class _GrupluListe extends StatefulWidget {
  const _GrupluListe({super.key});

  @override
  State<_GrupluListe> createState() => _GrupluListeState();
}

class _GrupluListeState extends State<_GrupluListe> {
  String _q = '';
  bool _izgara = false;
  final Set<String> _fav = {'Fatura', 'Cari', 'Stok', 'Finans', 'İrsaliye'};
  final Set<String> _kapali = {};

  // Örnek rozetler (gerçekte taslak/bekleyen sayıları servislerden gelir)
  static const _rozet = {
    'Fatura': ('2 taslak', Color(0xFFF59E0B)),
    'Sipariş': ('4 açık', Color(0xFF2F7BFF)),
    'Finans': ('1 bekleyen', Color(0xFFEF4444)),
  };

  static const _grupRenk = {
    'Satış': Color(0xFF2F7BFF),
    'Stok': Color(0xFFF59E0B),
    'Finans': Color(0xFF0EA5A4),
    'Rapor': Color(0xFF14B8A6),
  };

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final gruplar = <String, List<_M>>{};
    for (final m in _moduller) {
      if (q.isNotEmpty &&
          !m.ad.toLowerCase().contains(q) &&
          !m.alt.toLowerCase().contains(q)) continue;
      gruplar.putIfAbsent(m.grup, () => []).add(m);
    }
    final favListe = _moduller.where((m) => _fav.contains(m.ad)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        // ── Başlık ───────────────────────────────────────────────
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/images/logo_filerp.png',
                width: 44, height: 44, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('FilERP',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -0.5)),
              Text('Örnek Firma • Merkez Şube',
                  style: TextStyle(fontSize: 12, color: _muted)),
            ]),
          ),
          Stack(clipBehavior: Clip.none, children: [
            const CircleAvatar(
                radius: 21,
                backgroundColor: _brand,
                child: Text('YE',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13))),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: _bg, width: 2),
                ),
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 18),

        // ── Canlı arama ──────────────────────────────────────────
        TextField(
          onChanged: (v) => setState(() => _q = v),
          decoration: InputDecoration(
            hintText: 'Modül ara… (fatura, stok, kasa)',
            hintStyle: const TextStyle(color: _muted, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: _muted),
            suffixIcon: _q.isEmpty
                ? const Icon(Icons.mic_none_rounded, color: _muted)
                : IconButton(
                    icon: const Icon(Icons.close_rounded, color: _muted),
                    onPressed: () => setState(() => _q = '')),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),

        // ── Özet şeridi ──────────────────────────────────────────
        if (q.isEmpty) ...[
          SizedBox(
            height: 78,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: const [
                _OzetKart('Bugün Satış', '₺ 48.250', '▲ %12', Color(0xFF10B981),
                    Icons.trending_up_rounded),
                _OzetKart('Tahsilat', '₺ 21.900', '7 işlem', Color(0xFF2F7BFF),
                    Icons.payments_outlined),
                _OzetKart('Taslak Belge', '5', 'tamamlanmayı bekliyor',
                    Color(0xFFF59E0B), Icons.edit_note_rounded),
                _OzetKart('Kuyruk', '3', 'gönderilmeyi bekliyor',
                    Color(0xFFEF4444), Icons.cloud_upload_outlined),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0),
          const SizedBox(height: 22),

          // ── Sık kullanılanlar ──────────────────────────────────
          Row(children: [
            const Text('Sık Kullanılanlar',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
            const Spacer(),
            Text('${favListe.length} kısayol',
                style: const TextStyle(fontSize: 12, color: _muted)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: favListe.isEmpty
                ? Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _line),
                    ),
                    child: const Text('Aşağıdaki ★ ile kısayol ekleyin',
                        style: TextStyle(color: _muted, fontSize: 12.5)),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: favListe.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (_, i) {
                      final m = favListe[i];
                      final r = _rozet[m.ad];
                      return SizedBox(
                        width: 64,
                        child: Column(children: [
                          Stack(clipBehavior: Clip.none, children: [
                            Container(
                              width: 62,
                              height: 62,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                    color: m.renk.withOpacity(0.55), width: 2),
                              ),
                              child: Image.asset(m.asset, fit: BoxFit.contain),
                            ),
                            if (r != null)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                      color: r.$2,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _bg, width: 2)),
                                  alignment: Alignment.center,
                                  child: Text(r.$1.split(' ').first,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800)),
                                ),
                              ),
                          ]),
                          const SizedBox(height: 6),
                          Text(m.ad,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _ink)),
                        ]),
                      ).animate().fadeIn().scale(
                          begin: const Offset(0.85, 0.85),
                          end: const Offset(1, 1));
                    },
                  ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Modüller başlığı + görünüm değiştirici ─────────────────
        Row(children: [
          Text(
              q.isEmpty
                  ? 'Modüller'
                  : '${gruplar.values.fold<int>(0, (s, l) => s + l.length)} sonuç',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(3),
            child: Row(children: [
              _gorunumDugme(Icons.view_agenda_outlined, !_izgara,
                  () => setState(() => _izgara = false)),
              _gorunumDugme(Icons.grid_view_rounded, _izgara,
                  () => setState(() => _izgara = true)),
            ]),
          ),
        ]),

        if (gruplar.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Column(children: [
              Icon(Icons.search_off_rounded,
                  size: 52, color: Color(0xFFCBD2DC)),
              SizedBox(height: 10),
              Text('Eşleşen modül bulunamadı', style: TextStyle(color: _muted)),
            ]),
          ),

        // ── Gruplar ────────────────────────────────────────────
        for (final e in gruplar.entries) ...[
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _kapali.contains(e.key)
                ? _kapali.remove(e.key)
                : _kapali.add(e.key)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Row(children: [
                Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                        color: _grupRenk[e.key],
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text(e.key.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _muted,
                        letterSpacing: 1.1)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                      color: _line, borderRadius: BorderRadius.circular(8)),
                  child: Text('${e.value.length}',
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _muted)),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _kapali.contains(e.key) ? -0.25 : 0,
                  duration: 200.ms,
                  child: const Icon(Icons.expand_more_rounded,
                      color: _muted, size: 22),
                ),
              ]),
            ),
          ),
          AnimatedSize(
            duration: 250.ms,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _kapali.contains(e.key)
                ? const SizedBox(width: double.infinity)
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: _izgara ? _grupIzgara(e.value) : _grupListe(e.value),
                  ),
          ),
        ],

        // ── Son işlemler ─────────────────────────────────────────
        if (q.isEmpty) ...[
          const SizedBox(height: 26),
          const Text('Son İşlemler',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Column(children: [
              _SonIslem(
                  Icons.receipt_long_rounded,
                  Color(0xFF2F7BFF),
                  'Satış Faturası • Yıldız Market',
                  '₺ 12.480,00',
                  'Bugün 10:42',
                  true),
              Divider(height: 1, indent: 66, color: _line),
              _SonIslem(Icons.account_balance_wallet_rounded, Color(0xFF0EA5A4),
                  'Tahsilat • Atlas Gıda', '₺ 6.000,00', 'Bugün 09:15', true),
              Divider(height: 1, indent: 66, color: _line),
              _SonIslem(Icons.edit_note_rounded, Color(0xFFF59E0B),
                  'Çek Bordrosu • Demir Ticaret', '₺ 18.750,00', 'Dün', false),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _gorunumDugme(IconData i, bool aktif, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: aktif ? _brand : Colors.transparent,
              borderRadius: BorderRadius.circular(9)),
          child: Icon(i, size: 18, color: aktif ? Colors.white : _muted),
        ),
      );

  // Liste görünümü
  Widget _grupListe(List<_M> l) => Column(children: [
        for (var i = 0; i < l.length; i++) ...[
          _satir(l[i], ilk: i == 0, son: i == l.length - 1),
          if (i != l.length - 1)
            const Padding(
                padding: EdgeInsets.only(left: 72),
                child: Divider(height: 1, color: _line)),
        ],
      ]);

  // Izgara görünümü (3 sütun, kompakt). Uzun basınca kısayola ekler/çıkarır.
  Widget _grupIzgara(List<_M> l) => Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.95,
          children: [
            for (final m in l)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {},
                onLongPress: () => setState(() =>
                    _fav.contains(m.ad) ? _fav.remove(m.ad) : _fav.add(m.ad)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(clipBehavior: Clip.none, children: [
                        _squircle(m, boyut: 50),
                        if (_rozet[m.ad] != null)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                  color: _rozet[m.ad]!.$2,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(_rozet[m.ad]!.$1.split(' ').first,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 7),
                      Text(m.ad,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _ink)),
                    ]),
              ),
          ],
        ),
      );

  Widget _satir(_M m, {required bool ilk, required bool son}) {
    final r = _rozet[m.ad];
    final fav = _fav.contains(m.ad);
    return InkWell(
      borderRadius: BorderRadius.vertical(
          top: Radius.circular(ilk ? 20 : 0),
          bottom: Radius.circular(son ? 20 : 0)),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(children: [
          _squircle(m),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                    child: Text(m.ad,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _ink))),
                if (r != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: r.$2.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(r.$1,
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: r.$2)),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Text(m.alt, style: const TextStyle(fontSize: 12, color: _muted)),
            ]),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: fav ? 'Kısayoldan çıkar' : 'Kısayol ekle',
            onPressed: () =>
                setState(() => fav ? _fav.remove(m.ad) : _fav.add(m.ad)),
            icon: Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded,
                color: fav ? const Color(0xFFF59E0B) : const Color(0xFFB6BCC8),
                size: 22),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB6BCC8)),
          const SizedBox(width: 4),
        ]),
      ),
    );
  }
}

class _OzetKart extends StatelessWidget {
  final String baslik, deger, alt;
  final Color renk;
  final IconData ikon;
  const _OzetKart(this.baslik, this.deger, this.alt, this.renk, this.ikon);

  @override
  Widget build(BuildContext context) => Container(
        width: 156,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: renk.withOpacity(0.13),
                borderRadius: BorderRadius.circular(11)),
            child: Icon(ikon, color: renk, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: _muted)),
                  Text(deger,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  Text(alt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: renk)),
                ]),
          ),
        ]),
      );
}

class _SonIslem extends StatelessWidget {
  final IconData ikon;
  final Color renk;
  final String baslik, tutar, zaman;
  final bool tamam;
  const _SonIslem(
      this.ikon, this.renk, this.baslik, this.tutar, this.zaman, this.tamam);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: renk.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(ikon, color: renk, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _ink)),
              const SizedBox(height: 2),
              Row(children: [
                Icon(
                    tamam ? Icons.check_circle_rounded : Icons.schedule_rounded,
                    size: 12,
                    color: tamam
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text('${tamam ? 'Tamamlandı' : 'Taslak'} • $zaman',
                    style: const TextStyle(fontSize: 11, color: _muted)),
              ]),
            ]),
          ),
          Text(tutar,
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink)),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════════════════
//  E) KATEGORİ ÇİPLİ KARTLAR + HIZLI İŞLEM
// ══════════════════════════════════════════════════════════════════════════
class _CipliKartlar extends StatefulWidget {
  const _CipliKartlar({super.key});

  @override
  State<_CipliKartlar> createState() => _CipliKartlarState();
}

class _CipliKartlarState extends State<_CipliKartlar> {
  String _grup = 'Tümü';
  static const _gruplar = ['Tümü', 'Satış', 'Stok', 'Finans', 'Rapor'];

  List<_M> get _liste => _grup == 'Tümü'
      ? _moduller
      : _moduller.where((m) => m.grup == _grup).toList();

  void _hizliIslem() {
    const islemler = [
      (Icons.receipt_long_rounded, 'Yeni Fatura', Color(0xFF2F7BFF)),
      (Icons.account_balance_wallet_rounded, 'Tahsilat', Color(0xFF0EA5A4)),
      (Icons.qr_code_scanner_rounded, 'Hızlı Barkod', Color(0xFFF59E0B)),
      (Icons.local_shipping_rounded, 'İrsaliye', Color(0xFFEC4899)),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: _line, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Hızlı İşlem',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final i in islemler)
                  Material(
                    color: i.$3.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(children: [
                          Icon(i.$1, color: i.$3),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(i.$2,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _ink,
                                      fontSize: 13.5))),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(children: [
        // Mavi üst şerit (sade, tek renk)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 26),
          decoration: const BoxDecoration(
            color: _brand,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hoş geldin',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13)),
                    const SizedBox(height: 2),
                    const Text('Yunus Emre',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Text('Örnek Firma • Merkez Şube',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12)),
                  ]),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.search_rounded, color: Colors.white),
            ),
          ]),
        ),

        // Kategori çipleri
        SizedBox(
          height: 58,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            scrollDirection: Axis.horizontal,
            itemCount: _gruplar.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final secili = _gruplar[i] == _grup;
              return GestureDetector(
                onTap: () => setState(() => _grup = _gruplar[i]),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: secili ? _ink : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_gruplar[i],
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: secili ? Colors.white : _muted)),
                ),
              );
            },
          ),
        ),

        // Kartlar
        Expanded(
          child: GridView.builder(
            key: ValueKey(_grup),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            itemCount: _liste.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (_, i) {
              final m = _liste[i];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {},
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              _squircle(m, boyut: 48),
                              const Spacer(),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                    color: _bg, shape: BoxShape.circle),
                                child: const Icon(Icons.arrow_forward_rounded,
                                    size: 15, color: _muted),
                              ),
                            ]),
                            const Spacer(),
                            Text(m.ad,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                    letterSpacing: -0.2)),
                            const SizedBox(height: 2),
                            Text(m.alt,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    color: _muted,
                                    height: 1.25)),
                          ]),
                    ),
                  ),
                ),
              )
                  .animate(delay: (40 * i).ms)
                  .fadeIn(duration: 250.ms)
                  .slideY(begin: 0.06, end: 0);
            },
          ),
        ),
      ]),

      // Alt dock + ortada hızlı işlem düğmesi
      Positioned(
        left: 20,
        right: 20,
        bottom: 18,
        child: SizedBox(
          height: 72,
          child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 62,
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DockItem(Icons.home_rounded, 'Ana Sayfa', true),
                        _DockItem(Icons.sync_rounded, 'Bekleyen', false),
                        SizedBox(width: 56),
                        _DockItem(Icons.notifications_none_rounded, 'Bildirim',
                            false),
                        _DockItem(
                            Icons.person_outline_rounded, 'Profil', false),
                      ]),
                ),
                Positioned(
                  top: 0,
                  child: GestureDetector(
                    onTap: _hizliIslem,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F7BFF),
                        shape: BoxShape.circle,
                        border: Border.all(color: _bg, width: 4),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF2F7BFF).withOpacity(0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 6))
                        ],
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ]),
        ),
      ),
    ]);
  }
}

class _DockItem extends StatelessWidget {
  final IconData ikon;
  final String ad;
  final bool aktif;
  const _DockItem(this.ikon, this.ad, this.aktif);

  @override
  Widget build(BuildContext context) {
    final c = aktif ? Colors.white : Colors.white.withOpacity(0.5);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(ikon, color: c, size: 22),
      const SizedBox(height: 2),
      Text(ad,
          style: TextStyle(
              color: c,
              fontSize: 10,
              fontWeight: aktif ? FontWeight.w700 : FontWeight.w500)),
    ]);
  }
}
