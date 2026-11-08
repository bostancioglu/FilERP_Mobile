class CekalinanportfoydentahsilhareketCreateDto {
  String? cekalinanhareketid;             // Guid — tahsil edilecek çek
  String? cekalinanportfoydentahsilid;    // Guid — üst tahsil bordrosu
  double? kur;
  double? doviztutar;
  double? tutar;
  double? masraf;
  bool?   masraficindenmi;
  int?    oncekievrakdurum; // çekin tahsil öncesi Evrakdurum'u — silme/iptal durumunda geri dönüş için
  int?    oncekievrakyeri;  // çekin tahsil öncesi Evrakyeri'i — silme/iptal durumunda geri dönüş için

  CekalinanportfoydentahsilhareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (cekalinanhareketid != null)          'Cekalinanhareketid':          cekalinanhareketid,
        if (cekalinanportfoydentahsilid != null) 'Cekalinanportfoydentahsilid': cekalinanportfoydentahsilid,
        if (kur != null)                         'Kur':                        kur,
        if (doviztutar != null)                  'Doviztutar':                 doviztutar,
        if (tutar != null)                       'Tutar':                      tutar,
        if (masraf != null)                      'Masraf':                     masraf,
        if (masraficindenmi != null)             'Masraficindenmi':            masraficindenmi,
        if (oncekievrakdurum != null)             'Oncekievrakdurum':           oncekievrakdurum,
        if (oncekievrakyeri != null)              'Oncekievrakyeri':            oncekievrakyeri,
      };
}
