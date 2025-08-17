import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class FaceDetectionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: true,
      enableClassification: true,
      minFaceSize: 0.2,
      enableTracking: true,
    ),
  );

  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<bool> detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final List<Face> faces = await _faceDetector.processImage(inputImage);
    return faces.isNotEmpty;
  }

  Future<String?> getFaceImageBase64() async {
    final imageFile = await pickImage();
    if (imageFile == null) return null;

    final hasFace = await detectFaces(imageFile);
    if (!hasFace) return null;

    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  Future<img.Image?> getImageFromBase64(String base64Image) async {
    try {
      final bytes = base64Decode(base64Image);
      return img.decodeImage(bytes);
    } catch (e) {
      print('Error decoding image: $e');
      return null;
    }
  }

  Future<String?> getFacePrint(File imageFile) async {
    try {
      final faces = await getFaceFeatures(imageFile);
      if (faces.isEmpty) return null;

      final face = faces.first;
      final landmarks = face.landmarks;

      final features = <String, dynamic>{};

      // 1. Calculate key landmarks
      final leftEye = landmarks[FaceLandmarkType.leftEye]?.position;
      final rightEye = landmarks[FaceLandmarkType.rightEye]?.position;
      final noseBase = landmarks[FaceLandmarkType.noseBase]?.position;
      final leftMouth = landmarks[FaceLandmarkType.leftMouth]?.position;
      final rightMouth = landmarks[FaceLandmarkType.rightMouth]?.position;

      // 2. Calculate facial proportions (more robust than absolute coordinates)
      if (leftEye != null && rightEye != null && noseBase != null) {
        final eyeDist = _calculateDistance(leftEye, rightEye);
        features['eye_distance'] = eyeDist;

        // Distance between eyes and nose
        final leftEyeNoseDist = _calculateDistance(leftEye, noseBase);
        final rightEyeNoseDist = _calculateDistance(rightEye, noseBase);

        if (eyeDist > 0) {
          // Prevent division by zero
          features['left_eye_nose'] = leftEyeNoseDist / eyeDist;
          features['right_eye_nose'] = rightEyeNoseDist / eyeDist;
        }
      }

      // 3. Mouth proportions
      if (leftMouth != null && rightMouth != null && noseBase != null) {
        final mouthWidth = _calculateDistance(leftMouth, rightMouth);
        features['mouth_width'] = mouthWidth;

        final mouthCenter = Point(
          (leftMouth.x + rightMouth.x) / 2,
          (leftMouth.y + rightMouth.y) / 2,
        );
        features['mouth_nose'] = _calculateDistance(mouthCenter, noseBase);
      }

      // 4. Normalized face contour
      if (face.contours.isNotEmpty) {
        final faceContour = face.contours[FaceContourType.face];
        if (faceContour != null && faceContour.points.isNotEmpty) {
          final basePoint = faceContour.points.first;
          features['face_contour'] = faceContour.points.map((p) {
            final distance = _calculateDistance(basePoint, Point(p.x, p.y));
            return {
              'x': distance > 0 ? (p.x - basePoint.x) / distance : 0,
              'y': distance > 0 ? (p.y - basePoint.y) / distance : 0,
            };
          }).toList();
        }
      }

      return json.encode(features);
    } catch (e) {
      print('Error generating faceprint: $e');
      return null;
    }
  }

  Future<double> compareFaces(String faceprint1, String faceprint2) async {
    try {
      print('Faceprint 1: $faceprint1');
      print('Faceprint 2: $faceprint2');

      if (faceprint1.isEmpty || faceprint2.isEmpty) {
        throw Exception('Uno de los faceprints está vacío');
      }

      final features1 = json.decode(faceprint1) as Map<String, dynamic>;
      final features2 = json.decode(faceprint2) as Map<String, dynamic>;

      double similarity = 0.0;
      int featureCount = 0;

      // Comparar contorno facial si existe
      if (features1['face_contour'] != null &&
          features2['face_contour'] != null) {
        final contour1 = List<Map<String, dynamic>>.from(
          features1['face_contour'],
        );
        final contour2 = List<Map<String, dynamic>>.from(
          features2['face_contour'],
        );

        if (contour1.length == contour2.length) {
          double contourSimilarity = 0.0;

          // Normalizar coordenadas respecto al primer punto
          final baseX1 = contour1[0]['x'].toDouble();
          final baseY1 = contour1[0]['y'].toDouble();
          final baseX2 = contour2[0]['x'].toDouble();
          final baseY2 = contour2[0]['y'].toDouble();

          for (int i = 0; i < contour1.length; i++) {
            // Calcular posiciones relativas
            final relX1 = contour1[i]['x'].toDouble() - baseX1;
            final relY1 = contour1[i]['y'].toDouble() - baseY1;
            final relX2 = contour2[i]['x'].toDouble() - baseX2;
            final relY2 = contour2[i]['y'].toDouble() - baseY2;

            // Calcular distancia entre puntos relativos
            final dist = sqrt(pow(relX1 - relX2, 2) + pow(relY1 - relY2, 2));

            // Normalizar (asumimos que 100px es la máxima diferencia aceptable)
            contourSimilarity += 1 - (dist / 100).clamp(0.0, 1.0);
          }

          similarity += contourSimilarity / contour1.length;
          featureCount++;
        }
      }

      // Comparar distancia entre ojos
      if (features1['eye_distance'] != null &&
          features2['eye_distance'] != null) {
        final diff = (features1['eye_distance'] - features2['eye_distance'])
            .abs();
        similarity += 1 - (diff / features1['eye_distance']).clamp(0.0, 1.0);
        featureCount++;
      }

      // Comparar ancho de boca
      if (features1['mouth_width'] != null &&
          features2['mouth_width'] != null) {
        final diff = (features1['mouth_width'] - features2['mouth_width'])
            .abs();
        similarity += 1 - (diff / features1['mouth_width']).clamp(0.0, 1.0);
        featureCount++;
      }

      // Comparar posición de nariz
      if (features1['nose_position'] != null &&
          features2['nose_position'] != null) {
        final nose1 = features1['nose_position'] as Map<String, dynamic>;
        final nose2 = features2['nose_position'] as Map<String, dynamic>;
        final dist = sqrt(
          pow(nose1['x'] - nose2['x'], 2) + pow(nose1['y'] - nose2['y'], 2),
        );
        similarity += 1 - (dist / 100).clamp(0.0, 1.0);
        featureCount++;
      }

      return featureCount > 0 ? similarity / featureCount : 0.0;
    } catch (e) {
      print('Error comparing faceprints: $e');
      return 0.0;
    }
  }

  Future<List<img.Point>?> getFacialPoints(File imageFile) async {
    try {
      final faces = await getFaceFeatures(imageFile);
      if (faces.isEmpty) return null;

      final face = faces.first;
      final points = <img.Point>[];

      // Add key landmarks
      final landmarks = face.landmarks;
      landmarks.forEach((type, landmark) {
        points.add(img.Point(landmark!.position.x, landmark.position.y));
      });

      // Add face contour points
      if (face.contours.isNotEmpty) {
        final faceContour = face.contours[FaceContourType.face];
        if (faceContour != null) {
          points.addAll(faceContour.points.map((p) => img.Point(p.x, p.y)));
        }
      }

      return points;
    } catch (e) {
      print('Error getting facial points: $e');
      return null;
    }
  }

  Future<Map<String, String>?> getFaceData({int captureCount = 1}) async {
    try {
      List<String> faceprints = [];
      String? imageBase64;
      String? imagePath;

      for (int i = 0; i < captureCount; i++) {
        final imageFile = await pickImage();
        if (imageFile == null) continue;

        imagePath = imageFile.path;
        final hasFace = await detectFaces(imageFile);
        if (!hasFace) continue;

        final bytes = await imageFile.readAsBytes();
        imageBase64 = base64Encode(bytes);

        final facePrint = await getFacePrint(imageFile);
        if (facePrint != null) {
          faceprints.add(facePrint);
        }
      }

      if (faceprints.isEmpty) return null;

      return {
        'image': imageBase64 ?? '',
        'faceprint': faceprints.first,
        'imagePath': imagePath ?? '',
      };
    } catch (e) {
      print('Error in getFaceData: $e');
      return null;
    }
  }

  Future<List<Face>> getFaceFeatures(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    return await _faceDetector.processImage(inputImage);
  }

  Future<double> compareFaceFeatures(
    List<Face> faces1,
    List<Face> faces2,
  ) async {
    if (faces1.isEmpty || faces2.isEmpty) return 0.0;

    // Comparar características faciales principales
    final face1 = faces1.first;
    final face2 = faces2.first;

    double similarity = 0.0;

    // Obtener landmarks (puntos de referencia faciales)
    final landmarks1 = face1.landmarks;
    final landmarks2 = face2.landmarks;

    // Comparar posición de ojos si están disponibles
    final leftEye1 = landmarks1[FaceLandmarkType.leftEye];
    final rightEye1 = landmarks1[FaceLandmarkType.rightEye];
    final leftEye2 = landmarks2[FaceLandmarkType.leftEye];
    final rightEye2 = landmarks2[FaceLandmarkType.rightEye];

    if (leftEye1 != null &&
        rightEye1 != null &&
        leftEye2 != null &&
        rightEye2 != null) {
      final eyeDist1 = _calculateDistance(
        leftEye1.position,
        rightEye1.position,
      );
      final eyeDist2 = _calculateDistance(
        leftEye2.position,
        rightEye2.position,
      );
      similarity +=
          1 - ((eyeDist1 - eyeDist2).abs() / eyeDist1).clamp(0.0, 1.0);
    }

    // Comparar posición de boca si está disponible
    final mouth1 = landmarks1[FaceLandmarkType.bottomMouth];
    final mouth2 = landmarks2[FaceLandmarkType.bottomMouth];

    if (mouth1 != null && mouth2 != null) {
      final mouthWidth1 = _calculateDistance(
        landmarks1[FaceLandmarkType.leftMouth]?.position ?? mouth1.position,
        landmarks1[FaceLandmarkType.rightMouth]?.position ?? mouth1.position,
      );
      final mouthWidth2 = _calculateDistance(
        landmarks2[FaceLandmarkType.leftMouth]?.position ?? mouth2.position,
        landmarks2[FaceLandmarkType.rightMouth]?.position ?? mouth2.position,
      );
      similarity +=
          1 - ((mouthWidth1 - mouthWidth2).abs() / mouthWidth1).clamp(0.0, 1.0);
    }

    // Comparar posición de nariz si está disponible
    final nose1 = landmarks1[FaceLandmarkType.noseBase];
    final nose2 = landmarks2[FaceLandmarkType.noseBase];

    if (nose1 != null && nose2 != null) {
      similarity +=
          1 -
          (_calculateDistance(nose1.position, nose2.position) / 100).clamp(
            0.0,
            1.0,
          );
    }

    // Normalizar resultado (dividimos por 3 porque comparamos 3 características)
    return (similarity / 3).clamp(0.0, 1.0);
  }

  double _calculateDistance(Point a, Point b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  void dispose() {
    _faceDetector.close();
  }
}
