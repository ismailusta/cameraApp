import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QRScannerScreen extends StatefulWidget {
  final CameraDescription camera;
  const QRScannerScreen({required this.camera});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  CameraController? _cameraController;
  QRViewController? _qrviewController;

  final GlobalKey qrKey = GlobalKey(debugLabel: "QR");
  bool isCameraInitialized = false;
  bool isCameraPermissionGranted = false;
  @override
  void initState() {
    super.initState();
    requestCameraPermission();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _qrviewController?.dispose();

    super.dispose();
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      isCameraPermissionGranted = status.isGranted;
    });
    if (status.isGranted) {
      _initializeCamera();
    }
  }

  void _initializeCamera() {
    availableCameras().then(
      (cameras) {
        print('Available cameras: $cameras');
        final rearCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
        print("Selected camera: $rearCamera");
        _cameraController = CameraController(rearCamera, ResolutionPreset.max);
        _cameraController!.initialize().then(
          (value) {
            if (!mounted) {
              return;
            }
            setState(
              () {
                isCameraInitialized = true;
              },
            );
          },
        );
      },
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _qrviewController = controller;
    });
    _qrviewController!.scannedDataStream.listen(
      (scanData) async {
        if (await canLaunch(scanData.code!)) {
          await launch(scanData.code!);
        } else {
          print("Couldn't launch ${scanData.code}");
        }
      },
    );
    _qrviewController!.toggleFlash();
    _setCameraFocusMode(FocusMode.auto);
    _cameraController!.startImageStream(
      (CameraImage cameraImage) {
        if (_qrviewController != null) {
          final qrCode = _decodeQRCode(cameraImage);
          if (qrCode != null) {
            _qrviewController!.pauseCamera();
            print(qrCode);
          }
        }
      },
    );
  }

  Future<void> _setCameraFocusMode(FocusMode focusMode) async {
    final currentFocusMode = _cameraController!.value.focusMode;
    if (currentFocusMode == focusMode) {
      return;
    }
    await _cameraController!.setFocusMode(focusMode);
  }

  String? _decodeQRCode(CameraImage cameraImage) {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          centerTitle: true,
          title: const Text("QR Scanner"),
          actions: const [
            Text(""),
          ],
          leading: const Text(""),
        ),
        body: Column(
          children: [
            Expanded(
              child: isCameraInitialized
                  ? QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                      overlay: QrScannerOverlayShape(
                        borderRadius: 10,
                        borderColor: Colors.white,
                        borderLength: 30,
                        borderWidth: 10,
                        cutOutSize: 300,
                      ),
                    )
                  : Container(),
            )
          ],
        ),
      ),
    );
  }
}
