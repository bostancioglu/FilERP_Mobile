class UlkeDto {
  final int Id;
  final String Ad;

  UlkeDto({required this.Id, required this.Ad});

  factory UlkeDto.fromJson(Map<String, dynamic> json) {
    return UlkeDto(
      Id: json['Id'],
      Ad: json['Ad'],
    );
  }
}
