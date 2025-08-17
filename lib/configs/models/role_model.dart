import 'dart:convert';

class Role {
  int? idRole;
  String? roleNombre;
  String? roleDescr;
  bool? canView;
  bool? canAdd;
  bool? canEdit;
  bool? canDelete;
  bool? canManageUsers;
  bool? canManageRoles;
  bool? canEvaluar;
  bool? canCContables;
  Role({
    this.idRole,
    this.roleNombre,
    this.roleDescr,
    this.canView,
    this.canAdd,
    this.canEdit,
    this.canDelete,
    this.canManageUsers,
    this.canManageRoles,
    this.canEvaluar,
    this.canCContables,
  });

  Role copyWith({
    int? idRole,
    String? roleNombre,
    String? roleDescr,
    bool? canView,
    bool? canAdd,
    bool? canEdit,
    bool? canDelete,
    bool? canManageUsers,
    bool? canManageRoles,
    bool? canEvaluar,
    bool? canCContables,
  }) {
    return Role(
      idRole: idRole ?? this.idRole,
      roleNombre: roleNombre ?? this.roleNombre,
      roleDescr: roleDescr ?? this.roleDescr,
      canView: canView ?? this.canView,
      canAdd: canAdd ?? this.canAdd,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      canManageUsers: canManageUsers ?? this.canManageUsers,
      canManageRoles: canManageRoles ?? this.canManageRoles,
      canEvaluar: canEvaluar ?? this.canEvaluar,
      canCContables: canCContables ?? this.canCContables,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idRole': idRole,
      'roleNombre': roleNombre,
      'roleDescr': roleDescr,
      'canView': canView,
      'canAdd': canAdd,
      'canEdit': canEdit,
      'canDelete': canDelete,
      'canManageUsers': canManageUsers,
      'canManageRoles': canManageRoles,
      'canEvaluar': canEvaluar,
      'canCContables': canCContables,
    };
  }

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      idRole: map['idRole'] != null ? map['idRole'] as int : null,
      roleNombre: map['roleNombre'] != null ? map['roleNombre'] as String : null,
      roleDescr: map['roleDescr'] != null ? map['roleDescr'] as String : null,
      canView: map['canView'] != null ? map['canView'] as bool : null,
      canAdd: map['canAdd'] != null ? map['canAdd'] as bool : null,
      canEdit: map['canEdit'] != null ? map['canEdit'] as bool : null,
      canDelete: map['canDelete'] != null ? map['canDelete'] as bool : null,
      canManageUsers: map['canManageUsers'] != null ? map['canManageUsers'] as bool : null,
      canManageRoles: map['canManageRoles'] != null ? map['canManageRoles'] as bool : null,
      canEvaluar: map['canEvaluar'] != null ? map['canEvaluar'] as bool : null,
      canCContables: map['canCContables'] != null ? map['canCContables'] as bool : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Role.fromJson(String source) => Role.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Role(idRole: $idRole, roleNombre: $roleNombre, roleDescr: $roleDescr, canView: $canView, canAdd: $canAdd, canEdit: $canEdit, canDelete: $canDelete, canManageUsers: $canManageUsers, canManageRoles: $canManageRoles, canEvaluar: $canEvaluar, canCContables: $canCContables)';
  }

  @override
  bool operator ==(covariant Role other) {
    if (identical(this, other)) return true;
  
    return 
      other.idRole == idRole &&
      other.roleNombre == roleNombre &&
      other.roleDescr == roleDescr &&
      other.canView == canView &&
      other.canAdd == canAdd &&
      other.canEdit == canEdit &&
      other.canDelete == canDelete &&
      other.canManageUsers == canManageUsers &&
      other.canManageRoles == canManageRoles &&
      other.canEvaluar == canEvaluar &&
      other.canCContables == canCContables;
  }

  @override
  int get hashCode {
    return idRole.hashCode ^
      roleNombre.hashCode ^
      roleDescr.hashCode ^
      canView.hashCode ^
      canAdd.hashCode ^
      canEdit.hashCode ^
      canDelete.hashCode ^
      canManageUsers.hashCode ^
      canManageRoles.hashCode ^
      canEvaluar.hashCode ^
      canCContables.hashCode;
  }
}
