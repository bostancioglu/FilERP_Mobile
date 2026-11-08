class SenetalinanportfoydentahsilhareketCreateDto {
  String? senetalinanhareketid;             // Guid — tahsil edilecek senet
  String? senetalinanportfoydentahsilid;    // Guid — üst tahsil bordrosu
  double? kur;
  double? doviztutar;
  double? tutar;
  double? masraf;
  bool?   masraficindenmi;
  int?    oncekievrakdurum; // senedin tahsil öncesi Evrakdurum'u — silme/iptal durumunda geri dönüş için
  int?    oncekievrakyeri;  // senedin tahsil öncesi Evrakyeri'i — silme/iptal durumunda geri dönüş için

  SenetalinanportfoydentahsilhareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (senetalinanhareketid != null)          'Senetalinanhareketid':          senetalinanhareketid,
        if (senetalinanportfoydentahsilid != null) 'Senetalinanportfoydentahsilid': senetalinanportfoydentahsilid,
        if (kur != null)                         'Kur':                        kur,
        if (doviztutar != null)                  'Doviztutar':                 doviztutar,
        if (tutar != null)                       'Tutar':                      tutar,
        if (masraf != null)                      'Masraf':                     masraf,
        if (masraficindenmi != null)             'Masraficindenmi':            masraficindenmi,
        if (oncekievrakdurum != null)             'Oncekievrakdurum':           oncekievrakdurum,
        if (oncekievrakyeri != null)              'Oncekievrakyeri':            oncekievrakyeri,
      };
}
