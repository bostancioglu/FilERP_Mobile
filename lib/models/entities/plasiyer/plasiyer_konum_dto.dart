class PlasiyerKonumDto {
  final int? Plasiyerid;
  final String? PlasiyerAdi;
  final double? Enlem;
  final double? Boylam;
  final DateTime? Tarih;

  PlasiyerKonumDto({
    this.Plasiyerid,
    this.PlasiyerAdi,
    this.Enlem,
    this.Boylam,
    this.Tarih,
  });

  factory PlasiyerKonumDto.fromJson(Map<String, dynamic> json) {
    return PlasiyerKonumDto(
      Plasiyerid: json['Plasiyerid'] as int?,
      PlasiyerAdi: json['PlasiyerAdi'] as String?,
      Enlem: (json['Enlem'] as num?)?.toDouble(),
      Boylam: (json['Boylam'] as num?)?.toDouble(),
      Tarih: json['Tarih'] != null ? DateTime.tryParse(json['Tarih'] as String) : null,
    );
  }
}
