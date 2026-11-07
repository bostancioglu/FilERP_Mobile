import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// TASARIM ÖNİZLEME — mevcut ekranlara dokunmadan "modern kabuk" örneği.
/// Veriler örnektir (sabit). Beğenilirse bileşenler ortak widget'a çıkarılıp
/// ekranlara tek tek uygulanır. Beğenilmezse bu dosya + home_page'deki menü
/// satırı silinerek geri alınır.
class TasarimOnizlemePage extends StatefulWidget {
  const TasarimOnizlemePage({super.key});

  @override
  State<TasarimOnizlemePage> createState() => _TasarimOnizlemePageState();
}

const _kInk = Color(0xFF0F172A); // ana metin
const _kMuted = Color(0xFF64748B); // ikincil metin
const _kBg = Color(0xFFF6F7FB); // sayfa zemini
const _kBrand = Color(0xFF044DAC); // mevcut mavi
const _kBrand2 = Color(0xFF2F7BFF); // gradyan açık ucu

class _Modul {
  final String ad;
  final String asset;
  final Color renk;
  const _Modul(this.ad, this.asset, this.renk);
}

const _moduller = [
  _Modul('Finans', 'assets/icons/new/finansnew.png', Color(0xFF0EA5A4)),
  _Modul('Cari', 'assets/icons/new/cari.png', Color(0xFF6366F1)),
  _Modul('Stok', 'assets/icons/new/stok.png', Color(0xFFF59E0B)),
  _Modul('Fatura', 'assets/icons/new/fatura.png', Color(0xFF2F7BFF)),
  _Modul('Depo', 'assets/icons/new/dat.png', Color(0xFF10B981)),
  _Modul(
      'İrsaliye', 'assets/icons/new/satis_irsaliyesi.png', Color(0xFFEC4899)),
  _Modul('Ambar G/Ç', 'assets/icons/new/ambargc.png', Color(0xFF8B5CF6)),
  _Modul('Sipariş', 'assets/icons/new/siparisler.png', Color(0xFFEF4444)),
  _Modul('Rapor', 'assets/icons/new/raporlama.png', Color(0xFF14B8A6)),
];

class _TasarimOnizlemePageState extends State<TasarimOnizlemePage> {
  int _nav = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      extendBody: true,
      bottomNavigationBar: _altBar(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _ustAlan()),
          SliverToBoxAdapter(child: _hizliIslemler()),
          _baslik('Modüller'),
          _modulGrid(),
          _baslik('Son İşlemler', aksiyon: 'Tümü'),
          _sonIslemler(),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  // ── 1) Gradyanlı üst alan: selamlama + arama + özet kartı ────────────────
  Widget _ustAlan() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kBrand, _kBrand2],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 14, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: 'Önizlemeyi kapat',
          ),
          const SizedBox(width: 4),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Merhaba 👋',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 13)),
              const Text('FilERP',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3)),
            ]),
          ),
          _camIkon(Icons.notifications_none_rounded, rozet: true),
          const SizedBox(width: 8),
          _camIkon(Icons.cloud_done_outlined),
        ]),
        const SizedBox(height: 18),
        // arama
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8))
            ],
          ),
          child: const Row(children: [
            Icon(Icons.search_rounded, color: _kMuted),
            SizedBox(width: 10),
            Expanded(
                child: Text('Cari, stok veya belge ara…',
                    style: TextStyle(color: _kMuted, fontSize: 14))),
            Icon(Icons.qr_code_scanner_rounded, color: _kBrand),
          ]),
        ),
        const SizedBox(height: 18),
        // özet kartları
        Row(children: [
          Expanded(
              child: _ozet('Bugün Satış', '₺ 48.250', Icons.trending_up_rounded,
                  const Color(0xFF34D399), '+12%')),
          const SizedBox(width: 12),
          Expanded(
              child: _ozet('Tahsilat', '₺ 21.900', Icons.payments_outlined,
                  const Color(0xFFFBBF24), '7 işlem')),
        ]),
      ]).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05, end: 0),
    );
  }

  Widget _camIkon(IconData i, {bool rozet = false}) =>
      Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(i, color: Colors.white, size: 21),
        ),
        if (rozet)
          Positioned(
            right: 9,
            top: 9,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252),
                shape: BoxShape.circle,
                border: Border.all(color: _kBrand, width: 1.5),
              ),
            ),
          ),
      ]);

  Widget _ozet(String baslik, String deger, IconData ikon, Color vurgu,
          String etiket) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(ikon, size: 18, color: vurgu),
            const SizedBox(width: 6),
            Text(baslik,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          Text(deger,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(etiket,
              style: TextStyle(
                  color: vurgu, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );

  // ── 2) Hızlı işlem çipleri ────────────────────────────────────────────────
  Widget _hizliIslemler() {
    final items = [
      (Icons.receipt_long_rounded, 'Yeni Fatura'),
      (Icons.account_balance_wallet_rounded, 'Tahsilat'),
      (Icons.qr_code_2_rounded, 'Hızlı Barkod'),
      (Icons.local_shipping_rounded, 'İrsaliye'),
    ];
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                Icon(items[i].$1, size: 19, color: _kBrand),
                const SizedBox(width: 8),
                Text(items[i].$2,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kInk)),
              ]),
            ),
          ),
        ).animate(delay: (80 * i).ms).fadeIn().slideX(begin: 0.1, end: 0),
      ),
    );
  }

  SliverToBoxAdapter _baslik(String t, {String? aksiyon}) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
          child: Row(children: [
            Expanded(
                child: Text(t,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                        letterSpacing: -0.2))),
            if (aksiyon != null)
              Text(aksiyon,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kBrand)),
          ]),
        ),
      );

  // ── 3) Modül grid: renkli pastel zemin + mevcut PNG ikon ─────────────────
  Widget _modulGrid() => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid.builder(
          itemCount: _moduller.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (_, i) {
            final m = _moduller[i];
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {},
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: m.renk.withOpacity(0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: m.renk.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Image.asset(m.asset, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 10),
                        Text(m.ad,
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _kInk)),
                      ]),
                ),
              ),
            ).animate(delay: (50 * i).ms).fadeIn(duration: 300.ms).scale(
                begin: const Offset(0.92, 0.92), end: const Offset(1, 1));
          },
        ),
      );

  // ── 4) Liste kartı örneği (belge listeleri için) ──────────────────────────
  Widget _sonIslemler() {
    const rows = [
      (
        'Yıldız Market Ltd.',
        'Satış Faturası • 000000142',
        '₺ 12.480,00',
        'Tamamlandı',
        Color(0xFF10B981),
        true
      ),
      (
        'Atlas Gıda San.',
        'Tahsilat • 000000087',
        '₺ 6.000,00',
        'Tamamlandı',
        Color(0xFF10B981),
        true
      ),
      (
        'Demir Ticaret',
        'Çek Bordrosu • 000000021',
        '₺ 18.750,00',
        'Taslak',
        Color(0xFFF59E0B),
        false
      ),
      (
        'Güneş Kırtasiye',
        'Alış Faturası • 000000310',
        '₺ 3.215,40',
        'Taslak',
        Color(0xFFF59E0B),
        false
      ),
    ];
    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final r = rows[i];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _kBrand.withOpacity(0.10),
                child: Text(r.$1[0],
                    style: const TextStyle(
                        color: _kBrand,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: _kInk)),
                      const SizedBox(height: 3),
                      Text(r.$2,
                          style:
                              const TextStyle(fontSize: 11.5, color: _kMuted)),
                    ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(r.$3,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kInk)),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: r.$5.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration:
                            BoxDecoration(color: r.$5, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(r.$4,
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: r.$5)),
                  ]),
                ),
              ]),
            ]),
          ).animate(delay: (70 * i).ms).fadeIn().slideY(begin: 0.08, end: 0),
        );
      },
    );
  }

  // ── 5) Alt gezinme (Material 3 NavigationBar, yüzen) ─────────────────────
  Widget _altBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: Colors.white,
                indicatorColor: _kBrand.withOpacity(0.12),
                height: 64,
                labelTextStyle:
                    WidgetStateProperty.resolveWith((s) => TextStyle(
                          fontSize: 11,
                          fontWeight: s.contains(WidgetState.selected)
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: s.contains(WidgetState.selected)
                              ? _kBrand
                              : _kMuted,
                        )),
              ),
              child: NavigationBar(
                selectedIndex: _nav,
                onDestinationSelected: (i) => setState(() => _nav = i),
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded, color: _kBrand),
                      label: 'Ana Sayfa'),
                  NavigationDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon:
                          Icon(Icons.grid_view_rounded, color: _kBrand),
                      label: 'Modüller'),
                  NavigationDestination(
                      icon: Icon(Icons.sync_outlined),
                      selectedIcon: Icon(Icons.sync_rounded, color: _kBrand),
                      label: 'Bekleyen'),
                  NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person_rounded, color: _kBrand),
                      label: 'Profil'),
                ],
              ),
            ),
          ),
        ),
      );
}
