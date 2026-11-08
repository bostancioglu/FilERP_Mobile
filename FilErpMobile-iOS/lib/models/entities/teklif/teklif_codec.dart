import 'teklif_dto.dart';
import 'teklifhareket_dto.dart';
import '../siparis/siparishareket_dto.dart';

Map<String, dynamic> teklifJson(TeklifDto d) => {
      'Id': d.id,
      'Firmaid': d.firmaid,
      'Sirketid': d.sirketid,
      'Subeid': d.subeid,
      'Cariid': d.cariid,
      'Cariadresid': d.cariadresid,
      'Plasiyerid': d.plasiyerid,
      'Dovizid': d.dovizid,
      'Projeid': d.projeid,
      'Referansid': d.referansid,
      'Belgeserino': d.belgeserino,
      'Belgeyil': d.belgeyil,
      'Belgeseri': d.belgeseri,
      'Belgeno': d.belgeno,
      'Referansbelgeno': d.referansbelgeno,
      'Tarih': d.tarih?.toIso8601String(),
      'Fiilitarih': d.fiilitarih?.toIso8601String(),
      'Teslimtarihi': d.teslimtarihi?.toIso8601String(),
      'Tahsilattarihi': d.tahsilattarihi?.toIso8601String(),
      'Vadetarihi': d.vadetarihi?.toIso8601String(),
      'Gecerliliktarihi': d.gecerliliktarihi?.toIso8601String(),
      'Vadegunu': d.vadegunu,
      'Belgetipi': d.belgetipi,
      'Ithalatihracattipi': d.ithalatihracattipi,
      'Odemesekli': d.odemesekli,
      'Kdvdahil': d.kdvdahil,
      'Doviztarih': d.doviztarih?.toIso8601String(),
      'Kur': d.kur,
      'Belgeturu': d.belgeturu,
      'Geneliskontooran': d.geneliskontooran,
      'Geneliskontotutar': d.geneliskontotutar,
      'Bruttutar': d.bruttutar,
      'Iskontotutar': d.iskontotutar,
      'Malfazlasitutar': d.malfazlasitutar,
      'Aratoplam': d.aratoplam,
      'Aratoplam2': d.aratoplam2,
      'Kdvaratoplam': d.kdvaratoplam,
      'Tevkifatmatrah': d.tevkifatmatrah,
      'Tevkifattutar': d.tevkifattutar,
      'Kdvtoplam': d.kdvtoplam,
      'Geneltoplam': d.geneltoplam,
      'Doviztoplam': d.doviztoplam,
      'Aciklama': d.aciklama,
      ...{
        for (var i = 0; i < d.extraNotes.length; i++)
          'Aciklama${i + 1}': d.extraNotes[i]
      },
      'Grupno': d.grupno,
      'Dovizgeneliskontotutar': d.dovizgeneliskontotutar,
      'Onayagonderildi': d.onayagonderildi,
      'Onaydurum': d.onaydurum,
      'Oncelik': d.oncelik,
      'Teslimattipi': d.teslimattipi,
      'Onaylanabilir': d.onaylanabilir,
      'Onaykaldirilabilir': d.onaykaldirilabilir,
      'Localerpentegrasyondurum': d.localerpentegrasyondurum,
      'Localerpdenkilitli': d.localerpdenkilitli,
      'Belgedurum': d.belgedurum,
    };

Map<String, dynamic> teklifKalemJson(TeklifhareketDto d) => {
      'Id': d.id,
      'Firmaid': d.firmaid,
      'Teklifid': d.teklifid,
      'Depoid': d.depoid,
      'Stokid': d.stokid,
      'Stokozelliksabitid': d.stokozelliksabitid,
      'Olcubrid': d.olcubrid,
      'Olcubr2id': d.olcubr2id,
      'Stokadiaciklama': d.stokadiaciklama,
      'Projeid': d.projeid,
      'IstisnaId': d.istisnaId,
      'Talephareketid': d.talephareketid,
      'Referansid': d.referansid,
      'Olcubrcarpim': d.olcubrcarpim,
      'Belgeturu': d.belgeturu,
      'Giriscikis': d.giriscikis,
      'Tarih': d.tarih?.toIso8601String(),
      'Teslimtarihi': d.teslimtarihi?.toIso8601String(),
      'Miktar': d.miktar,
      'Miktar2': d.miktar2,
      'Dovizfiyat': d.dovizfiyat,
      'Fiyat': d.fiyat,
      'Malfazlasiiskonto': d.malfazlasiiskonto,
      'Iskontoorani1': d.iskontoorani1,
      'Iskontotutari1': d.iskontotutari1,
      'Doviziskontotutari1': d.doviziskontotutari1,
      'Iskontoorani2': d.iskontoorani2,
      'Iskontotutari2': d.iskontotutari2,
      'Doviziskontotutari2': d.doviziskontotutari2,
      'Iskontoorani3': d.iskontoorani3,
      'Iskontotutari3': d.iskontotutari3,
      'Doviziskontotutari3': d.doviziskontotutari3,
      'Iskontoorani4': d.iskontoorani4,
      'Iskontotutari4': d.iskontotutari4,
      'Doviziskontotutari4': d.doviziskontotutari4,
      'Iskontoorani5': d.iskontoorani5,
      'Iskontotutari5': d.iskontotutari5,
      'Doviziskontotutari5': d.doviziskontotutari5,
      'Iskontoorani6': d.iskontoorani6,
      'Iskontotutari6': d.iskontotutari6,
      'Doviziskontotutari6': d.doviziskontotutari6,
      'Tutar': d.tutar,
      'Kdvorani': d.kdvorani,
      'Tevkifatorani': d.tevkifatorani,
      'Bruttutar': d.bruttutar,
      'Iskontotutar': d.iskontotutar,
      'Malfazlasitutar': d.malfazlasitutar,
      'Aratoplam': d.aratoplam,
      'Aratoplamiskontolu': d.aratoplamiskontolu,
      'Kdvtutar': d.kdvtutar,
      'Tevkifatmatrahi': d.tevkifatmatrahi,
      'Tevkifattutar': d.tevkifattutar,
      'Aciklama': d.aciklama,
      'Onaydurum': d.onaydurum,
      'Acikkapali': d.acikkapali,
      'Kapanisnedeni': d.kapanisnedeni,
    };

SiparishareketDto teklifKalemToEditor(TeklifhareketDto k) => SiparishareketDto()
  ..id = k.id?.toString()
  ..firmaid = k.firmaid
  ..depoid = k.depoid
  ..stokid = k.stokid
  ..stokozelliksabitid = k.stokozelliksabitid
  ..olcubrid = k.olcubrid
  ..olcubr2id = k.olcubr2id
  ..olcubr2 = k.olcubr2
  ..stokadiaciklama = k.stokadiaciklama
  ..istisna = k.istisna
  ..projeid = k.projeid
  ..istisnaId = k.istisnaId
  ..referansid = k.referansid
  ..olcubrcarpim = k.olcubrcarpim
  ..belgeturu = k.belgeturu
  ..giriscikis = k.giriscikis
  ..tarih = k.tarih
  ..teslimtarihi = k.teslimtarihi
  ..miktar = k.miktar
  ..miktar2 = k.miktar2
  ..dovizfiyat = k.dovizfiyat
  ..fiyat = k.fiyat
  ..malfazlasiiskonto = k.malfazlasiiskonto
  ..iskontoorani1 = k.iskontoorani1
  ..iskontotutari1 = k.iskontotutari1
  ..doviziskontotutari1 = k.doviziskontotutari1
  ..iskontoorani2 = k.iskontoorani2
  ..iskontotutari2 = k.iskontotutari2
  ..doviziskontotutari2 = k.doviziskontotutari2
  ..iskontoorani3 = k.iskontoorani3
  ..iskontotutari3 = k.iskontotutari3
  ..doviziskontotutari3 = k.doviziskontotutari3
  ..iskontoorani4 = k.iskontoorani4
  ..iskontotutari4 = k.iskontotutari4
  ..doviziskontotutari4 = k.doviziskontotutari4
  ..iskontoorani5 = k.iskontoorani5
  ..iskontotutari5 = k.iskontotutari5
  ..doviziskontotutari5 = k.doviziskontotutari5
  ..iskontoorani6 = k.iskontoorani6
  ..iskontotutari6 = k.iskontotutari6
  ..doviziskontotutari6 = k.doviziskontotutari6
  ..tutar = k.tutar
  ..kdvorani = k.kdvorani
  ..tevkifatorani = k.tevkifatorani
  ..bruttutar = k.bruttutar
  ..iskontotutar = k.iskontotutar
  ..malfazlasitutar = k.malfazlasitutar
  ..aratoplam = k.aratoplam
  ..aratoplamiskontolu = k.aratoplamiskontolu
  ..kdvtutar = k.kdvtutar
  ..tevkifatmatrahi = k.tevkifatmatrahi
  ..tevkifattutar = k.tevkifattutar
  ..aciklama = k.aciklama
  ..onaydurum = k.onaydurum
  ..acikkapali = k.acikkapali
  ..kapanisnedeni = k.kapanisnedeni
  ..stok = k.stok
  ..depo = k.depo
  ..olcubr = k.olcubr
  ..proje = k.proje
  ..stokozelliksabit = k.stokozelliksabit;

TeklifhareketDto teklifKalemFromEditor(SiparishareketDto k,
        {TeklifhareketDto? original}) =>
    TeklifhareketDto()
      ..id = int.tryParse(k.id ?? '')
      ..firmaid = k.firmaid
      ..depoid = k.depoid
      ..stokid = k.stokid
      ..stokozelliksabitid = k.stokozelliksabitid
      ..olcubrid = k.olcubrid
      ..olcubr2id = k.olcubr2id
      ..olcubr2 = k.olcubr2
      ..stokadiaciklama = k.stokadiaciklama
      ..istisna = k.istisna
      ..projeid = k.projeid
      ..istisnaId = k.istisnaId
      ..referansid = k.referansid
      ..olcubrcarpim = k.olcubrcarpim
      ..belgeturu = k.belgeturu
      ..giriscikis = k.giriscikis
      ..tarih = k.tarih
      ..teslimtarihi = k.teslimtarihi
      ..miktar = k.miktar
      ..miktar2 = k.miktar2
      ..dovizfiyat = k.dovizfiyat
      ..fiyat = k.fiyat
      ..malfazlasiiskonto = k.malfazlasiiskonto
      ..iskontoorani1 = k.iskontoorani1
      ..iskontotutari1 = k.iskontotutari1
      ..doviziskontotutari1 = k.doviziskontotutari1
      ..iskontoorani2 = k.iskontoorani2
      ..iskontotutari2 = k.iskontotutari2
      ..doviziskontotutari2 = k.doviziskontotutari2
      ..iskontoorani3 = k.iskontoorani3
      ..iskontotutari3 = k.iskontotutari3
      ..doviziskontotutari3 = k.doviziskontotutari3
      ..iskontoorani4 = k.iskontoorani4
      ..iskontotutari4 = k.iskontotutari4
      ..doviziskontotutari4 = k.doviziskontotutari4
      ..iskontoorani5 = k.iskontoorani5
      ..iskontotutari5 = k.iskontotutari5
      ..doviziskontotutari5 = k.doviziskontotutari5
      ..iskontoorani6 = k.iskontoorani6
      ..iskontotutari6 = k.iskontotutari6
      ..doviziskontotutari6 = k.doviziskontotutari6
      ..tutar = k.tutar
      ..kdvorani = k.kdvorani
      ..tevkifatorani = k.tevkifatorani
      ..bruttutar = k.bruttutar
      ..iskontotutar = k.iskontotutar
      ..malfazlasitutar = k.malfazlasitutar
      ..aratoplam = k.aratoplam
      ..aratoplamiskontolu = k.aratoplamiskontolu
      ..kdvtutar = k.kdvtutar
      ..tevkifatmatrahi = k.tevkifatmatrahi
      ..tevkifattutar = k.tevkifattutar
      ..aciklama = k.aciklama
      ..onaydurum = k.onaydurum
      ..acikkapali = k.acikkapali
      ..kapanisnedeni = k.kapanisnedeni
      ..stok = k.stok
      ..depo = k.depo
      ..olcubr = k.olcubr
      ..proje = k.proje
      ..stokozelliksabit = k.stokozelliksabit
      ..tarih = original?.tarih ?? k.tarih
      ..teslimtarihi = original?.teslimtarihi ?? k.teslimtarihi
      ..belgeturu = original?.belgeturu ?? k.belgeturu
      ..giriscikis = original?.giriscikis ?? k.giriscikis
      ..talephareketid = original?.talephareketid
      ..referansid = original?.referansid ?? k.referansid
      ..istisnaId = k.istisnaId
      ..onaydurum = original?.onaydurum
      ..acikkapali = original?.acikkapali
      ..kapanisnedeni = original?.kapanisnedeni;
