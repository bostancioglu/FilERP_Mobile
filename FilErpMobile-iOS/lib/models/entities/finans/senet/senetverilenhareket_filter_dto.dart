class SenetverilenhareketFilterDto {
  DateTime? vadetarihi1;
  DateTime? vadetarihi2;
  String? belgeseri1;
  String? belgeseri2;
  String? belgeno1;
  String? belgeno2;
  int? cariid;
  int? projeid;
  List<int>? evrakdurum;
  List<int>? evrakyeri;
  bool? projeidEquals;
  bool? evrakdurumEquals;
  bool? evrakyeriEquals;

  SenetverilenhareketFilterDto();

  Map<String, dynamic> toJson() => {
        if (vadetarihi1 != null)       'Vadetarihi1':      vadetarihi1!.toIso8601String(),
        if (vadetarihi2 != null)       'Vadetarihi2':      vadetarihi2!.toIso8601String(),
        if (belgeseri1 != null)        'Belgeseri1':       belgeseri1,
        if (belgeseri2 != null)        'Belgeseri2':       belgeseri2,
        if (belgeno1 != null)          'Belgeno1':         belgeno1,
        if (belgeno2 != null)          'Belgeno2':         belgeno2,
        if (cariid != null)            'Cariid':           cariid,
        if (projeid != null)           'Projeid':          projeid,
        if (evrakdurum != null)        'Evrakdurum':       evrakdurum,
        if (evrakyeri != null)         'Evrakyeri':        evrakyeri,
        if (projeidEquals != null)     'ProjeidEquals':    projeidEquals,
        if (evrakdurumEquals != null)  'EvrakdurumEquals': evrakdurumEquals,
        if (evrakyeriEquals != null)   'EvrakyeriEquals':  evrakyeriEquals,
      };
}
