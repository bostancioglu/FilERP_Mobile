class CekalinantahsilhareketCreateDto {
  String? cekalinanhareketid; // Guid — tahsil edilecek çek
  String? cekalinantahsilid;  // Guid — üst tahsil bordrosu
  double? kur;

  CekalinantahsilhareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (cekalinanhareketid != null) 'Cekalinanhareketid': cekalinanhareketid,
        if (cekalinantahsilid != null)  'Cekalinantahsilid':  cekalinantahsilid,
        if (kur != null)                'Kur':                kur,
      };
}
