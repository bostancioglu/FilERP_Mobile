class IlDto {
  final int Id;
  final String Ad;

  IlDto({required this.Id, required this.Ad});

  factory IlDto.fromJson(Map<String, dynamic> json) {
    return IlDto(
      Id: json['Id'],
      Ad: json['Ad'],
    );
  }
}
