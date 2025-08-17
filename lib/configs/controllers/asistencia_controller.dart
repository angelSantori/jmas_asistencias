import 'dart:io';

import 'package:http/io_client.dart';
import 'package:jmas_asistencias/configs/models/asistencia_model.dart';
import 'package:jmas_asistencias/configs/services/auth_service.dart';

class AsistenciaController {
  final AuthService _authService = AuthService();

  IOClient _createHttpClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  //  Add Asistencia
  Future<bool> addAsistencia(Asistencia asistencia) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.post(
        Uri.parse('${_authService.apiURL}/Asistencias'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: asistencia.toJson(),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print(
          'Error addAsistencia | Ife | AsistenciaController: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error addAsistencia | Try | AsistenciaController: $e');
      return false;
    }
  }
}
