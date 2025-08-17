// Librerías
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:jmas_asistencias/configs/models/users_model.dart';
import 'package:jmas_asistencias/configs/services/auth_service.dart';

class UsersController {
  final AuthService _authService = AuthService();

  IOClient _createHttpClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  Future<bool> addUser(Users user, BuildContext context) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.post(
        Uri.parse('${_authService.apiURL}/Users'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: user.toJson(),
      );

      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 409) {
        print(
          'Error al agregar usuario: ${response.statusCode} - ${response.body}',
        );
        //showError(context, 'ERROR: ${response.body}');
        return false;
      } else {
        print(
          'Error al agregar usuario ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error al agregar httpe: $e');
      return false;
    }
  }

  Future<Users?> getUserById(int idUser) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client
          .get(
            Uri.parse('${_authService.apiURL}/Users/$idUser'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData =
            json.decode(response.body) as Map<String, dynamic>;
        return Users.fromMap(jsonData);
      } else if (response.statusCode == 404) {
        print('Usuario no encontrado con ID: $idUser');
        return null;
      } else {
        print(
          'Error al obtener proveedor por ID: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error al obtener usuario por ID: $e');
      return null;
    }
  }

  Future<List<Users>> listUsers() async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/Users'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((user) => Users.fromMap(user)).toList();
      } else {
        print(
          'Error al obtener lista de usuarios: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error lista de usuarios: $e');
      return [];
    }
  }

  //GetUserXNombre
  Future<List<Users>> getUserXNombre(String userNombre) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse(
          '${_authService.apiURL}/Users/UserPorNombre?userNombre=$userNombre',
        ),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((userNameList) => Users.fromMap(userNameList)).toList();
      } else {
        print(
          'Error getUserXNombre | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error getUserXNombre | Try | Controller: $e');
      return [];
    }
  }

  Future<bool> loginUser(
    String userAccess,
    String userPassword,
    BuildContext context,
  ) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.post(
        Uri.parse('${_authService.apiURL}/Users/Login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'userAccess': userAccess,
          'userPassword': userPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        await _authService.saveToken(token);
        await _authService.saveUserData(Users.fromMap(userData));

        return true;
      } else if (response.statusCode == 401) {
        return false;
      } else {
        print('Error en el login: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error al intentar iniciar sesión: $e');
      //showError(context, 'Error de red $e');
      return false;
    }
  }

  Future<bool> editUser(
    Users user,
    BuildContext context, {
    String? password,
  }) async {
    try {
      final Map<String, dynamic> updateUserData = user.toMap();

      if (password != null && password.isNotEmpty) {
        updateUserData['user_Password'] = password;
      }

      print('Datos a enviar para edición: $updateUserData');

      final IOClient client = _createHttpClient();

      final response = await client.put(
        Uri.parse('${_authService.apiURL}/Users/${user.id_User}'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(updateUserData),
      );

      print(
        'Respuesta del servidor: ${response.statusCode} - ${response.body}',
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      } else {
        print(
          'Error al editar usuario: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error al editar usuario: $e');
      return false;
    }
  }
}
