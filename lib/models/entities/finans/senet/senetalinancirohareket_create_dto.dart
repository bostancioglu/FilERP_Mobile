class SenetalinancirohareketCreateDto {
  String? senetalinanhareketid; // Guid — cirolanan (portföydeki) senet
  String? senetalinanciroid;    // Guid — üst ciro bordrosu
  double? kur;

  SenetalinancirohareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (senetalinanhareketid != null) 'Senetalinanhareketid': senetalinanhareketid,
        if (senetalinanciroid != null)    'Senetalinanciroid':    senetalinanciroid,
        if (kur != null)                'Kur':                kur,
      };
}
