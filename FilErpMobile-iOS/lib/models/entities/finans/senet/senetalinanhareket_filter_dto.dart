class SenetalinanhareketFilterDto {
  int? cariid;
  int? projeid;
  List<int>? evrakdurum;
  List<int>? evrakyeri;
  int? cirobankaid;
  int? cirobankahesapid;
  int? cirocariid;
  bool? cariidEquals;
  bool? projeidEquals;

  SenetalinanhareketFilterDto();

  Map<String, dynamic> toJson() => {
        if (cariid != null)           'Cariid':           cariid,
        if (projeid != null)          'Projeid':          projeid,
        if (evrakdurum != null)       'Evrakdurum':       evrakdurum,
        if (evrakyeri != null)        'Evrakyeri':        evrakyeri,
        if (cirobankaid != null)      'Cirobankaid':      cirobankaid,
        if (cirobankahesapid != null) 'Cirobankahesapid': cirobankahesapid,
        if (cirocariid != null)       'Cirocariid':       cirocariid,
        if (cariidEquals != null)     'CariidEquals':     cariidEquals,
        if (projeidEquals != null)    'ProjeidEquals':    projeidEquals,
      };
}
