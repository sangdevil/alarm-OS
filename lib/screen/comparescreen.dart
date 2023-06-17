import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class CamCompare extends StatefulWidget {
  bool faceCorrect = false;
  late XFile? myFaceImageFile;

  CamCompare({required this.myFaceImageFile, Key? key}) : super(key: key);

  @override
  _CamCompareState createState() => _CamCompareState();
}

class _CamCompareState extends State<CamCompare> {
  late bool resultBool = false;
  late XFile? myFaceImageFile;
  late CameraController _cameraController;
  late Future<void> _cameraInitFuture;

  @override
  void initState() {
    super.initState();
    _cameraInit();
  }

  Future<void> _cameraInit() async {
    myFaceImageFile = widget.myFaceImageFile;
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
    );

    await _cameraController.initialize();

    setState(() {});

    final resp = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final cameraPermission = resp[Permission.camera];
    final microphonePermission = resp[Permission.microphone];

    if (cameraPermission != PermissionStatus.granted ||
        microphonePermission != PermissionStatus.granted) {
      throw '카메라 또는 마이크 권한이 없습니다.';
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('얼굴을 인식해 주세요.'),
      ),
      body: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: _cameraController.value.aspectRatio,
              child: CameraPreview(_cameraController),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: faceCompare,
                  child: Text(
                    '촬영',
                    style: TextStyle(fontSize: 24.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void faceCompare() async {
    final faceDetector = GoogleMlKit.vision.faceDetector();
    final inputImage = InputImage.fromFilePath(myFaceImageFile!.path);
    final detectedFaces = await faceDetector.processImage(inputImage);
    if (detectedFaces.isNotEmpty) {
      final currentImage = await _cameraController.takePicture();
      final currentInputImage = InputImage.fromFilePath(currentImage.path);
      final currentDetectedFaces = await faceDetector.processImage(currentInputImage);
      if (currentDetectedFaces.isNotEmpty) {
        final Face face1 = detectedFaces.first;
        final face2 = currentDetectedFaces.first;
        final simillar = calculateSimilarity(face1, face2);
        print("유사도는 $simillar");
        if (simillar > 0) {
          // Faces are considered a match
          showCompareSuccess('Faces matched');
          resultBool = true;
        } else {
          // Faces are not a match
          showCompareSuccess('Faces did not match');
        }
      }
    }
  }

  void showCompareSuccess(String result) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Result'),
          content: Text(result),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(result);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
  double calculateSimilarity(Face face1, Face face2) {
    // Calculate similarity based on different facial features
    double similarity = 0.0;

    // Calculate bounding box similarity
    double boundingBoxSimilarity = calculateBoundingBoxSimilarity(face1.boundingBox, face2.boundingBox);
    similarity += boundingBoxSimilarity;

    // Calculate head Euler angle similarity (if available)
    double eulerAngleSimilarity = calculateEulerAngleSimilarity(face1, face2);
    similarity += eulerAngleSimilarity;

    // Calculate similarity based on landmarks and contours
    double landmarkSimilarity = calculateLandmarkSimilarity(face1, face2);
    similarity += landmarkSimilarity;

    // Calculate overall similarity as an average
    similarity /= 5.0; // Adjust the divisor based on the number of features considered

    return similarity;
  }

  double calculateBoundingBoxSimilarity(Rect boundingBox1, Rect boundingBox2) {
    // Calculate the overlapping area of the bounding boxes
    final intersection = boundingBox1.intersect(boundingBox2);
    final intersectionArea = intersection.width * intersection.height;

    // Calculate the union area of the bounding boxes
    final unionArea = boundingBox1.width * boundingBox1.height +
        boundingBox2.width * boundingBox2.height -
        intersectionArea;

    // Calculate the similarity based on the intersection over union (IOU)
    final similarity = intersectionArea / unionArea;
    return similarity;
  }

  double calculateEulerAngleSimilarity(Face face1, Face face2) {
    // Calculate the absolute difference in Euler angles
    final angleXDiff = (face1.headEulerAngleX ?? 0.0) - (face2.headEulerAngleX ?? 0.0);
    final angleYDiff = (face1.headEulerAngleY ?? 0.0) - (face2.headEulerAngleY ?? 0.0);
    final angleZDiff = (face1.headEulerAngleZ ?? 0.0) - (face2.headEulerAngleZ ?? 0.0);

    // Calculate the overall similarity based on the absolute differences
    final similarity = 1.0 - (angleXDiff.abs() + angleYDiff.abs() + angleZDiff.abs()) / 3.0;
    return similarity;
  }

  double calculateEyeOpenProbabilitySimilarity(Face face1, Face face2) {
    // Calculate the absolute difference in eye open probabilities
    final eyeOpenProb1 = face1.leftEyeOpenProbability ?? 0.0;
    final eyeOpenProb2 = face2.leftEyeOpenProbability ?? 0.0;
    final eyeOpenProbDiff = (eyeOpenProb1 - eyeOpenProb2).abs();

    // Calculate the overall similarity based on the absolute difference
    final similarity = 1.0 - eyeOpenProbDiff;
    return similarity;
  }

  double calculateSmilingProbabilitySimilarity(Face face1, Face face2) {
    // Calculate the absolute difference in smiling probabilities
    final smilingProb1 = face1.smilingProbability ?? 0.0;
    final smilingProb2 = face2.smilingProbability ?? 0.0;
    final smilingProbDiff = (smilingProb1 - smilingProb2).abs();

    // Calculate the overall similarity based on the absolute difference
    final similarity = 1.0 - smilingProbDiff;
    return similarity;
  }

  double calculateLandmarkSimilarity(Face face1, Face face2) {
    // Calculate the average similarity based on landmarks
    double totalSimilarity = 0.0;
    int numLandmarks = 0;

    for (final landmarkType in FaceLandmarkType.values) {
      final landmark1 = face1.landmarks[landmarkType];
      final landmark2 = face2.landmarks[landmarkType];

      if (landmark1 != null && landmark2 != null) {
        final landmarkSimilarity = calculatePointSimilarity(landmark1.position, landmark2.position);
        totalSimilarity += landmarkSimilarity;
        numLandmarks++;
      }
    }

    // Calculate the average similarity based on the number of valid landmarks
    final landmarkSimilarity = totalSimilarity / max(1, numLandmarks);
    return landmarkSimilarity;
  }

  double calculatePointSimilarity(Point<int> point1, Point<int> point2) {
    // Calculate the Euclidean distance between the points
    final distance = sqrt(pow(point1.x - point2.x, 2) + pow(point1.y - point2.y, 2));

    // Calculate the similarity based on the inverse of the distance
    const maxDistance = 100.0; // Adjust this value based on the expected range of distances
    final similarity = 1.0 - (distance / maxDistance);
    return similarity;
  }
}
