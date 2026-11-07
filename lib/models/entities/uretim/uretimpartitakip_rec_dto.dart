import 'uretimpartino_dto.dart';
import '../olcubirimi/olcubr_dto.dart';
import '../stok/stok_dto.dart';
import '../stok/stokozelliksabit_dto.dart';

class UretimpartitakipRecDto {
  int? id;

  int? uretimpartinoid;
  DateTime? skt;
  double? miktar;
  int? stokid;
  int? stokozelliksabitid;
  int? olcubrid;

  UretimpartinoDto? uretimpartino;
  OlcubrDto? olcubr;
  StokDto? stok;
  StokozelliksabitDto? stokozelliksabit;

  UretimpartitakipRecDto();

  UretimpartitakipRecDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    uretimpartinoid = json["Uretimpartinoid"];
    skt = json["Skt"] != null ? DateTime.parse(json["Skt"]) : null;
    miktar = (json["Miktar"] as num?)?.toDouble();
    stokid = json["Stokid"];
    stokozelliksabitid = json["Stokozelliksabitid"];
    olcubrid = json["Olcubrid"];

    uretimpartino = json["Uretimpartino"] != null
        ? UretimpartinoDto.fromJson(json["Uretimpartino"])
        : null;
    olcubr =
        json["Olcubr"] != null ? OlcubrDto.fromJson(json["Olcubr"]) : null;
    stok =
        json["Stok"] != null ? StokDto.fromJson(json["Stok"]) : null;
    stokozelliksabit = json["Stokozelliksabit"] != null
        ? StokozelliksabitDto.fromJson(json["Stokozelliksabit"])
        : null;
  }
}
