// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:jmas_asistencias/configs/models/role_model.dart';

class Users {
  int? id_User;
  String? user_Name;
  String? user_Contacto;
  String? user_Access;
  String? user_Password;
  String? user_HuellaFacial;
  String? user_Rostro64;
  String? user_Rol;
  int? idRole;
  Role? role;
  Users({
    this.id_User,
    this.user_Name,
    this.user_Contacto,
    this.user_Access,
    this.user_Password,
    this.user_HuellaFacial,
    this.user_Rostro64,
    this.user_Rol,
    this.idRole,
    this.role,
  });

  Users copyWith({
    int? id_User,
    String? user_Name,
    String? user_Contacto,
    String? user_Access,
    String? user_Password,
    String? user_HuellaFacial,
    String? user_Rostro64,
    String? user_Rol,
    int? idRole,
    Role? role,
  }) {
    return Users(
      id_User: id_User ?? this.id_User,
      user_Name: user_Name ?? this.user_Name,
      user_Contacto: user_Contacto ?? this.user_Contacto,
      user_Access: user_Access ?? this.user_Access,
      user_Password: user_Password ?? this.user_Password,
      user_HuellaFacial: user_HuellaFacial ?? this.user_HuellaFacial,
      user_Rostro64: user_Rostro64 ?? this.user_Rostro64,
      user_Rol: user_Rol ?? this.user_Rol,
      idRole: idRole ?? this.idRole,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id_User': id_User,
      'user_Name': user_Name,
      'user_Contacto': user_Contacto,
      'user_Access': user_Access,
      'user_Password': user_Password,
      'user_HuellaFacial': user_HuellaFacial,
      'user_Rostro64': user_Rostro64,
      'user_Rol': user_Rol,
      'idRole': idRole,
      'role': role?.toMap(),
    };
  }

  factory Users.fromMap(Map<String, dynamic> map) {
    return Users(
      id_User: map['id_User'] != null ? map['id_User'] as int : null,
      user_Name: map['user_Name'] != null ? map['user_Name'] as String : null,
      user_Contacto: map['user_Contacto'] != null
          ? map['user_Contacto'] as String
          : null,
      user_Access: map['user_Access'] != null
          ? map['user_Access'] as String
          : null,
      user_Password: map['user_Password'] != null
          ? map['user_Password'] as String
          : null,
      user_HuellaFacial: map['user_HuellaFacial'] != null
          ? map['user_HuellaFacial'] as String
          : null,
      user_Rostro64: map['user_Rostro64'] != null
          ? map['user_Rostro64'] as String
          : null,
      user_Rol: map['user_Rol'] != null ? map['user_Rol'] as String : null,
      idRole: map['idRole'] != null ? map['idRole'] as int : null,
      role: map['role'] != null
          ? Role.fromMap(map['role'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Users.fromJson(String source) =>
      Users.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Users(id_User: $id_User, user_Name: $user_Name, user_Contacto: $user_Contacto, user_Access: $user_Access, user_Password: $user_Password, user_HuellaFacial: $user_HuellaFacial, user_Rostro64: $user_Rostro64, user_Rol: $user_Rol, idRole: $idRole, role: $role)';
  }

  @override
  bool operator ==(covariant Users other) {
    if (identical(this, other)) return true;

    return other.id_User == id_User &&
        other.user_Name == user_Name &&
        other.user_Contacto == user_Contacto &&
        other.user_Access == user_Access &&
        other.user_Password == user_Password &&
        other.user_HuellaFacial == user_HuellaFacial &&
        other.user_Rostro64 == user_Rostro64 &&
        other.user_Rol == user_Rol &&
        other.idRole == idRole &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id_User.hashCode ^
        user_Name.hashCode ^
        user_Contacto.hashCode ^
        user_Access.hashCode ^
        user_Password.hashCode ^
        user_HuellaFacial.hashCode ^
        user_Rostro64.hashCode ^
        user_Rol.hashCode ^
        idRole.hashCode ^
        role.hashCode;
  }
}
