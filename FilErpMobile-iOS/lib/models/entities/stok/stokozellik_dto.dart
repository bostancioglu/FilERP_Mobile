import 'stokozelliksabit_dto.dart';

class StokozellikDto {
  int? id;
  int? stokid;
  int? stokozelliksabitid;
  String? carigrupkodu;
  int? sira;

  StokozelliksabitDto? stokozelliksabit;

  StokozellikDto();

  StokozellikDto.fromJson(Map<String, dynamic> json) {
    id = json['Id'];
    stokid = json['Stokid'];
    stokozelliksabitid = json['Stokozelliksabitid'];
    carigrupkodu = json['Carigrupkodu'];
    sira = json['Sira'];

    stokozelliksabit = json['Stokozelliksabit'] != null
        ? StokozelliksabitDto.fromJson(json['Stokozelliksabit'])
        : null;
  }

  /// Dropdown'da gösterilecek ad: önce sabit adı, yoksa id
  String get displayAd =>
      stokozelliksabit?.ad ?? stokozelliksabitid?.toString() ?? '';

  Map<String, dynamic> toJson() => {
        'Id': id,
        'Stokid': stokid,
        'Stokozelliksabitid': stokozelliksabitid,
        'Carigrupkodu': carigrupkodu,
        'Sira': sira,
        'Stokozelliksabit': stokozelliksabit == null
            ? null
            : {'Id': stokozelliksabit!.id, 'Ad': stokozelliksabit!.ad}
      };
}
