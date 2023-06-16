import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_call/screen/camscreen.dart';
import 'package:video_call/screen/comparescreen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:math';

final stt.SpeechToText speechToText = stt.SpeechToText();

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool faceCorrect = false;
  bool faceRegistered = false;
  XFile? myFaceImageFile;

  void registerpop() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (BuildContext context) {
        return CamRegister(
          faceRegistered: faceRegistered,
        );
      }),
    );
    if (result != null) {
      print("not null");
      setState(() {
        myFaceImageFile = result;
        faceRegistered = true;
      });
    }
  }

  void comparepop() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (BuildContext context) {
        return CamCompare(
          myFaceImageFile: myFaceImageFile,
        );
      }),
    );
    if (result != null) {
      setState(() {
        faceCorrect = true;
        FlutterRingtonePlayer.stop();
      });
    }
  }

  Future<void> permissionInit() async {
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
  void initState() {
    super.initState();
    permissionInit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: _Logo(myFaceImageFile: myFaceImageFile),
            ),
            Expanded(
              child: _Image(),
            ),
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RegisterButton(onPressed: registerpop),
                CompareButton(
                  onPressed: comparepop,
                  abled: faceRegistered,
                ),
              ],
            ))
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatefulWidget {
  late XFile? myFaceImageFile;

  _Logo({required this.myFaceImageFile, Key? key}) : super(key: key);

  @override
  _LogoState createState() => _LogoState();
}

class _LogoState extends State<_Logo> {
  late XFile? myFaceImageFile;
  bool isWaitingForResponse = false;
  bool isAlarmActive = false;

  @override
  void initState() {
    super.initState();
    myFaceImageFile = widget.myFaceImageFile;
  }

  @override
  Widget build(BuildContext context) {
    print(myFaceImageFile);
    return StartButton(
      isWaitingForResponse: isWaitingForResponse,
      onPressed: onPressed,
    );
  }

  void onPressed() async {
    setState(() {
      isWaitingForResponse = true;
    });

    while (isWaitingForResponse) {
      // Communicate with the server every 5 seconds and check for a response
      await Future.delayed(const Duration(seconds: 5));

      // Make an HTTP request to the server and check the response
      // Replace this with your actual HTTP request code
      bool isResponseStrange = await checkSoundResponse();
      print(isResponseStrange);
      if (isResponseStrange) {
        setState(() {
          isAlarmActive = true;
        });

        // Start the phone alarm
        // Replace this with your actual code to start the alarm
        startPhoneAlarm();

        // Exit the loop and stop waiting for the response
        break;
      }
    }

    // Reset the button state
    setState(() {
      isWaitingForResponse = false;
    });

    // If the response is not strange, navigate to CamCompare screen
    if (!isAlarmActive) {
      navigateToCamCompare();
    }
  }

  Future<bool> checkSoundResponse() async {
    bool isSpecificWordFound =
        false; // Variable to track if the specific word is found

    if (await speechToText.initialize()) {
      // Create a Completer to handle the result asynchronously
      Completer<bool> completer = Completer<bool>();

      speechToText.listen(
        onResult: (result) {
          final String recognizedSpeech = result.recognizedWords.toLowerCase();
          print(result);
          if (recognizedSpeech.contains('게임')) {
            isSpecificWordFound = true; // Set the variable to true
          }
        },
        onSoundLevelChange: (level) {
          // Optional: Handle sound level changes if needed
        },
        listenFor: Duration(seconds: 5), // Listen for 5 seconds
      );

      // Wait for the result or timeout after 5 seconds
      await Future.delayed(Duration(seconds: 5));
      completer.complete(
          isSpecificWordFound); // Complete the completer with the result

      // Stop listening after the timeout
      speechToText.stop();
      // Return the result from the Completer
      return await completer.future;
    }
    return false;
  }

  void startPhoneAlarm() {
    // Code to start the phone alarm
    // Replace this with your actual code to start the alarm
    FlutterRingtonePlayer.playAlarm(
      looping: true, // Set to true for continuous playback
      asAlarm: true, // Play as an alarm sound
      volume: 1.0, // Set the volume (0.0 to 1.0)
    );
  }

  void navigateToCamCompare() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (BuildContext context) {
        return CamCompare(
          myFaceImageFile: myFaceImageFile,
        );
      }),
    );

    // Check if the user is the original user
    if (result == 'Faces matched') {
      // Stop the phone alarm
      // Replace this with your actual code to stop the alarm
      stopPhoneAlarm();
    }
  }

  void stopPhoneAlarm() {
    // Code to stop the phone alarm
    // Replace this with your actual code to stop the alarm
    FlutterRingtonePlayer.stop();
  }
}

class _Image extends StatelessWidget {
  const _Image({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset('asset/img/home_img.png'),
    );
  }
}

class RegisterButton extends StatelessWidget {
  late final VoidCallback onPressed;

  RegisterButton({required this.onPressed, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(onPressed: onPressed, child: Text("얼굴 등록")),
      ],
    );
  }
}

class CompareButton extends StatelessWidget {
  late final VoidCallback onPressed;
  late final bool abled;

  CompareButton({required this.onPressed, required this.abled, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
            onPressed: abled ? onPressed : null, child: Text("얼굴 인식")),
      ],
    );
  }
}

class StartButton extends StatelessWidget {
  final bool isWaitingForResponse;
  final VoidCallback onPressed;

  const StartButton(
      {required this.isWaitingForResponse, required this.onPressed, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        style: ButtonStyle(
          fixedSize: MaterialStateProperty.all<Size>(Size(240, 80)),
          // Set the desired size
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20.0), // Set the desired border radius
            ),
          ),
        ),
        onPressed: isWaitingForResponse ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, color: Colors.white, size: 40.0),
            SizedBox(width: 12.0),
            Text(
              '측정시작',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30.0,
                letterSpacing: 4.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
