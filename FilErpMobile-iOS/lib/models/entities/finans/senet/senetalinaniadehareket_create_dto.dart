class SenetalinaniadehareketCreateDto {
  String? senetalinanhareketid; // Guid — iade edilecek senet
  String? senetalinaniadeid;    // Guid — üst iade bordrosu
  int?    oncekievrakdurum;   // senedin iade öncesi Evrakdurum'u — silme/iptal durumunda geri dönüş için
  int?    oncekievrakyeri;    // senedin iade öncesi Evrakyeri'i — silme/iptal durumunda geri dönüş için

  SenetalinaniadehareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (senetalinanhareketid != null) 'Senetalinanhareketid': senetalinanhareketid,
        if (senetalinaniadeid != null)    'Senetalinaniadeid':    senetalinaniadeid,
        if (oncekievrakdurum != null)   'Oncekievrakdurum':   oncekievrakdurum,
        if (oncekievrakyeri != null)    'Oncekievrakyeri':    oncekievrakyeri,
      };
}
