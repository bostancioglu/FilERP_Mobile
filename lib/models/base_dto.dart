class BaseDto {
  final int? Id;

  BaseDto({this.Id});

  factory BaseDto.fromJson(Map<String, dynamic> json) {
    return BaseDto(
      Id: json['Id'],
    );
  }
}
