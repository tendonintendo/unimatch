// lib/services/id_card_service.dart
//
// Primary strategy  : Roboflow YOLO model via REST API (no TFLite instability)
// Fallback strategy : Google ML Kit Document Scanner (scans & crops ID card)
//
// WHY REST OVER TFLite FOR THIS YOLO MODEL:
// The Roboflow-hosted model (id-card-detection-hl0ko/3) exposes a clean HTTPS
// inference endpoint.  TFLite integration for YOLOv8/v9 requires custom ops,
// post-processing (NMS), and anchor math that is fragile across Flutter versions.
// The REST approach is stable, always uses the latest weights, and removes the
// ~20 MB model binary from the APK.  In production with no internet, swap to
// ML Kit below.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/painting.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

// Detection result returned to the UI
class CardDetectionResult {
  final bool detected;
  final double confidence;   // 0.0–1.0
  final Rect? boundingBox;   // normalised (0–1)

  const CardDetectionResult({
    required this.detected,
    required this.confidence,
    this.boundingBox,
  });
}

class IDCardService {
  // ── Roboflow config ───────────────────────────────────────────────
  static const String _roboflowModel =
      'id-card-detection-hl0ko/3';
  static const String _roboflowBaseUrl =
      'https://detect.roboflow.com';
  // Store the API key in --dart-define=ROBOFLOW_KEY=xxx or a secrets manager
  final String _apiKey;

  // Detection tuning
  static const double _confidenceThreshold = 0.55;
  static const int _inferenceIntervalMs = 800; // throttle camera frames
  DateTime _lastInference = DateTime(0);

  IDCardService({required String roboflowApiKey})
      : _apiKey = roboflowApiKey;

  // ── Live-frame analysis (called from camera preview) ──────────────
  Future<CardDetectionResult> analyzeFrame(CameraImage frame) async {
    final now = DateTime.now();
    if (now.difference(_lastInference).inMilliseconds < _inferenceIntervalMs) {
      return const CardDetectionResult(detected: false, confidence: 0);
    }
    _lastInference = now;

    try {
      final jpeg = await _cameraImageToJpeg(frame);
      return await _inferViaRoboflow(jpeg);
    } catch (e) {
      debugPrint('[IDCard] Roboflow error: $e');
      return const CardDetectionResult(detected: false, confidence: 0);
    }
  }

  // ── Roboflow REST inference ───────────────────────────────────────
  Future<CardDetectionResult> _inferViaRoboflow(Uint8List jpeg) async {
    final base64Image = base64Encode(jpeg);

    final uri = Uri.parse(
        '$_roboflowBaseUrl/$_roboflowModel?api_key=$_apiKey'
        '&confidence=${(_confidenceThreshold * 100).toInt()}'
        '&overlap=30');

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: base64Image,
        )
        .timeout(const Duration(seconds: 4));

    if (response.statusCode != 200) {
      throw Exception('Roboflow HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final predictions =
        (json['predictions'] as List<dynamic>? ?? []);

    if (predictions.isEmpty) {
      return const CardDetectionResult(detected: false, confidence: 0);
    }

    // Take highest-confidence prediction
    final best = predictions
        .cast<Map<String, dynamic>>()
        .reduce((a, b) =>
            (a['confidence'] as double) > (b['confidence'] as double) ? a : b);

    final conf = (best['confidence'] as double);
    final imgWidth = (json['image']?['width'] as num?)?.toDouble() ?? 1.0;
    final imgHeight = (json['image']?['height'] as num?)?.toDouble() ?? 1.0;

    // Roboflow returns centre-x, centre-y, width, height
    final cx = (best['x'] as num).toDouble() / imgWidth;
    final cy = (best['y'] as num).toDouble() / imgHeight;
    final bw = (best['width'] as num).toDouble() / imgWidth;
    final bh = (best['height'] as num).toDouble() / imgHeight;

    return CardDetectionResult(
      detected: conf >= _confidenceThreshold,
      confidence: conf,
      boundingBox: Rect.fromLTWH(cx - bw / 2, cy - bh / 2, bw, bh),
    );
  }

  // ── Convert CameraImage (YUV420) to JPEG bytes ────────────────────
  static Future<Uint8List> _cameraImageToJpeg(CameraImage frame) async {
    // Run heavy conversion off the main isolate
    return compute(_convertYuv420ToJpeg, frame);
  }

  static Uint8List _convertYuv420ToJpeg(CameraImage frame) {
    final yPlane = frame.planes[0];
    final uPlane = frame.planes[1];
    final vPlane = frame.planes[2];

    final width = frame.width;
    final height = frame.height;
    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final uvIndex =
            (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uPlane.bytesPerPixel!;
        final yVal = yPlane.bytes[y * yPlane.bytesPerRow + x];
        final uVal = uPlane.bytes[uvIndex];
        final vVal = vPlane.bytes[uvIndex];

        final r = (yVal + 1.370705 * (vVal - 128)).clamp(0, 255).toInt();
        final g = (yVal - 0.698001 * (vVal - 128) - 0.337633 * (uVal - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yVal + 1.732446 * (uVal - 128)).clamp(0, 255).toInt();

        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    // Resize to 640×640 to match YOLO input and reduce upload size
    final resized = img.copyResize(image, width: 640, height: 640);
    return img.encodeJpg(resized, quality: 85);
  }
}

// ── FALLBACK: ML Kit Document Scanner ────────────────────────────────
// Use this when offline or if REST is unacceptable (data residency).
// Uncomment and replace IDCardService calls with MlKitIdScanner.
//
// import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
//
// class MlKitIdScanner {
//   final _scanner = DocumentScanner(
//     options: DocumentScannerOptions(
//       documentFormat: DocumentFormat.jpeg,
//       mode: ScannerMode.filter,
//       isGalleryImport: false,
//       pageLimit: 1,
//     ),
//   );
//
//   Future<String?> scan() async {
//     final result = await _scanner.startScan();
//     return result.images.firstOrNull?.uri; // local file path
//   }
//
//   void dispose() => _scanner.close();
// }
