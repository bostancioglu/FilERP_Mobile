class CekverileniadehareketCreateDto {
  String? cekverilenhareketid; // Guid — iade edilecek çek
  String? cekverileniadeid;    // Guid — üst iade bordrosu

  CekverileniadehareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (cekverilenhareketid != null) 'Cekverilenhareketid': cekverilenhareketid,
        if (cekverileniadeid != null)    'Cekverileniadeid':    cekverileniadeid,
      };
}
