class SenetalinantahsilhareketCreateDto {
  String? senetalinanhareketid; // Guid — tahsil edilecek senet
  String? senetalinantahsilid;  // Guid — üst tahsil bordrosu
  double? kur;

  SenetalinantahsilhareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (senetalinanhareketid != null) 'Senetalinanhareketid': senetalinanhareketid,
        if (senetalinantahsilid != null)  'Senetalinantahsilid':  senetalinantahsilid,
        if (kur != null)                'Kur':                kur,
      };
}
