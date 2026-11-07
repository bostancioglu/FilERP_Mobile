class SenetverilenodemehareketCreateDto {
  String? senetverilenhareketid; // Guid — ödenecek senet
  String? senetverilenodemeid;   // Guid — üst ödeme bordrosu
  double? kur;

  SenetverilenodemehareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (senetverilenhareketid != null) 'Senetverilenhareketid': senetverilenhareketid,
        if (senetverilenodemeid != null)   'Senetverilenodemeid':   senetverilenodemeid,
        if (kur != null)                 'Kur':                 kur,
      };
}
