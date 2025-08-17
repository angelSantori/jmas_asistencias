import 'dart:convert';

class Asistencia {
  int? idAsistencia;
  String? fechaAsistencia;
  String? horaAsistencia;
  int? idUser;
  Asistencia({
    this.idAsistencia,
    this.fechaAsistencia,
    this.horaAsistencia,
    this.idUser,
  });

  Asistencia copyWith({
    int? idAsistencia,
    String? fechaAsistencia,
    String? horaAsistencia,
    int? idUser,
  }) {
    return Asistencia(
      idAsistencia: idAsistencia ?? this.idAsistencia,
      fechaAsistencia: fechaAsistencia ?? this.fechaAsistencia,
      horaAsistencia: horaAsistencia ?? this.horaAsistencia,
      idUser: idUser ?? this.idUser,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idAsistencia': idAsistencia,
      'fechaAsistencia': fechaAsistencia,
      'horaAsistencia': horaAsistencia,
      'idUser': idUser,
    };
  }

  factory Asistencia.fromMap(Map<String, dynamic> map) {
    return Asistencia(
      idAsistencia: map['idAsistencia'] != null
          ? map['idAsistencia'] as int
          : null,
      fechaAsistencia: map['fechaAsistencia'] != null
          ? map['fechaAsistencia'] as String
          : null,
      horaAsistencia: map['horaAsistencia'] != null
          ? map['horaAsistencia'] as String
          : null,
      idUser: map['idUser'] != null ? map['idUser'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Asistencia.fromJson(String source) =>
      Asistencia.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Asistencia(idAsistencia: $idAsistencia, fechaAsistencia: $fechaAsistencia, horaAsistencia: $horaAsistencia, idUser: $idUser)';
  }

  @override
  bool operator ==(covariant Asistencia other) {
    if (identical(this, other)) return true;

    return other.idAsistencia == idAsistencia &&
        other.fechaAsistencia == fechaAsistencia &&
        other.horaAsistencia == horaAsistencia &&
        other.idUser == idUser;
  }

  @override
  int get hashCode {
    return idAsistencia.hashCode ^
        fechaAsistencia.hashCode ^
        horaAsistencia.hashCode ^
        idUser.hashCode;
  }
}
