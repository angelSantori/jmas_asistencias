import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:jmas_asistencias/configs/controllers/asistencia_controller.dart';
import 'package:jmas_asistencias/configs/controllers/users_controller.dart';
import 'package:jmas_asistencias/configs/models/asistencia_model.dart';
import 'package:jmas_asistencias/configs/models/users_model.dart';
import 'package:intl/intl.dart';
import 'package:jmas_asistencias/screens/home/widgets/faceDetectionService.dart';
import 'package:jmas_asistencias/screens/home/widgets/facePointsPainter.dart';
import 'package:local_auth/local_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FaceDetectionService _faceService = FaceDetectionService();
  final UsersController _usersController = UsersController();
  final AsistenciaController _asistenciaController = AsistenciaController();
  final LocalAuthentication _localAuth = LocalAuthentication();

  String? _attendanceFaceImageBase64;
  bool _isLoading = false;
  List<Users> _usersList = [];
  Users? _selectedUser;
  // ignore: unused_field
  bool _supportsBiometrics = false;
  List<img.Point>? _facialPoints;
  img.Image? _capturedImage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      _supportsBiometrics = await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('Error checking biometrics: $e');
    }
  }

  Future<Uint8List> _convertImageToDisplayFormat(img.Image image) async {
    final pngBytes = img.encodePng(image);
    return Uint8List.fromList(pngBytes);
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _usersController.listUsers();

    setState(() {
      _usersList = users;

      // Si había un usuario seleccionado, reemparejarlo por id
      if (_selectedUser != null) {
        _selectedUser = _usersList.firstWhere(
          (u) => u.id_User == _selectedUser!.id_User,
          orElse: () => _selectedUser!,
        );
      }

      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _faceService.dispose();
    super.dispose();
  }

  Future<void> _registerAttendance() async {
    if (_attendanceFaceImageBase64 == null) {
      _showSnackBar('Por favor, capture una imagen facial');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Buscar usuario por coincidencia facial
      Users? matchedUser;
      double highestSimilarity = 0.0;

      for (final user in _usersList) {
        if (user.user_HuellaFacial == null || user.user_HuellaFacial!.isEmpty)
          continue;

        print('Comparando con usuario: ${user.user_Name}');
        print('Faceprint almacenado: ${user.user_HuellaFacial}');
        print('Faceprint capturado: $_attendanceFaceImageBase64');

        final similarity = await _faceService.compareFaces(
          user.user_HuellaFacial!,
          _attendanceFaceImageBase64!,
        );

        print('Similitud con ${user.user_Name}: ${similarity * 100}%');

        if (similarity > highestSimilarity && similarity >= 0.6) {
          // Reducir umbral a 0.6
          highestSimilarity = similarity;
          matchedUser = user;
        }
      }

      if (matchedUser == null) {
        _showSnackBar(
          'No se encontró un usuario con coincidencia facial suficiente',
        );
        return;
      }

      // Registrar asistencia
      final now = DateTime.now();
      final asistencia = Asistencia(
        idAsistencia: 0,
        fechaAsistencia: DateFormat('dd/MM/yyyy').format(now),
        horaAsistencia: DateFormat('HH:mm:ss').format(now),
        idUser: matchedUser.id_User!,
      );

      final success = await _asistenciaController.addAsistencia(asistencia);

      if (success) {
        _showSnackBar(
          'Asistencia registrada para ${matchedUser.user_Name}. Similitud: ${(highestSimilarity * 100).toStringAsFixed(1)}%',
        );
      } else {
        _showSnackBar('Error al registrar asistencia');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _attendanceFaceImageBase64 = null;
      });
    }
  }

  Future<void> _registerUserBiometrics() async {
    if (_selectedUser == null) {
      _showSnackBar('Por favor, seleccione un usuario');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final faceData = await _faceService.getFaceData();
      if (faceData == null || faceData['image'] == null) {
        _showSnackBar('No se detectó un rostro válido');
        return;
      }

      final updatedUser = Users(
        id_User: _selectedUser!.id_User,
        user_Name: _selectedUser!.user_Name,
        user_Contacto: _selectedUser!.user_Contacto,
        user_Access: _selectedUser!.user_Access,
        user_Password: _selectedUser!.user_Password,
        user_Rostro64: faceData['image'],
        user_HuellaFacial: faceData['faceprint'],
        user_Rol: _selectedUser!.user_Rol,
        idRole: _selectedUser!.idRole,
      );

      final success = await _usersController.editUser(updatedUser, context);

      if (success) {
        _showSnackBar(
          'Datos biométricos registrados exitosamente para ${_selectedUser!.user_Name}',
        );
        setState(() {
          _usersList.clear;
          _selectedUser = null;
          _loadUsers();
        });
      } else {
        _showSnackBar('Error al guardar datos biométricos');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _captureAttendanceFace() async {
    setState(() => _isLoading = true);
    final faceData = await _faceService.getFaceData();

    if (faceData == null || faceData['faceprint'] == null) {
      _showSnackBar('No se detectó un rostro válido');
    } else {
      _attendanceFaceImageBase64 = faceData['faceprint'];

      // Get facial points for visualization
      final imageFile = await _faceService.pickImage();
      if (imageFile != null) {
        _facialPoints = await _faceService.getFacialPoints(imageFile);
        final bytes = await imageFile.readAsBytes();
        _capturedImage = await _faceService.getImageFromBase64(
          base64Encode(bytes),
        );
      }

      _registerAttendance();
    }
    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color.fromARGB(255, 96, 156, 217),
              const Color.fromARGB(255, 4, 134, 240),
            ],
          ),
        ),
        child: Center(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _captureAttendanceFace,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Registrar Asistencia Facial'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<Users>(
                    value: _selectedUser,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    hint: const Text('Seleccione un usuario'),
                    items: _usersList.map((user) {
                      return DropdownMenuItem<Users>(
                        value: user,
                        child: Text(user.user_Name ?? 'Usuario sin nombre'),
                      );
                    }).toList(),
                    onChanged: (Users? user) {
                      setState(() {
                        _selectedUser = user;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _registerUserBiometrics,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Registrar Datos'),
                    ),
                  ),
                  if (_capturedImage != null && _facialPoints != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: FutureBuilder<Uint8List>(
                        future: _convertImageToDisplayFormat(_capturedImage!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              snapshot.hasData) {
                            return Stack(
                              children: [
                                Image.memory(
                                  snapshot.data!,
                                  height: 200, // Ajusta según necesites
                                  width: 200, // Ajusta según necesites
                                  fit: BoxFit.contain,
                                ),
                                CustomPaint(
                                  painter: FacePointsPainter(_facialPoints!),
                                ),
                              ],
                            );
                          }
                          return const CircularProgressIndicator();
                        },
                      ),
                    ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
