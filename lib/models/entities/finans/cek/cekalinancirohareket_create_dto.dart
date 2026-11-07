class CekalinancirohareketCreateDto {
  String? cekalinanhareketid; // Guid — cirolanan (portföydeki) çek
  String? cekalinanciroid;    // Guid — üst ciro bordrosu
  double? kur;

  CekalinancirohareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (cekalinanhareketid != null) 'Cekalinanhareketid': cekalinanhareketid,
        if (cekalinanciroid != null)    'Cekalinanciroid':    cekalinanciroid,
        if (kur != null)                'Kur':                kur,
      };
}
