class CekverilenodemehareketCreateDto {
  String? cekverilenhareketid; // Guid — ödenecek çek
  String? cekverilenodemeid;   // Guid — üst ödeme bordrosu
  double? kur;

  CekverilenodemehareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (cekverilenhareketid != null) 'Cekverilenhareketid': cekverilenhareketid,
        if (cekverilenodemeid != null)   'Cekverilenodemeid':   cekverilenodemeid,
        if (kur != null)                 'Kur':                 kur,
      };
}
