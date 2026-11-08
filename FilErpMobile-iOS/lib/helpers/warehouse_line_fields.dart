import '../models/entities/stok/stok_dto.dart';
import '../models/entities/depo/dathareket_dto.dart';
import '../models/entities/depo/ambargchareket_dto.dart';

/// Web uses only the feature definitions linked to the selected stock.
int? warehouseFeatureId(StokDto stock, int? selected) {
  if (stock.Stokozelligesahip == false) return null;
  if (selected != null) return selected;
  return stock.Stokozellik.where((e) => e.stokozelliksabitid != null)
      .firstOrNull
      ?.stokozelliksabitid;
}

Map<String, dynamic> warehouseDraftJson(Map<String, dynamic> json) => {
      for (final e in json.entries)
        '${e.key[0].toUpperCase()}${e.key.substring(1)}': e.value,
    };

extension DatLineFields on DathareketDto {
  Map<String, dynamic> toWarehouseJson(String parentId,
          {bool includeId = false}) =>
      {
        if (includeId) 'id': id,
        'datid': parentId,
        'stokid': stokid,
        'stokozelliksabitid': stokozelliksabitid,
        'olcubrid': olcubrid,
        'projeid': projeid,
        'miktar': miktar,
        'miktar2': miktar2,
        'cikacagisubeid': cikacagisubeid,
        'cikacagidepoid': cikacagidepoid,
        'cikacagidepoadresid': cikacagidepoadresid,
        'gidecegisubeid': gidecegisubeid,
        'gidecegidepoid': gidecegidepoid,
        'gidecegidepoadresid': gidecegidepoadresid,
        'aciklama': aciklama,
      };
}

extension AmbarLineFields on AmbargchareketDto {
  Map<String, dynamic> toWarehouseJson(String parentId,
          {bool includeId = false}) =>
      {
        if (includeId) 'id': id,
        'ambargcid': parentId,
        'stokid': stokid,
        'stokozelliksabitid': stokozelliksabitid,
        'depoid': depoid,
        'depoadresid': depoadresid,
        'olcubrid': olcubrid,
        'projeid': projeid,
        'miktar': miktar,
        'miktar2': miktar2,
        'dovizfiyat': dovizfiyat,
        'fiyat': fiyat ?? 0,
        'tutar': tutar ?? 0,
        'aciklama': aciklama,
        'tarih': tarih?.toIso8601String(),
      };
}

void priceWarehouseLine(AmbargchareketDto line,
    {required bool foreign, required double rate}) {
  if (foreign) {
    line.fiyat = (line.dovizfiyat ?? 0) * rate;
  } else {
    line.dovizfiyat = 0;
  }
  line.tutar = (line.miktar ?? 0) * (line.fiyat ?? 0);
}

void repriceWarehouseLines(Iterable<AmbargchareketDto> lines,
    {required bool foreign, required double rate}) {
  if (foreign && rate <= 0) return;
  for (final line in lines) {
    if (foreign && line.dovizfiyat == null)
      line.dovizfiyat = (line.fiyat ?? 0) / rate;
    priceWarehouseLine(line, foreign: foreign, rate: rate);
  }
}
