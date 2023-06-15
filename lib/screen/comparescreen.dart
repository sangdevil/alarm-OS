import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

class CamCompare extends StatefulWidget {
  bool faceCorrect = false;
  late final String myFace = "";

  CamCompare({required myFace, Key? key}) : super(key: key);

  @override
  _CamCompareState createState() => _CamCompareState();
}

class _CamCompareState extends State<CamCompare> {
  late final String myFace;
  late CameraController _cameraController;
  late Future<void> _cameraInitFuture;

  @override
  void initState() {
    super.initState();
    _cameraInit();
  }

  Future<void> _cameraInit() async {
    myFace = widget.myFace;
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
    String url = 'http://example.com/not_yet/compare-human';

    // TODO: 이미지 파일을 가져와서 Base64로 변환
    XFile currentImage;

    try {
      currentImage = await _cameraController.takePicture();
      List<int> imageBytes = await currentImage.readAsBytes();
      String currentFace = base64Encode(imageBytes);
      Map<String, String> headers = {'Content-Type': 'application/json'};
      Map<String, dynamic> body = {
        'img1': currentFace, // 첫 번째 이미지를 Base64로 변환한 문자열로 변경
        'img2': myFace, // 두 번째 이미지를 Base64로 변환한 문자열로 변경
      };
      http.Response response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // 응답이 성공적으로 수신된 경우
        Map<String, dynamic> responseData = jsonDecode(response.body);
        String result = responseData['result'];
        showCompareSuccess(result);
      } else {
        // 응답이 실패한 경우
        // TODO: 오류 처리
      }
    } catch (error) {
      // HTTP 요청이 실패한 경우
      // TODO: 오류 처리
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
                Navigator.pop(true as BuildContext); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
