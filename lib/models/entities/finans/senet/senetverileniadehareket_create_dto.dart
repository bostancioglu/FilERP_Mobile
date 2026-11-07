class SenetverileniadehareketCreateDto {
  String? senetverilenhareketid; // Guid — iade edilecek senet
  String? senetverileniadeid;    // Guid — üst iade bordrosu

  SenetverileniadehareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (senetverilenhareketid != null) 'Senetverilenhareketid': senetverilenhareketid,
        if (senetverileniadeid != null)    'Senetverileniadeid':    senetverileniadeid,
      };
}
