// lib/screens/registration/id_card_camera_screen.dart
//
// Shows a live camera preview with a card-shaped overlay.
// When the YOLO model detects an ID card with sufficient confidence,
// it auto-captures, shows a confirmation, then uploads to Firebase Storage.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/id_card_service.dart';
import '../../services/storage_service.dart';

class IDCardCameraScreen extends StatefulWidget {
  final void Function(String uploadedUrl) onSuccess;
  final StorageService storageService;
  final String uid;
  const IDCardCameraScreen({
    super.key,
    required this.onSuccess,
    required this.storageService,
    required this.uid,
  });

  @override
  State<IDCardCameraScreen> createState() => _IDCardCameraScreenState();
}

class _IDCardCameraScreenState extends State<IDCardCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  late IDCardService _idService;
  CardDetectionResult _detection =
      const CardDetectionResult(detected: false, confidence: 0);
  bool _capturing = false;
  bool _uploading = false;
  Uint8List? _capturedBytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _idService = IDCardService(
      roboflowApiKey: const String.fromEnvironment('ROBOFLOW_KEY'),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }
      // Prefer back camera (better for ID scanning)
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(back, ResolutionPreset.high,
          enableAudio: false);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});

      _controller!.startImageStream(_onCameraFrame);
    } on CameraException catch (e) {
      setState(() => _error = 'Camera error: ${e.description ?? e.code}');
    } catch (_) {
      setState(() => _error = 'Unable to access the camera.');
    }
  }

  void _onCameraFrame(CameraImage frame) async {
    if (_capturing || _uploading) return;
    final result = await _idService.analyzeFrame(frame);
    if (!mounted) return;
    setState(() => _detection = result);

    // Auto-capture when confidence crosses threshold
    if (result.detected && result.confidence >= 0.75) {
      _autoCapture();
    }
  }

  Future<void> _autoCapture() async {
    if (_capturing || _uploading) return;
    setState(() => _capturing = true);
    await _controller?.stopImageStream();

    final xFile = await _controller?.takePicture();
    final bytes = await xFile?.readAsBytes();
    if (!mounted) return;
    setState(() {
      _capturedBytes = bytes;
      _capturing = false;
    });
  }

  Future<void> _uploadCapture() async {
    if (_capturedBytes == null) return;
    setState(() => _uploading = true);
    final url = await widget.storageService.uploadIdCard(widget.uid, _capturedBytes!);
    if (!mounted) return;
    widget.onSuccess(url);
  }
  void _retake() {
    setState(() {
      _capturedBytes = null;
      _detection = const CardDetectionResult(detected: false, confidence: 0);
    });
    _controller?.startImageStream(_onCameraFrame);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text(_error!,
            style: const TextStyle(color: Colors.red))),
      );
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Verify Your ID'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera or captured image
          if (_capturedBytes != null)
            Image.memory(_capturedBytes!, fit: BoxFit.cover)
          else
            CameraPreview(_controller!),

          // Card guide overlay
          _CardGuideOverlay(detected: _detection.detected),

          // Status badge
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: _StatusBadge(detection: _detection, uploading: _uploading),
          ),

          // Bottom actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomBar(
              captured: _capturedBytes != null,
              uploading: _uploading,
              onRetake: _retake,
              onConfirm: _uploadCapture,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardGuideOverlay extends StatelessWidget {
  final bool detected;
  const _CardGuideOverlay({required this.detected});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardW = size.width * 0.82;
    final cardH = cardW * 0.63; // CR-80 ratio
    return CustomPaint(
      size: Size(size.width, size.height),
      painter: _OverlayPainter(
        cardWidth: cardW,
        cardHeight: cardH,
        borderColor: detected ? Colors.greenAccent : Colors.white,
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double cardWidth;
  final double cardHeight;
  final Color borderColor;

  _OverlayPainter({
    required this.cardWidth,
    required this.cardHeight,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cardLeft = (size.width - cardWidth) / 2;
    final cardTop = (size.height - cardHeight) / 2 - 30;
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardLeft, cardTop, cardWidth, cardHeight),
      const Radius.circular(12),
    );

    // Dim the rest
    final dimPaint = Paint()..color = Colors.black54;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cardRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dimPaint);

    // Card border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(cardRect, borderPaint);
  }

  @override
  bool shouldRepaint(_OverlayPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}

class _StatusBadge extends StatelessWidget {
  final CardDetectionResult detection;
  final bool uploading;
  const _StatusBadge({required this.detection, required this.uploading});

  @override
  Widget build(BuildContext context) {
    if (uploading) {
      return _badge('Uploading…', Colors.blue.shade400, Icons.cloud_upload);
    }
    if (detection.detected) {
      return _badge(
              'ID card detected! Hold still…',
              Colors.green.shade400,
              Icons.check_circle_outline)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.04, duration: 600.ms);
    }
    return _badge(
        'Point camera at your ID card', Colors.white70, Icons.credit_card);
  }

  Widget _badge(String label, Color color, IconData icon) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
}

class _BottomBar extends StatelessWidget {
  final bool captured;
  final bool uploading;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;
  const _BottomBar(
      {required this.captured,
      required this.uploading,
      required this.onRetake,
      required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: captured
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          minimumSize: const Size(0, 50)),
                      onPressed: uploading ? null : onRetake,
                      icon: const Icon(Icons.replay),
                      label: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 50)),
                      onPressed: uploading ? null : onConfirm,
                      icon: uploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload),
                      label:
                          Text(uploading ? 'Uploading…' : 'Use this photo'),
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
