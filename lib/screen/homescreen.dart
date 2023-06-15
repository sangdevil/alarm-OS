import 'package:flutter/material.dart';
import 'package:video_call/screen/camscreen.dart';
import 'package:video_call/screen/comparescreen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool faceCorrect = false;
  bool faceRegistered = false;
  String myFace_base64 = "";

  void registerpop() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (BuildContext context) {
        return CamRegister(
          faceRegistered: faceRegistered,
        );
      }),
    );
    if (result != null) {
      myFace_base64 = result;
      faceRegistered = true;
    }
  }

  void comparepop() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (BuildContext context) {
        return CamCompare(
          myFace: myFace_base64,
        );
      }),
    );
    faceCorrect = true;
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
              child: _Logo(myFace: myFace_base64),
            ),
            Expanded(
              child: _Image(),
            ),
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                registerButton(onPressed: registerpop),
                compareButton(
                  onPressed: comparepop,
                  abled: faceRegistered,
                )
              ],
            ))
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatefulWidget {
  final String myFace;

  const _Logo({required this.myFace, Key? key}) : super(key: key);

  @override
  _LogoState createState() => _LogoState();
}

class _LogoState extends State<_Logo> {
  late final String myFace;
  bool isWaitingForResponse = false;
  bool isAlarmActive = false;

  @override
  void initState() {
    myFace = widget.myFace;
    super.initState();
  }

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

  void onPressed() async {
    setState(() {
      isWaitingForResponse = true;
    });

    while (isWaitingForResponse) {
      // Communicate with the server every 5 seconds and check for a response
      await Future.delayed(const Duration(seconds: 5));

      // Make an HTTP request to the server and check the response
      // Replace this with your actual HTTP request code
      bool isResponseStrange = await checkServerResponse();
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

  Future<bool> checkServerResponse() async {
    // Perform the HTTP request to check the server response
    // Replace this with your actual HTTP request code
    // Return true if the response is strange, false otherwise
    return true;
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
        return CamCompare(myFace: myFace);
      }),
    );

    // Check if the user is the original user
    if (result == true) {
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

class registerButton extends StatelessWidget {
  late final VoidCallback onPressed;

  registerButton({required this.onPressed, Key? key}) : super(key: key);

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

class compareButton extends StatelessWidget {
  late final VoidCallback onPressed;
  late final bool abled;

  compareButton({required this.onPressed, required this.abled, Key? key})
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
