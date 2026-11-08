import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// TASARIM ÖNİZLEME 2 — iki farklı yön:
///  B) Koyu "fintech" panosu   C) Açık "bento" karo düzeni
/// Veriler örnektir. Beğenilmezse bu dosya + home_page'deki menü satırı silinir.
class TasarimOnizleme2Page extends StatefulWidget {
  const TasarimOnizleme2Page({super.key});

  @override
  State<TasarimOnizleme2Page> createState() => _TasarimOnizleme2PageState();
}

class _TasarimOnizleme2PageState extends State<TasarimOnizleme2Page> {
  int _stil = 0; // 0 = koyu fintech, 1 = bento

  @override
  Widget build(BuildContext context) {
    final koyu = _stil == 0;
    return Scaffold(
      backgroundColor: koyu ? _DarkP.bg : _BentoP.bg,
      body: Column(children: [
        // Stil değiştirici (sadece önizleme için)
        Container(
          color: koyu ? _DarkP.bg : _BentoP.bg,
          padding: EdgeInsets.fromLTRB(
              8, MediaQuery.of(context).padding.top + 6, 16, 6),
          child: Row(children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_rounded,
                  color: koyu ? Colors.white : Colors.black87),
            ),
            const Spacer(),
            SegmentedButton<int>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact),
              segments: const [
                ButtonSegment(value: 0, label: Text('B • Koyu')),
                ButtonSegment(value: 1, label: Text('C • Bento')),
              ],
              selected: {_stil},
              onSelectionChanged: (s) => setState(() => _stil = s.first),
            ),
          ]),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: 300.ms,
            child: koyu
                ? const _KoyuStil(key: ValueKey('k'))
                : const _BentoStil(key: ValueKey('b')),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  B) KOYU FİNTECH
// ══════════════════════════════════════════════════════════════════════════
class _DarkP {
  static const bg = Color(0xFF0B1220);
  static const card = Color(0xFF131C31);
  static const line = Color(0xFF1F2A44);
  static const text = Color(0xFFE6EBF5);
  static const muted = Color(0xFF8A97B2);
  static const cyan = Color(0xFF38BDF8);
  static const mint = Color(0xFF34D399);
  static const amber = Color(0xFFFBBF24);
  static const rose = Color(0xFFFB7185);
}

class _KoyuStil extends StatelessWidget {
  const _KoyuStil({super.key});

  @override
  Widget build(BuildContext context) {
    const moduller = [
      (Icons.account_balance_wallet_outlined, 'Finans', _DarkP.cyan),
      (Icons.groups_outlined, 'Cari', _DarkP.mint),
      (Icons.inventory_2_outlined, 'Stok', _DarkP.amber),
      (Icons.receipt_long_outlined, 'Fatura', _DarkP.cyan),
      (Icons.warehouse_outlined, 'Depo', _DarkP.mint),
      (Icons.local_shipping_outlined, 'İrsaliye', _DarkP.rose),
      (Icons.swap_vert_rounded, 'Ambar G/Ç', _DarkP.amber),
      (Icons.shopping_bag_outlined, 'Sipariş', _DarkP.rose),
      (Icons.insights_rounded, 'Rapor', _DarkP.cyan),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        const Text('Genel Bakış',
            style: TextStyle(color: _DarkP.muted, fontSize: 13)),
        const SizedBox(height: 2),
        const Text('FilERP',
            style: TextStyle(
                color: _DarkP.text,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5)),
        const SizedBox(height: 18),

        // Ana bakiye kartı + mini grafik
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
            ),
            boxShadow: [
              BoxShadow(
                  color: _DarkP.cyan.withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 14))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Net Nakit Durumu',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Bu ay',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            const Text('₺ 184.730,50',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.arrow_upward_rounded,
                  color: _DarkP.mint, size: 16),
              const SizedBox(width: 2),
              Text('%8,4 geçen aya göre',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 12)),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: CustomPaint(
                  painter:
                      _SparkPainter(const [3, 5, 4, 7, 6, 9, 8, 11, 10, 13])),
            ),
          ]),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),

        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: _kpi(
                  'Alacak', '₺ 92.400', _DarkP.mint, Icons.south_west_rounded)),
          const SizedBox(width: 12),
          Expanded(
              child: _kpi(
                  'Borç', '₺ 41.150', _DarkP.rose, Icons.north_east_rounded)),
        ]).animate(delay: 100.ms).fadeIn().slideY(begin: 0.06, end: 0),

        const SizedBox(height: 26),
        const Text('Modüller',
            style: TextStyle(
                color: _DarkP.text, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: moduller.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (_, i) {
            final m = moduller[i];
            return Material(
              color: _DarkP.card,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {},
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _DarkP.line),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: m.$3.withOpacity(0.12),
                            boxShadow: [
                              BoxShadow(
                                  color: m.$3.withOpacity(0.25), blurRadius: 16)
                            ],
                          ),
                          child: Icon(m.$1, color: m.$3, size: 22),
                        ),
                        const SizedBox(height: 8),
                        Text(m.$2,
                            style: const TextStyle(
                                color: _DarkP.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                ),
              ),
            )
                .animate(delay: (45 * i).ms)
                .fadeIn()
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
          },
        ),

        const SizedBox(height: 26),
        const Text('Bekleyen İşler',
            style: TextStyle(
                color: _DarkP.text, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _is('Demir Ticaret • Çek Bordrosu', 'Taslak — tamamlanmayı bekliyor',
            _DarkP.amber, Icons.edit_note_rounded),
        _is('3 kayıt kuyruğa alındı', 'İnternet gelince gönderilecek',
            _DarkP.cyan, Icons.cloud_upload_outlined),
        _is('Güneş Kırtasiye • Alış Faturası', 'Taslak', _DarkP.amber,
            Icons.edit_note_rounded),
      ],
    );
  }

  Widget _kpi(String t, String v, Color c, IconData i) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _DarkP.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _DarkP.line),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: c.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(i, color: c, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: const TextStyle(color: _DarkP.muted, fontSize: 12)),
            const SizedBox(height: 2),
            Text(v,
                style: const TextStyle(
                    color: _DarkP.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ]),
        ]),
      );

  Widget _is(String t, String s, Color c, IconData i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _DarkP.card,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: c, width: 3)),
        ),
        child: Row(children: [
          Icon(i, color: c, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t,
                  style: const TextStyle(
                      color: _DarkP.text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(s,
                  style: const TextStyle(color: _DarkP.muted, fontSize: 11.5)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: _DarkP.muted),
        ]),
      );
}

class _SparkPainter extends CustomPainter {
  final List<double> v;
  _SparkPainter(this.v);

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = v.reduce((a, b) => a > b ? a : b);
    final dx = size.width / (v.length - 1);
    final path = Path();
    for (var i = 0; i < v.length; i++) {
      final x = dx * i;
      final y = size.height - (v[i] / maxV) * size.height * 0.9;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withOpacity(0.30), Colors.white.withOpacity(0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.v != v;
}

// ══════════════════════════════════════════════════════════════════════════
//  C) AÇIK BENTO
// ══════════════════════════════════════════════════════════════════════════
class _BentoP {
  static const bg = Color(0xFFF4F1EC);
  static const ink = Color(0xFF1C1B1F);
  static const muted = Color(0xFF7A766F);
  static const lime = Color(0xFFD9F27B);
  static const sky = Color(0xFFBFDBFE);
  static const peach = Color(0xFFFFD7C2);
  static const lilac = Color(0xFFDDD6FE);
  static const mint = Color(0xFFBBF7D0);
  static const dark = Color(0xFF1C1B1F);
}

class _BentoStil extends StatelessWidget {
  const _BentoStil({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        const Text('Günaydın,',
            style: TextStyle(color: _BentoP.muted, fontSize: 15)),
        const Text('Bugün neye\nbakıyoruz?',
            style: TextStyle(
                color: _BentoP.ink,
                fontSize: 32,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8)),
        const SizedBox(height: 20),

        // Satır 1: büyük Finans + iki küçük
        SizedBox(
          height: 210,
          child: Row(children: [
            Expanded(
              flex: 5,
              child: _karo('Finans', 'Kasa • Banka\nÇek • Senet',
                  Icons.account_balance_wallet_rounded, _BentoP.dark,
                  yazi: Colors.white, buyuk: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(children: [
                Expanded(
                    child: _karo('Cari', '248 kayıt', Icons.groups_rounded,
                        _BentoP.lime)),
                const SizedBox(height: 12),
                Expanded(
                    child: _karo('Stok', '1.320 ürün',
                        Icons.inventory_2_rounded, _BentoP.sky)),
              ]),
            ),
          ]),
        ).animate().fadeIn().slideY(begin: 0.05, end: 0),
        const SizedBox(height: 12),

        // Satır 2: geniş Fatura
        SizedBox(
          height: 96,
          child: _karo('Fatura', 'Satış ve alış faturaları • bugün 7 yeni',
              Icons.receipt_long_rounded, _BentoP.peach,
              yatay: true),
        ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.05, end: 0),
        const SizedBox(height: 12),

        // Satır 3: üç eşit
        SizedBox(
          height: 130,
          child: Row(children: [
            Expanded(
                child:
                    _karo('Depo', '', Icons.warehouse_rounded, _BentoP.mint)),
            const SizedBox(width: 12),
            Expanded(
                child: _karo('İrsaliye', '', Icons.local_shipping_rounded,
                    _BentoP.lilac)),
            const SizedBox(width: 12),
            Expanded(
                child: _karo(
                    'Sipariş', '', Icons.shopping_bag_rounded, _BentoP.lime)),
          ]),
        ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.05, end: 0),
        const SizedBox(height: 12),

        // Satır 4: rapor + bekleyen sayacı
        SizedBox(
          height: 110,
          child: Row(children: [
            Expanded(
                flex: 5,
                child: _karo('Raporlar', 'Cari • Stok • Günlük özet',
                    Icons.insights_rounded, _BentoP.sky,
                    yatay: true)),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26)),
                child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('3',
                          style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: _BentoP.ink,
                              height: 1)),
                      SizedBox(height: 4),
                      Text('bekleyen\nkayıt',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: _BentoP.muted)),
                    ]),
              ),
            ),
          ]),
        ).animate(delay: 240.ms).fadeIn().slideY(begin: 0.05, end: 0),
      ],
    );
  }

  Widget _karo(String baslik, String alt, IconData ikon, Color renk,
      {Color yazi = _BentoP.ink, bool buyuk = false, bool yatay = false}) {
    final ikonKutu = Container(
      width: yatay ? 48 : 44,
      height: yatay ? 48 : 44,
      decoration: BoxDecoration(
        color: yazi == Colors.white
            ? Colors.white.withOpacity(0.14)
            : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(ikon, color: yazi, size: 24),
    );
    final metin = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(baslik,
            style: TextStyle(
                color: yazi,
                fontSize: buyuk ? 24 : 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3)),
        if (alt.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(alt,
              style: TextStyle(
                  color: yazi.withOpacity(0.7), fontSize: 12, height: 1.3)),
        ],
      ],
    );
    return Material(
      color: renk,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: yatay
              ? Row(children: [
                  ikonKutu,
                  const SizedBox(width: 14),
                  Expanded(child: metin),
                  Icon(Icons.arrow_outward_rounded,
                      color: yazi.withOpacity(0.6)),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    ikonKutu,
                    const Spacer(),
                    Icon(Icons.arrow_outward_rounded,
                        color: yazi.withOpacity(0.6), size: 20),
                  ]),
                  const Spacer(),
                  metin,
                ]),
        ),
      ),
    );
  }
}
