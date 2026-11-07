class BaseUpdateDto {
  int? id;

  BaseUpdateDto({this.id});

  Map<String, dynamic> toJson() => {
        "id": id,
      };
}

class BaseUpdateDtoT<T> {
  T? id;

  BaseUpdateDtoT({this.id});

  Map<String, dynamic> toJson() => {
        "id": id,
      };
}
