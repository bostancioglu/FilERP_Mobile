class SenetalinanprotestohareketCreateDto {
  String? senetalinanhareketid;   // Guid — protesto edilecek senet
  String? senetalinanprotestoid;  // Guid — üst protesto bordrosu

  SenetalinanprotestohareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (senetalinanhareketid != null)  'Senetalinanhareketid':  senetalinanhareketid,
        if (senetalinanprotestoid != null) 'Senetalinanprotestoid': senetalinanprotestoid,
      };
}
