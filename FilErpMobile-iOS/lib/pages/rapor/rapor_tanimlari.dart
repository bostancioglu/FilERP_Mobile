import 'package:FilERP/widgets/permission_page.dart';
import 'package:flutter/material.dart';
import '../../services/auth/authorization_session.dart';

import '../../helpers/belge_turu_couples.dart';
import '../../models/entities/cari/cari_dto_lite.dart';
import '../../models/entities/depo/depo_dto.dart';
import '../../models/entities/helper/doviz_dto.dart';
import '../../models/entities/stok/stok_list_dto.dart';
import '../../services/rapor/rapor_api.dart';
import 'cari/carihareket_raporu.dart';
import 'ortak/rapor_modelleri.dart';
import 'ortak/rapor_sayfasi.dart';
import 'stok/stokhareket_raporu.dart';

const _borcRenk = Color(0xFFD32F2F);
const _alacakRenk = Color(0xFF2E7D32);
const _mavi = Color(0xFF1A237E);

bool _tl(DovizDto? d) {
  final b = (d?.Birim ?? '').trim().toUpperCase();
  return b == 'TL' || b == 'TRY' || b == '₺';
}

/// Seçili para birimi TL değilse (dövizliyse) true.
bool _dovizli(RaporFiltre f) => f.doviz != null && !_tl(f.doviz);

void _git(BuildContext context, Widget sayfa) =>
    Navigator.push(context, PermissionMaterialPageRoute(builder: (_) => sayfa));

// ═══════════════════════════════════════════════════════════════════════════
// 2 • Cari Borç / Alacak
// ═══════════════════════════════════════════════════════════════════════════
// Tarih aralığı verilirse VW_Carihareket/Filter sonucu cariye göre toplanır (dönem borç/alacak).
// Tarih verilmezse güncel bakiye hazır view'lardan alınır (çok daha hızlı):
//   TL → VW_Cariborcalacaktry, döviz → VW_Cariborcalacakdoviz.
Future<RaporSonuc> _cariBorcAlacak(RaporFiltre f) async {
  const kolonlar = [
    RaporKolon('Cari Kod', baslikKolonu: true),
    RaporKolon('Cari İsim', baslikKolonu: true),
    RaporKolon('Borç', tip: RaporKolonTipi.tutar, toplamla: true),
    RaporKolon('Alacak', tip: RaporKolonTipi.tutar, toplamla: true),
    RaporKolon('Bakiye', tip: RaporKolonTipi.bakiye, toplamla: true),
    RaporKolon('Para Birimi'),
  ];

  final dovizli = _dovizli(f);
  final para = f.doviz == null ? 'TL' : (f.doviz!.Birim ?? '');
  final tarihli = f.tarih1 != null || f.tarih2 != null;

  // (cariId, kod, isim, borç, alacak)
  final satirlar =
      <({int? id, String kod, String isim, double borc, double alacak})>[];

  if (!tarihli) {
    final kayitlar = dovizli
        ? await RaporApi.post('VW_Cariborcalacakdoviz/Query',
            RaporApi.filtre(cariid: f.cari?.Id, dovizid: f.doviz!.Id))
        : await RaporApi.post(
            'VW_Cariborcalacaktry/Query', RaporApi.filtre(cariid: f.cari?.Id));
    for (final r in kayitlar) {
      satirlar.add((
        id: r.i('cariid'),
        kod: r.s('carikod'),
        isim: r.s('cariisim'),
        borc: dovizli ? r.d('borcdoviz') : r.d('borc'),
        alacak: dovizli ? r.d('alacakdoviz') : r.d('alacak'),
      ));
    }
  } else {
    final kayitlar = await RaporApi.post(
      'VW_Carihareket/Filter',
      RaporApi.filtre(
          tarih1: f.tarih1,
          tarih2: f.tarih2,
          cariid: f.cari?.Id,
          dovizid: f.doviz?.Id),
    );
    final grup = <String,
        ({int? id, String kod, String isim, double borc, double alacak})>{};
    for (final r in kayitlar) {
      final anahtar = '${r.i('cariid') ?? r.s('carikod')}';
      final onceki = grup[anahtar];
      final borc = dovizli ? r.d('dovizborctutar') : r.d('borctutar');
      final alacak = dovizli ? r.d('dovizalacaktutar') : r.d('alacaktutar');
      grup[anahtar] = (
        id: r.i('cariid'),
        kod: onceki?.kod ?? r.s('carikod'),
        isim: onceki?.isim ?? r.s('cariisim'),
        borc: (onceki?.borc ?? 0) + borc,
        alacak: (onceki?.alacak ?? 0) + alacak,
      );
    }
    satirlar.addAll(grup.values);
  }

  var liste = satirlar;
  if (f.anahtar)
    liste = liste.where((s) => (s.borc - s.alacak).abs() >= 0.005).toList();
  liste.sort((a, b) => a.kod.compareTo(b.kod));

  return RaporSonuc(kolonlar, [
    for (final s in liste)
      RaporSatir(
        [s.kod, s.isim, s.borc, s.alacak, s.borc - s.alacak, para],
        detay: s.id == null
            ? null
            : (ctx) => _git(
                  ctx,
                  CariHareketRaporu(
                    baslangicCari:
                        CariDtoLite(Id: s.id, Kod: s.kod, Ad: s.isim),
                    baslangicTarih1: f.tarih1 ?? DateTime(2000, 1, 1),
                    baslangicTarih2: f.tarih2 ?? DateTime.now(),
                    baslangicDoviz: f.doviz,
                  ),
                ),
      ),
  ]);
}

final cariBorcAlacakTanim = RaporTanim(
  no: '2',
  baslik: 'Cari Borç / Alacak',
  aciklama: 'Carilerin borç, alacak ve bakiyeleri',
  ikon: Icons.balance_rounded,
  renk: const Color(0xFF6366F1),
  filtreler: const [
    RaporFiltreTuru.tarih,
    RaporFiltreTuru.cari,
    RaporFiltreTuru.doviz,
    RaporFiltreTuru.anahtar
  ],
  anahtarEtiketi: 'Bakiyesi sıfır olanları gizle',
  anahtarVarsayilan: true,
  getir:
      _cariBorcAlacak, // tarih varsayılanı bugün; güncel bakiye için filtreden tarihler temizlenir
);

// ═══════════════════════════════════════════════════════════════════════════
// 12 • Stok Bakiye (stok + depo bazında)
// ═══════════════════════════════════════════════════════════════════════════
Future<RaporSonuc> _stokBakiye(RaporFiltre f) async {
  const kolonlar = [
    RaporKolon('Stok Kodu', baslikKolonu: true),
    RaporKolon('Stok Adı', baslikKolonu: true),
    RaporKolon('Depo'),
    RaporKolon('Bakiye', tip: RaporKolonTipi.miktar),
    RaporKolon('Ölçü Br'),
  ];
  final kayitlar = await RaporApi.post(
    'VW_Stokbakiyesubedepo/Query',
    RaporApi.filtre(stokid: f.stok?.Id, depoid: f.depo?.id),
  );
  var liste = kayitlar.toList();
  if (f.anahtar)
    liste = liste.where((r) => r.d('bakiye').abs() >= 0.00005).toList();
  liste.sort((a, b) {
    final c = a.s('kod').compareTo(b.s('kod'));
    return c != 0 ? c : a.s('depoadi').compareTo(b.s('depoadi'));
  });
  return RaporSonuc(kolonlar, [
    for (final r in liste)
      RaporSatir(
        [r.s('kod'), r.s('ad'), r.s('depoadi'), r.d('bakiye'), r.s('olcubr')],
        detay: r.i('stokid') == null
            ? null
            : (ctx) => _git(
                  ctx,
                  StokHareketRaporu(
                    baslangicStok: StokListDto(
                        Id: r.i('stokid'), Kod: r.s('kod'), Ad: r.s('ad')),
                    baslangicDepo: r.i('depoid') == null
                        ? null
                        : (DepoDto()
                          ..id = r.i('depoid')
                          ..kod = r.s('depokodu')
                          ..ad = r.s('depoadi')),
                  ),
                ),
      ),
  ]);
}

final stokBakiyeTanim = RaporTanim(
  no: '12',
  baslik: 'Stok Bakiye',
  aciklama: 'Stok ve depo bazında güncel bakiye',
  ikon: Icons.inventory_2_rounded,
  renk: const Color(0xFFF59E0B),
  filtreler: const [
    RaporFiltreTuru.stok,
    RaporFiltreTuru.depo,
    RaporFiltreTuru.anahtar
  ],
  anahtarEtiketi: 'Bakiyesi sıfır olanları gizle',
  anahtarVarsayilan: true,
  tarihVarsayilan: false,
  getir: _stokBakiye,
);

// ═══════════════════════════════════════════════════════════════════════════
// 21 • Fatura İcmali
// ═══════════════════════════════════════════════════════════════════════════
// VW_Faturairsaliyeicmali hem fatura hem irsaliye satırı döndürür; Belgeturu ile ayrılır:
// 1 satış faturası, 2 alış faturası, 3 satış irsaliyesi, 4 alış irsaliyesi → burada yalnızca 1 ve 2.
Future<RaporSonuc> _faturaIcmali(RaporFiltre f) async {
  const kolonlar = [
    RaporKolon('Belge No', baslikKolonu: true),
    RaporKolon('Cari İsim', baslikKolonu: true),
    RaporKolon('Tür'),
    RaporKolon('Tarih', tip: RaporKolonTipi.tarih),
    RaporKolon('Cari Kod'),
    RaporKolon('Genel Toplam', tip: RaporKolonTipi.tutar, toplamla: true),
    RaporKolon('Para Birimi'),
  ];
  final izinli = f.segment == 1
      ? {BelgeTuruCouples.satisFaturasi}
      : f.segment == 2
          ? {BelgeTuruCouples.alisFaturasi}
          : {BelgeTuruCouples.satisFaturasi, BelgeTuruCouples.alisFaturasi};

  final kayitlar = await RaporApi.post(
    'VW_Faturairsaliyeicmali/Query',
    RaporApi.filtre(
        tarih1: f.tarih1,
        tarih2: f.tarih2,
        cariid: f.cari?.Id,
        belgeno: f.belgeno),
  );
  final liste = kayitlar
      .where((r) => izinli.contains(r.i('belgeturu')))
      .toList()
    ..sort((a, b) => (b.t('tarih') ?? DateTime(2000))
        .compareTo(a.t('tarih') ?? DateTime(2000)));

  var satis = 0.0, alis = 0.0;
  for (final r in liste) {
    if (r.i('belgeturu') == BelgeTuruCouples.satisFaturasi) {
      satis += r.d('geneltoplam');
    } else {
      alis += r.d('geneltoplam');
    }
  }

  return RaporSonuc(
    kolonlar,
    [
      for (final r in liste)
        RaporSatir(
          [
            r.s('belgeno'),
            r.s('cariisim'),
            r.i('belgeturu') == BelgeTuruCouples.satisFaturasi
                ? 'Satış Faturası'
                : 'Alış Faturası',
            r.t('tarih'),
            r.s('carikod'),
            r.d('geneltoplam'),
            r.s('parabirimi', 'TL'),
          ],
          detay: (ctx) => _git(
            ctx,
            RaporSayfasi(
              tanim: faturaDetayTanim,
              baslangicFiltre: faturaDetayTanim.varsayilanFiltre()
                ..tarih1 = null
                ..tarih2 = null
                ..belgeno = r.s('belgeno')
                ..segment =
                    r.i('belgeturu') == BelgeTuruCouples.satisFaturasi ? 0 : 1,
            ),
          ),
        ),
    ],
    ozetler: f.segment == 0
        ? [
            RaporOzet('Satış Toplamı', rapTutar(satis), _alacakRenk),
            RaporOzet('Alış Toplamı', rapTutar(alis), _borcRenk)
          ]
        : const [],
  );
}

final faturaIcmaliTanim = RaporTanim(
  no: '21',
  baslik: 'Fatura İcmali',
  aciklama: 'Satış ve alış faturaları belge bazında',
  ikon: Icons.receipt_long_rounded,
  renk: const Color(0xFF2F7BFF),
  filtreler: const [
    RaporFiltreTuru.tarih,
    RaporFiltreTuru.cari,
    RaporFiltreTuru.segment
  ],
  segmentEtiketi: 'Fatura türü',
  segmentler: const ['Tümü', 'Satış', 'Alış'],
  getir: _faturaIcmali,
);

// ═══════════════════════════════════════════════════════════════════════════
// 22 • Fatura Detay (kalem bazında)
// ═══════════════════════════════════════════════════════════════════════════
Future<RaporSonuc> _faturaDetay(RaporFiltre f) async {
  const kolonlar = [
    RaporKolon('Fatura No', baslikKolonu: true),
    RaporKolon('Stok Adı', baslikKolonu: true),
    RaporKolon('Tür'),
    RaporKolon('Tarih', tip: RaporKolonTipi.tarih),
    RaporKolon('Stok Kodu'),
    RaporKolon('Cari'),
    RaporKolon('Miktar', tip: RaporKolonTipi.miktar),
    RaporKolon('Birim'),
    RaporKolon('Net Tutar', tip: RaporKolonTipi.tutar, toplamla: true),
    RaporKolon('Tutar', tip: RaporKolonTipi.tutar, toplamla: true),
  ];
  final filtre = RaporApi.filtre(
    tarih1: f.tarih1,
    tarih2: f.tarih2,
    cariid: f.cari?.Id,
    stokid: f.stok?.Id,
    belgeno: f.belgeno,
  );
  final liste = <(String, RaporKayit)>[];
  if (f.segment == 0 || f.segment == 2) {
    for (final r
        in await RaporApi.post('VW_Faturahareket/Satis/Query', filtre)) {
      liste.add(('Satış', r));
    }
  }
  if (f.segment == 1 || f.segment == 2) {
    for (final r
        in await RaporApi.post('VW_Faturahareket/Alis/Query', filtre)) {
      liste.add(('Alış', r));
    }
  }
  liste.sort((a, b) {
    final c = (b.$2.t('tarih') ?? DateTime(2000))
        .compareTo(a.$2.t('tarih') ?? DateTime(2000));
    if (c != 0) return c;
    final n = a.$2.s('faturano').compareTo(b.$2.s('faturano'));
    return n != 0 ? n : a.$2.s('kod').compareTo(b.$2.s('kod'));
  });
  return RaporSonuc(kolonlar, [
    for (final e in liste)
      RaporSatir([
        e.$2.s('faturano'),
        e.$2.s('ad'),
        e.$1,
        e.$2.t('tarih'),
        e.$2.s('kod'),
        e.$2.s('cariadi'),
        e.$2.d('faturamiktar'),
        e.$2.s('olcubr'),
        e.$2.d('faturanettutar'),
        e.$2.d('faturatutar'),
      ]),
  ]);
}

final faturaDetayTanim = RaporTanim(
  no: '22',
  baslik: 'Fatura Detay',
  aciklama: 'Fatura kalemleri: stok, miktar, tutar',
  ikon: Icons.list_alt_rounded,
  renk: const Color(0xFF0EA5A4),
  filtreler: const [
    RaporFiltreTuru.tarih,
    RaporFiltreTuru.cari,
    RaporFiltreTuru.stok,
    RaporFiltreTuru.segment
  ],
  segmentEtiketi: 'Fatura türü',
  segmentler: const ['Satış', 'Alış', 'Tümü'],
  getir: _faturaDetay,
);

// ═══════════════════════════════════════════════════════════════════════════
// 31 • Çek / Senet Listesi
// ═══════════════════════════════════════════════════════════════════════════
Future<RaporSonuc> _cekSenet(RaporFiltre f) async {
  const kolonlar = [
    RaporKolon('Çek / Senet No', baslikKolonu: true),
    RaporKolon('Cari İsmi', baslikKolonu: true),
    RaporKolon('Tür'),
    RaporKolon('Tarih', tip: RaporKolonTipi.tarih),
    RaporKolon('Cari Kod'),
    RaporKolon('Vade Tarihi', tip: RaporKolonTipi.tarih),
    RaporKolon('Tutar', tip: RaporKolonTipi.tutar, toplamla: true),
    RaporKolon('Durum'),
  ];
  final filtre =
      RaporApi.filtre(tarih1: f.tarih1, tarih2: f.tarih2, cariid: f.cari?.Id);

  // (tür adı, yön adı, endpoint, numara alanı)
  final kaynaklar = <(String, String, String, String)>[];
  final cek = f.segment == 0 || f.segment == 1;
  final senet = f.segment == 0 || f.segment == 2;
  final alinan = f.segment2 == 0 || f.segment2 == 2;
  final verilen = f.segment2 == 1 || f.segment2 == 2;
  if (cek && alinan)
    kaynaklar.add(('Çek', 'Müşteri', 'VW_Finanscekalinan/Query', 'cekno'));
  if (cek && verilen)
    kaynaklar.add(('Çek', 'Borç', 'VW_Finanscekverilen/Query', 'cekno'));
  if (senet && alinan)
    kaynaklar.add(('Senet', 'Müşteri', 'VW_Finanssenetalinan/Query', 'cekno'));
  if (senet && verilen)
    kaynaklar.add(('Senet', 'Borç', 'VW_Finanssenetverilen/Query', 'senetno'));

  final liste = <(String, RaporKayit)>[];
  for (final k in kaynaklar) {
    final module = switch (k.$3) {
      'VW_Finanscekalinan/Query' => 5032,
      'VW_Finanscekverilen/Query' => 5050,
      'VW_Finanssenetalinan/Query' => 5051,
      _ => 5058,
    };
    if (!AuthorizationSession.instance.can(module, Access.read)) continue;
    for (final r in await RaporApi.post(k.$3, filtre)) {
      liste.add(('${k.$1} • ${k.$2}', r));
    }
  }
  liste.sort((a, b) => (b.$2.t('tarih') ?? DateTime(2000))
      .compareTo(a.$2.t('tarih') ?? DateTime(2000)));

  String no(String tur, RaporKayit r) {
    final n = r.s('cekno').isNotEmpty ? r.s('cekno') : r.s('senetno');
    return n.isNotEmpty
        ? n
        : (r.s('cekserino').isNotEmpty ? r.s('cekserino') : r.s('senetserino'));
  }

  return RaporSonuc(kolonlar, [
    for (final e in liste)
      RaporSatir([
        no(e.$1, e.$2),
        e.$2.s('cariad').isNotEmpty ? e.$2.s('cariad') : e.$2.s('cariisim'),
        e.$1,
        e.$2.t('tarih'),
        e.$2.s('carikod'),
        e.$2.t('vadetarihi'),
        e.$2.d('tutar'),
        e.$2.s('suandaevrakdurum').isNotEmpty
            ? e.$2.s('suandaevrakdurum')
            : e.$2.s('durum'),
      ]),
  ]);
}

final cekSenetTanim = RaporTanim(
  no: '31',
  baslik: 'Çek / Senet',
  aciklama: 'Çek ve senet listesi (müşteri / borç)',
  ikon: Icons.description_rounded,
  renk: const Color(0xFF8B5CF6),
  filtreler: const [
    RaporFiltreTuru.tarih,
    RaporFiltreTuru.cari,
    RaporFiltreTuru.segment,
    RaporFiltreTuru.segment2
  ],
  segmentEtiketi: 'Tür',
  segmentler: const ['Tümü', 'Çek', 'Senet'],
  segment2Etiketi: 'Yön',
  segmentler2: const ['Müşteri (Alınan)', 'Borç (Verilen)', 'Tümü'],
  getir: _cekSenet,
);

// ═══════════════════════════════════════════════════════════════════════════
// 42 • Kasa Hareket
// ═══════════════════════════════════════════════════════════════════════════
// Sunucu tarafında kasa süzmesi yok: tarih / para birimi sunucuda, kasa seçimi (Kasaid) burada süzülür.
Future<RaporSonuc> _kasaHareket(RaporFiltre f) async {
  const kolonlar = [
    RaporKolon('Tarih', tip: RaporKolonTipi.tarih, baslikKolonu: true),
    RaporKolon('Cari İsim', baslikKolonu: true),
    RaporKolon('Kasa'),
    RaporKolon('Cari Kod'),
    RaporKolon('Yön'),
    RaporKolon('Tutar', tip: RaporKolonTipi.tutar),
    RaporKolon('Para Birimi'),
    RaporKolon('Belge No'),
    RaporKolon('Açıklama'),
  ];
  var kayitlar = await RaporApi.post(
    'VW_Finanskasahareket/Query',
    RaporApi.filtre(tarih1: f.tarih1, tarih2: f.tarih2, dovizid: f.doviz?.Id),
  );
  if (f.kasa != null)
    kayitlar = kayitlar.where((r) => r.i('kasaid') == f.kasa!.Id).toList();
  kayitlar.sort((a, b) => (a.t('tarih') ?? DateTime(2000))
      .compareTo(b.t('tarih') ?? DateTime(2000)));

  var giris = 0.0, cikis = 0.0;
  final satirlar = <RaporSatir>[];
  for (final r in kayitlar) {
    final girisMi = r.i('giriscikis') == 1 ||
        (r.i('giriscikis') == null && r.d('borctutar') > 0);
    final tutar = r.d('tutar') != 0
        ? r.d('tutar')
        : (girisMi ? r.d('borctutar') : r.d('alacaktutar'));
    if (girisMi) {
      giris += tutar;
    } else {
      cikis += tutar;
    }
    final karsi = r.s('islemcariad').isNotEmpty
        ? r.s('islemcariad')
        : (r.s('islembankaad').isNotEmpty ? r.s('islembankaad') : '');
    satirlar.add(RaporSatir([
      r.t('tarih'),
      karsi,
      '${r.s('kasakod')}${r.s('kasaisim').isNotEmpty ? ' - ${r.s('kasaisim')}' : ''}',
      r.s('islemcarikod'),
      girisMi ? 'Giriş' : 'Çıkış',
      tutar,
      r.s('dovizbirim'),
      r.s('belgeno'),
      r.s('hareketaciklama'),
    ]));
  }
  return RaporSonuc(kolonlar, satirlar, ozetler: [
    RaporOzet('Toplam Giriş', rapTutar(giris), _alacakRenk),
    RaporOzet('Toplam Çıkış', rapTutar(cikis), _borcRenk),
    RaporOzet('Net', rapTutar(giris - cikis), _mavi),
  ]);
}

final kasaHareketTanim = RaporTanim(
  no: '42',
  baslik: 'Kasa Hareket',
  aciklama: 'Kasa bazında giriş / çıkış hareketleri',
  ikon: Icons.point_of_sale_rounded,
  renk: const Color(0xFF10B981),
  filtreler: const [
    RaporFiltreTuru.tarih,
    RaporFiltreTuru.kasa,
    RaporFiltreTuru.doviz
  ],
  getir: _kasaHareket,
);

// ═══════════════════════════════════════════════════════════════════════════
// 51 • Bankalar Genel Durum
// ═══════════════════════════════════════════════════════════════════════════
Future<RaporSonuc> _bankaGenelDurum(RaporFiltre f) async {
  const kolonlar = [
    RaporKolon('Banka Kodu', baslikKolonu: true),
    RaporKolon('Banka Adı', baslikKolonu: true),
    RaporKolon('Hesap No'),
    RaporKolon('Bakiye', tip: RaporKolonTipi.tutar),
    RaporKolon('Para Birimi'),
    RaporKolon('TL Karşılığı', tip: RaporKolonTipi.tutar, toplamla: true),
  ];
  var kayitlar = await RaporApi.post(
      'VW_Finansbankatoplam/Query', RaporApi.filtre(dovizid: f.doviz?.Id));
  if (f.banka != null)
    kayitlar =
        kayitlar.where((r) => r.i('bankahesapid') == f.banka!.Id).toList();
  kayitlar.sort((a, b) => a.s('bankakod').compareTo(b.s('bankakod')));
  return RaporSonuc(kolonlar, [
    for (final r in kayitlar)
      RaporSatir([
        r.s('bankakod'),
        r.s('bankaisim'),
        r.s('hesapno'),
        (r.s('dovizbirim').isEmpty || _tl(DovizDto(Birim: r.s('dovizbirim'))))
            ? r.d('bakiyetutar')
            : r.d('dovizbakiyetutar'),
        r.s('dovizbirim', 'TL'),
        r.d('bakiyetutar'),
      ]),
  ]);
}

final bankaGenelDurumTanim = RaporTanim(
  no: '51',
  baslik: 'Bankalar Genel Durum',
  aciklama: 'Banka hesaplarının güncel bakiyeleri',
  ikon: Icons.account_balance_rounded,
  renk: const Color(0xFF0EA5E9),
  filtreler: const [RaporFiltreTuru.banka, RaporFiltreTuru.doviz],
  tarihVarsayilan: false,
  getir: _bankaGenelDurum,
);

// ═══════════════════════════════════════════════════════════════════════════
// 52 • Banka Hareket
// ═══════════════════════════════════════════════════════════════════════════
Future<RaporSonuc> _bankaHareket(RaporFiltre f) async {
  const kolonlar = [
    RaporKolon('Tarih', tip: RaporKolonTipi.tarih, baslikKolonu: true),
    RaporKolon('Cari İsim', baslikKolonu: true),
    RaporKolon('Banka'),
    RaporKolon('Cari Kod'),
    RaporKolon('Yön'),
    RaporKolon('Tutar', tip: RaporKolonTipi.tutar),
    RaporKolon('Para Birimi'),
    RaporKolon('Belge No'),
    RaporKolon('Açıklama'),
  ];
  var kayitlar = await RaporApi.post(
    'VW_Finansbankahareket/Query',
    RaporApi.filtre(tarih1: f.tarih1, tarih2: f.tarih2, dovizid: f.doviz?.Id),
  );
  if (f.banka != null)
    kayitlar =
        kayitlar.where((r) => r.i('bankahesapid') == f.banka!.Id).toList();
  kayitlar.sort((a, b) => (a.t('tarih') ?? DateTime(2000))
      .compareTo(b.t('tarih') ?? DateTime(2000)));

  var giris = 0.0, cikis = 0.0;
  final satirlar = <RaporSatir>[];
  for (final r in kayitlar) {
    final girisMi = r.i('giriscikis') == 1 ||
        (r.i('giriscikis') == null && r.d('borctutar') > 0);
    final tutar = r.d('tutar') != 0
        ? r.d('tutar')
        : (girisMi ? r.d('borctutar') : r.d('alacaktutar'));
    if (girisMi) {
      giris += tutar;
    } else {
      cikis += tutar;
    }
    final karsi = r.s('islemcariad').isNotEmpty
        ? r.s('islemcariad')
        : (r.s('islembankaad').isNotEmpty
            ? r.s('islembankaad')
            : r.s('kasaad'));
    satirlar.add(RaporSatir([
      r.t('tarih'),
      karsi,
      '${r.s('bankakod')}${r.s('bankaisim').isNotEmpty ? ' - ${r.s('bankaisim')}' : ''}',
      r.s('islemcarikod'),
      girisMi ? 'Giriş' : 'Çıkış',
      tutar,
      r.s('dovizbirim'),
      r.s('belgeno'),
      r.s('hareketaciklama').isNotEmpty
          ? r.s('hareketaciklama')
          : r.s('aciklama'),
    ]));
  }
  return RaporSonuc(kolonlar, satirlar, ozetler: [
    RaporOzet('Toplam Giriş', rapTutar(giris), _alacakRenk),
    RaporOzet('Toplam Çıkış', rapTutar(cikis), _borcRenk),
    RaporOzet('Net', rapTutar(giris - cikis), _mavi),
  ]);
}

final bankaHareketTanim = RaporTanim(
  no: '52',
  baslik: 'Banka Hareket',
  aciklama: 'Banka hesabı bazında hareketler',
  ikon: Icons.swap_vert_rounded,
  renk: const Color(0xFF14B8A6),
  filtreler: const [
    RaporFiltreTuru.tarih,
    RaporFiltreTuru.banka,
    RaporFiltreTuru.doviz
  ],
  getir: _bankaHareket,
);
