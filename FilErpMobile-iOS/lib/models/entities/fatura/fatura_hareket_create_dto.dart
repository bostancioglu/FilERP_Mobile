import 'base_update_dto.dart';

class FaturaHareketCreateDto extends BaseUpdateDto {
  String? faturaid;
  int? depoid;
  String? depoadresid;
  int? stokid;
  int? stokozelliksabitid;
  int? olcubrid;
  int? projeid;
  int? istisnaId;
  int? irsaliyehareketid;
  int? referansid;
  String? stokhareketid;

  double? olcubrcarpim;
  int? belgeturu;
  String? giriscikis;
  DateTime? tarih;
  DateTime? teslimtarihi;

  double? miktar;
  double? miktar2;
  double? dovizfiyat;
  double? fiyat;

  double? malfazlasiiskonto;

  double? iskontoorani1;
  double? iskontotutari1;
  double? iskontoorani2;
  double? iskontotutari2;
  double? iskontoorani3;
  double? iskontotutari3;
  double? iskontoorani4;
  double? iskontotutari4;
  double? iskontoorani5;
  double? iskontotutari5;
  double? iskontoorani6;
  double? iskontotutari6;

  double? tutar;
  double? tevkifatorani;
  double? kdvorani;

  double? bruttutar;
  double? iskontotutar;
  double? malfazlasitutar;
  double? aratoplam;
  double? aratoplamiskontolu;
  double? kdvtutar;
  double? tevkifatmatrahi;
  double? tevkifattutar;

  String? aciklama;
  int? sira;

  FaturaHareketCreateDto({super.id});

  Map<String, dynamic> toJson() => {
        //"id": id,
        "faturaid": faturaid,
        "depoid": depoid,
        "depoadresid": depoadresid,
        "stokid": stokid,
        "stokozelliksabitid": stokozelliksabitid,
        "olcubrid": olcubrid,
        "projeid": projeid,
        "istisnaId": istisnaId,
        "irsaliyehareketid": irsaliyehareketid,
        "referansid": referansid,
        "stokhareketid": stokhareketid,
        "olcubrcarpim": olcubrcarpim,
        "belgeturu": belgeturu,
        "giriscikis": giriscikis,
        "tarih": tarih?.toIso8601String(),
        "teslimtarihi": teslimtarihi?.toIso8601String(),
        "miktar": miktar,
        "miktar2": miktar2,
        "dovizfiyat": dovizfiyat,
        "fiyat": fiyat,
        "malfazlasiiskonto": malfazlasiiskonto,
        "iskontoorani1": iskontoorani1,
        "iskontotutari1": iskontotutari1,
        "iskontoorani2": iskontoorani2,
        "iskontotutari2": iskontotutari2,
        "iskontoorani3": iskontoorani3,
        "iskontotutari3": iskontotutari3,
        "iskontoorani4": iskontoorani4,
        "iskontotutari4": iskontotutari4,
        "iskontoorani5": iskontoorani5,
        "iskontotutari5": iskontotutari5,
        "iskontoorani6": iskontoorani6,
        "iskontotutari6": iskontotutari6,
        "tutar": tutar,
        "tevkifatorani": tevkifatorani,
        "kdvorani": kdvorani,
        "bruttutar": bruttutar,
        "iskontotutar": iskontotutar,
        "malfazlasitutar": malfazlasitutar,
        "aratoplam": aratoplam,
        "aratoplamiskontolu": aratoplamiskontolu,
        "kdvtutar": kdvtutar,
        "tevkifatmatrahi": tevkifatmatrahi,
        "tevkifattutar": tevkifattutar,
        "aciklama": aciklama,
        "sira": sira,
      };
}
