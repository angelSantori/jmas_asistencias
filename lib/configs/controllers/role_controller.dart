//Librerías
import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:jmas_asistencias/configs/models/role_model.dart';
import 'package:jmas_asistencias/configs/services/auth_service.dart';

class RoleController {
  final AuthService _authService = AuthService();

  IOClient _createHttpClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  //ListRole
  Future<List<Role>> listRole() async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/Roles'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((role) => Role.fromMap(role)).toList();
      } else {
        print(
          'Error al obtener roles | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error al listar roles | Ife | Controller: $e');
      return [];
    }
  }

  //EditRole
  Future<bool> editRole(Role role) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.put(
        Uri.parse('${_authService.apiURL}/Roles/${role.idRole}'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: role.toJson(),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print(
          'Error editRole | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error editRole | Try | Controller: $e');
      return false;
    }
  }

  //Add
  Future<bool> addRol(Role role) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.post(
        Uri.parse('${_authService.apiURL}/Roles'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: role.toJson(),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print(
          'Error addRol | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error addRole | Try | Controller: $e');
      return false;
    }
  }
}