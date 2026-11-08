class IlceDto {
  final int Id;
  final String Ad;

  IlceDto({required this.Id, required this.Ad});

  factory IlceDto.fromJson(Map<String, dynamic> json) {
    return IlceDto(
      Id: json['Id'],
      Ad: json['Ad'],
    );
  }
}
