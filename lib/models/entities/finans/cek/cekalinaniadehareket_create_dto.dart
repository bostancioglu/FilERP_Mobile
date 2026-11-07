class CekalinaniadehareketCreateDto {
  String? cekalinanhareketid; // Guid — iade edilecek çek
  String? cekalinaniadeid;    // Guid — üst iade bordrosu
  int?    oncekievrakdurum;   // çekin iade öncesi Evrakdurum'u — silme/iptal durumunda geri dönüş için
  int?    oncekievrakyeri;    // çekin iade öncesi Evrakyeri'i — silme/iptal durumunda geri dönüş için

  CekalinaniadehareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (cekalinanhareketid != null) 'Cekalinanhareketid': cekalinanhareketid,
        if (cekalinaniadeid != null)    'Cekalinaniadeid':    cekalinaniadeid,
        if (oncekievrakdurum != null)   'Oncekievrakdurum':   oncekievrakdurum,
        if (oncekievrakyeri != null)    'Oncekievrakyeri':    oncekievrakyeri,
      };
}
