import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

class CamRegister extends StatefulWidget {
  final bool faceRegistered;

  const CamRegister({required this.faceRegistered, Key? key}) : super(key: key);

  @override
  _CamRegisterState createState() => _CamRegisterState();
}

class _CamRegisterState extends State<CamRegister> {
  late CameraController _cameraController;
  late Future<void> _cameraInitFuture;
  bool faceRegistered = false;

  late XFile? myFaceImageFile;

  @override
  void initState() {
    faceRegistered = widget.faceRegistered;
    super.initState();
    _cameraInit();
  }

  Future<void> _cameraInit() async {
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
        title: Text('얼굴 등록'),
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
                  onPressed: faceRegister,
                  child: Text(
                    '얼굴 등록',
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

  //
  // void faceRegister() async {
  //   String url = 'http://example.com/not_yet/create-human';
  //
  //   XFile imageFile; // Variable to store the captured image file
  //
  //   try {
  //     // Capture a photo
  //     imageFile = await _cameraController.takePicture();
  //
  //     // Convert the image file to base64 string
  //     List<int> imageBytes = await imageFile.readAsBytes();
  //     String base64Image = base64Encode(imageBytes);
  //
  //     // Prepare the request body
  //     Map<String, String> headers = {'Content-Type': 'application/json'};
  //     Map<String, dynamic> body = {'image': base64Image};
  //
  //     // Send the HTTP request
  //     http.Response response = await http.post(
  //       Uri.parse(url),
  //       headers: headers,
  //       body: jsonEncode(body),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       // Response received successfully
  //       Map<String, dynamic> responseData = jsonDecode(response.body);
  //       String result = responseData['result'];
  //       myFace_base64 = base64Image;
  //       faceRegistered = true;
  //       showRegisterSuccess(result);
  //     } else {
  //       // Request failed
  //       // TODO: Handle the error
  //     }
  //   } catch (error) {
  //     // Error occurred during the request
  //     // TODO: Handle the error
  //   }
  // }

  void faceRegister() async {
    XFile imageFile; // Variable to store the captured image file

    // Capture a photo
    imageFile = await _cameraController.takePicture();
    myFaceImageFile = imageFile;
    if (myFaceImageFile != null) {
      showRegisterSuccess("얼굴 등록 완료");
    }
  }

  void showRegisterSuccess(String result) {
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
                Navigator.of(context).pop(myFaceImageFile); // Return to the home screen
                // TODO: Additional actions if needed
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
