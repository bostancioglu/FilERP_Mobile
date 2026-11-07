class IrsaliyeFilterDto {
  DateTime? tarih1;
  DateTime? tarih2;
  DateTime? teslimtarihi1;
  DateTime? teslimtarihi2;
  DateTime? tahsilattarihi1;
  DateTime? tahsilattarihi2;
  String?   belgeseri1;
  String?   belgeseri2;
  String?   belgeno1;
  String?   belgeno2;
  int?      cariid;
  int?      stokid;
  int?      projeid;
  int?      subeid;
  int?      referansid;

  IrsaliyeFilterDto();

  Map<String, dynamic> toJson() => {
    if (tarih1          != null) "tarih1"          : tarih1!.toIso8601String(),
    if (tarih2          != null) "tarih2"          : tarih2!.toIso8601String(),
    if (teslimtarihi1   != null) "teslimtarihi1"   : teslimtarihi1!.toIso8601String(),
    if (teslimtarihi2   != null) "teslimtarihi2"   : teslimtarihi2!.toIso8601String(),
    if (tahsilattarihi1 != null) "tahsilattarihi1" : tahsilattarihi1!.toIso8601String(),
    if (tahsilattarihi2 != null) "tahsilattarihi2" : tahsilattarihi2!.toIso8601String(),
    if (belgeseri1      != null) "belgeseri1"      : belgeseri1,
    if (belgeseri2      != null) "belgeseri2"      : belgeseri2,
    if (belgeno1        != null) "belgeno1"        : belgeno1,
    if (belgeno2        != null) "belgeno2"        : belgeno2,
    if (cariid          != null) "cariid"          : cariid,
    if (stokid          != null) "stokid"          : stokid,
    if (projeid         != null) "projeid"         : projeid,
    if (subeid          != null) "subeid"          : subeid,
    if (referansid      != null) "referansid"      : referansid,
  };
}