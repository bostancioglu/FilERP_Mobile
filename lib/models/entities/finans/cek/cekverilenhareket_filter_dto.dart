class CekverilenhareketFilterDto {
  int? cariid;
  int? projeid;
  int? bankahesapid;
  int? cekbankaid;
  int? cekbankasubeid;
  List<int>? evrakdurum;
  List<int>? evrakyeri;
  bool? bankahesapidEquals;
  bool? projeidEquals;

  CekverilenhareketFilterDto();

  Map<String, dynamic> toJson() => {
        if (cariid != null)             'Cariid':             cariid,
        if (projeid != null)            'Projeid':            projeid,
        if (bankahesapid != null)       'Bankahesapid':       bankahesapid,
        if (cekbankaid != null)         'Cekbankaid':         cekbankaid,
        if (cekbankasubeid != null)     'Cekbankasubeid':     cekbankasubeid,
        if (evrakdurum != null)         'Evrakdurum':         evrakdurum,
        if (evrakyeri != null)          'Evrakyeri':          evrakyeri,
        if (bankahesapidEquals != null) 'BankahesapidEquals': bankahesapidEquals,
        if (projeidEquals != null)      'ProjeidEquals':      projeidEquals,
      };
}
