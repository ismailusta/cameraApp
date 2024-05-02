import 'package:camera/camera.dart';
import 'package:camera_app/screens/photo_screen.dart';
import 'package:flutter/material.dart';

List<CameraDescription> cameras = [];
Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Framelerin hazır oldugnu kontrol edip başlatır.
  cameras =
      await availableCameras(); // kullanılabilir kameraları yukardakki listeye doldur.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter Demo",
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: PhotoScreen(cameras),
    );
  }
}
