import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:camera/camera.dart';
import 'package:camera_app/screens/qr_scanner_screen.dart';
import 'package:camera_app/screens/video_screen.dart';

import 'package:flutter/material.dart';

import 'package:gallery_saver/gallery_saver.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:syncfusion_flutter_sliders/sliders.dart';

class PhotoScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const PhotoScreen(this.cameras, {super.key});
  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  late CameraController controller;
  bool isCapturing = false;
  // for switch camera
  int _selectedCameraIndex = 0;
  bool _isFrontCamera = false;
  // for Flas
  bool _isFlashOn = false;
  // for focusing
  Offset? focusPoint;
  // for zoom
  double _zoom = 1.0;
  File? _capturedImage;
  // for Making Sound
  AssetsAudioPlayer? audioPlayer = AssetsAudioPlayer();

  @override
  void initState() {
    super.initState();
    controller = CameraController(widget.cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _toggleFlashLight() {
    if (_isFlashOn) {
      controller.setFlashMode(FlashMode.off);
      setState(() {
        _isFlashOn = false;
      });
    } else {
      controller.setFlashMode(FlashMode.torch);
      setState(() {
        _isFlashOn = true;
      });
    }
  }

  void _switchCamera() async {
    await controller.dispose();
    _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    _initCamera(_selectedCameraIndex);
  }

  Future<void> _initCamera(int cameraIndex) async {
    controller =
        CameraController(widget.cameras[cameraIndex], ResolutionPreset.max);
    try {
      await controller.initialize();
      setState(() {
        if (cameraIndex == 0) {
          _isFrontCamera = false;
        } else {
          _isFrontCamera = true;
        }
      });
    } catch (e) {
      print("error: $e");
    }
    if (mounted) {
      setState(() {});
    }
  }

  void capturePhoto() async {
    if (!controller.value.isInitialized) {
      return;
    }
    final Directory appDir =
        await pathProvider.getApplicationSupportDirectory();
    final String capturePath = path.join(appDir.path, '${DateTime.now()}.jpg');

    if (controller.value.isTakingPicture) {
      return;
    }
    try {
      setState(() {
        isCapturing = true;
      });
      final XFile capturedImage = await controller.takePicture();
      String imagePath = capturedImage.path;
      await GallerySaver.saveImage(imagePath);

      print("Photo Captured and saved to gallery");
      audioPlayer?.open(Audio("music/ses.mp3"));
      audioPlayer?.play();

      final String filePath =
          '$capturePath/${DateTime.now().millisecondsSinceEpoch}.jpg';
      _capturedImage = File(capturedImage.path);
      _capturedImage!.renameSync(filePath);
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        isCapturing = false;
      });
    }
  }

  void zoomCamera(double value) {
    setState(
      () {
        _zoom = value;
        controller.setZoomLevel(value);
      },
    );
  }

  Future<void> _setFocusPoint(Offset point) async {
    if (controller.value.isInitialized) {
      try {
        final double x = point.dx.clamp(0.0, 1.0);
        final double y = point.dy.clamp(0.0, 1.0);
        await controller.setFocusPoint(Offset(x, y));
        await controller.setFocusMode(FocusMode.auto);
        setState(() {
          focusPoint = Offset(x, y);
        });
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          focusPoint = null;
        });
      } catch (e) {
        print("error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: GestureDetector(
                            onTap: () {
                              _toggleFlashLight();
                            },
                            child: _isFlashOn == false
                                ? const Icon(Icons.flash_off,
                                    color: Colors.white)
                                : const Icon(Icons.flash_on,
                                    color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => QRScannerScreen(
                                      camera: widget.cameras.first),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  top: 50,
                  bottom: _isFrontCamera == false ? 0 : 150,
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: GestureDetector(
                      onTapDown: (TapDownDetails details) {
                        final Offset tapPosition = details.localPosition;
                        final Offset relativeTapPosition = Offset(
                            tapPosition.dx / constraints.maxWidth,
                            tapPosition.dy / constraints.maxHeight);
                        _setFocusPoint(relativeTapPosition);
                      },
                      child: CameraPreview(controller),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 10,
                  child: SfSlider.vertical(
                    max: 4,
                    min: 1,
                    activeColor: Colors.white,
                    value: _zoom,
                    onChanged: (dynamic value) {
                      setState(
                        () {
                          zoomCamera(value);
                        },
                      );
                    },
                  ),
                ),
                if (focusPoint != null)
                  Positioned.fill(
                    top: 50,
                    child: Align(
                      alignment: Alignment(
                          focusPoint!.dx * 2 - 1, focusPoint!.dy * 2 - 1),
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: _isFrontCamera == false
                          ? Colors.black45
                          : Colors.black,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (c) =>
                                            VideoScreen(widget.cameras),
                                      ),
                                    );
                                  },
                                  child: const Center(
                                    child: Text(
                                      "Video",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    "Photo",
                                    style: TextStyle(
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    "Pro Mode",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _capturedImage != null
                                            ? SizedBox(
                                                width: 50,
                                                height: 50,
                                                child: Image.file(
                                                    _capturedImage!,
                                                    fit: BoxFit.cover),
                                              )
                                            : Container(),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        capturePhoto();
                                      },
                                      child: Center(
                                        child: Container(
                                          height: 70,
                                          width: 70,
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            border: Border.all(
                                              width: 4,
                                              color: Colors.white,
                                              style: BorderStyle.solid,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        _switchCamera();
                                      },
                                      child: const Icon(
                                        Icons.cameraswitch_outlined,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
