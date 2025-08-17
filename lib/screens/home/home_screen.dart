import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
  bool _isCapturing = false;
  int _captureCount = 0;
  bool _showWelcomeDialog = false;
  String? _welcomeUserName;
  String? _randomGifPath;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _checkBiometrics();
  }

  void _showWelcomeDialogEmergente(String userName) {
    final random = Random();
    final gifNumber =
        random.nextInt(5) + 1; // Asume que tienes hola1.gif a hola5.gif
    setState(() {
      _welcomeUserName = userName;
      _randomGifPath = 'assets/gifs/hola$gifNumber.gif';
      _showWelcomeDialog = true;
    });

    // Cerrar automáticamente después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showWelcomeDialog = false;
        });
      }
    });
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
        _showWelcomeDialogEmergente(matchedUser.user_Name ?? 'Usuario');
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

    setState(() {
      _isLoading = true;
      _isCapturing = true;
      _captureCount = 0;
    });

    // Iniciar proceso de captura automática
    _startAutoCapture();
  }

  Future<void> _startAutoCapture() async {
    try {
      final List<String> faceprints = [];
      String? imageBase64;

      // Capturar 3 imágenes automáticamente
      for (int i = 0; i < 3; i++) {
        if (!_isCapturing) break; // Permitir cancelación

        setState(() => _captureCount = i + 1);

        final faceData = await _faceService.getFaceData(captureCount: 1);
        await Future.delayed(
          const Duration(seconds: 1),
        ); // Intervalo entre capturas

        if (faceData != null &&
            faceData['faceprint'] != null &&
            faceData['image'] != null) {
          faceprints.add(faceData['faceprint']!);
          imageBase64 = faceData['image'];

          // Obtener datos para vista previa
          final imagePath = faceData['imagePath'];
          if (imagePath != null) {
            final facialPoints = await _faceService.getFacialPoints(
              File(imagePath),
            );
            final capturedImage = await _faceService.getImageFromBase64(
              faceData['image']!,
            );

            // Actualizar UI
            setState(() {
              _facialPoints = facialPoints;
              _capturedImage = capturedImage;
            });
          }
        }
      }

      if (faceprints.isEmpty) {
        _showSnackBar('No se detectaron rostros válidos');
        return;
      }

      if (_selectedUser == null || imageBase64 == null) {
        _showSnackBar('Error en los datos del usuario');
        return;
      }

      // Procesar los datos capturados
      final updatedUser = Users(
        id_User: _selectedUser!.id_User,
        user_Name: _selectedUser!.user_Name,
        user_Contacto: _selectedUser!.user_Contacto,
        user_Access: _selectedUser!.user_Access,
        user_Password: _selectedUser!.user_Password,
        user_Rostro64: imageBase64,
        user_HuellaFacial: faceprints.first,
        user_Rol: _selectedUser!.user_Rol,
        idRole: _selectedUser!.idRole,
      );

      final success = await _usersController.editUser(updatedUser, context);

      if (success) {
        _showSnackBar(
          'Datos biométricos registrados exitosamente para ${_selectedUser!.user_Name}',
        );
        setState(() {
          _usersList.clear();
          _selectedUser = null;
        });
        await _loadUsers();
      } else {
        _showSnackBar('Error al guardar datos biométricos');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isCapturing = false;
      });
    }
  }

  Future<void> _captureAttendanceFace() async {
    setState(() {
      _isLoading = true;
      _isCapturing = true;
      _captureCount = 0;
    });

    try {
      final faceData = await _faceService.getFaceData(captureCount: 1);

      if (faceData == null ||
          faceData['faceprint'] == null ||
          faceData['image'] == null) {
        _showSnackBar('No se detectó un rostro válido');
        return;
      }

      _attendanceFaceImageBase64 = faceData['faceprint'];

      // Mostrar puntos faciales
      final imagePath = faceData['imagePath'];
      if (imagePath != null) {
        final facialPoints = await _faceService.getFacialPoints(
          File(imagePath),
        );
        final bytes = await File(imagePath).readAsBytes();
        final capturedImage = await _faceService.getImageFromBase64(
          base64Encode(bytes),
        );

        setState(() {
          _facialPoints = facialPoints;
          _capturedImage = capturedImage;
        });
      }

      await _registerAttendance();
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isCapturing = false;
      });
    }
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
      body: Stack(
        children: [
          Container(
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
                      Column(
                        children: [
                          InkWell(
                            onTap: _captureAttendanceFace,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Image.asset('assets/png/camara.png'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Registrar Asistencia',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
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
                      if (_isCapturing)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Column(
                            children: [
                              Text('Capturando imagen $_captureCount/3'),
                              const SizedBox(height: 10),
                              const CircularProgressIndicator(),
                            ],
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
          if (_showWelcomeDialog)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_randomGifPath != null)
                      Image.asset(
                        _randomGifPath!,
                        height: 150,
                        width: 150,
                        fit: BoxFit.contain,
                      ),
                    const SizedBox(height: 10),
                    Text(
                      '¡Bienvenido de vuelta $_welcomeUserName 😁!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
