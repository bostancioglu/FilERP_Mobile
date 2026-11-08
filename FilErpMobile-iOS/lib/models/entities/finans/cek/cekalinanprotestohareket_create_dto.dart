class CekalinanprotestohareketCreateDto {
  String? cekalinanhareketid;   // Guid — protesto edilecek çek
  String? cekalinanprotestoid;  // Guid — üst protesto bordrosu

  CekalinanprotestohareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (cekalinanhareketid != null)  'Cekalinanhareketid':  cekalinanhareketid,
        if (cekalinanprotestoid != null) 'Cekalinanprotestoid': cekalinanprotestoid,
      };
}
