import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:geolocator/geolocator.dart';

import 'report_details_page.dart'; // Ensure this exists and is correctly implemented

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? _cameras;
  CameraDescription? _currentCamera;
  bool _isFlashOn = false;
  bool _isLoadingLocation = false;  // To track if location is being fetched

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      _currentCamera = _cameras!.first;
      await _setupCamera(_currentCamera!);
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _setupCamera(CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    final newCamera = _cameras!.firstWhere(
          (camera) => camera != _currentCamera,
      orElse: () => _cameras!.first,
    );
    _currentCamera = newCamera;
    _setupCamera(_currentCamera!);
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    _isFlashOn = !_isFlashOn;
    await _cameraController!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  Future<Position> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;  // Start loading location
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _isLoadingLocation = false;  // Stop loading location
    });

    return position;
  }

  Future<void> _captureImage() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) return;
      await _initializeControllerFuture;

      final image = await _cameraController!.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final savedPath = join(directory.path, '${DateTime.now()}.jpg');
      final savedImage = await File(image.path).copy(savedPath);

      final position = await _getCurrentLocation();

      if (!mounted) return;
      Navigator.push(
        this.context,  // Correct use of context
        MaterialPageRoute(
          builder: (BuildContext context) => ReportDetailsPage(
            imagePath: savedImage.path,
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now(),
          ),
        ),
      );
    } catch (e) {
      print('Capture error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: (_initializeControllerFuture == null)
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder(
          future: _initializeControllerFuture,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                _cameraController != null &&
                _cameraController!.value.isInitialized) {
              return Stack(
                children: [
                  SizedBox.expand(
                    child: CameraPreview(_cameraController!),
                  ),
                  Container(color: Colors.black.withOpacity(0.2)),
                  Center(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: LensFramePainter(),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _captureImage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey.shade800,
                              width: 4,
                            ),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 20,
                    child: IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.switch_camera, color: Colors.white, size: 30),
                      onPressed: _switchCamera,
                    ),
                  ),
                  // Show loading indicator while fetching location
                  if (_isLoadingLocation)
                    Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                ],
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

class LensFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double frameWidth = size.width * 0.7;
    final double frameHeight = size.height * 0.3;
    final double left = (size.width - frameWidth) / 2;
    final double top = (size.height - frameHeight) / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, frameWidth, frameHeight),
      const Radius.circular(20),
    );

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
