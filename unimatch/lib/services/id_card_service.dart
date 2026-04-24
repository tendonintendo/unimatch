// lib/services/id_card_service.dart

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class CardDetectionResult {
  final bool detected;
  final double confidence;
  final Rect? boundingBox;

  const CardDetectionResult({
    required this.detected,
    required this.confidence,
    this.boundingBox,
  });
}

class _AnalyzeArgs {
  final CameraImage frame;
  final Rect crop;
  const _AnalyzeArgs(this.frame, this.crop);
}

class IDCardService {
  static const int _inferenceIntervalMs = 200;
  static const double _confidenceThreshold = 0.45;
  DateTime _lastInference = DateTime(0);

  IDCardService({String roboflowApiKey = ''});

  Future<CardDetectionResult> analyzeFrame(
    CameraImage frame, {
    required Rect overlayRect,
  }) async {
    final now = DateTime.now();
    if (now.difference(_lastInference).inMilliseconds < _inferenceIntervalMs) {
      return const CardDetectionResult(detected: false, confidence: 0);
    }
    _lastInference = now;

    try {
      return await compute(_analyzeContrast, _AnalyzeArgs(frame, overlayRect));
    } catch (e) {
      debugPrint('[IDCard] Analysis error: $e');
      return const CardDetectionResult(detected: false, confidence: 0);
    }
  }
  static CardDetectionResult _analyzeContrast(_AnalyzeArgs args) {
    final frame = args.frame;
    final crop = args.crop;

    final yPlane = frame.planes[0];
    final width = frame.width;
    final height = frame.height;

    final x0 = (crop.left * width).round().clamp(0, width - 1);
    final y0 = (crop.top * height).round().clamp(0, height - 1);
    final x1 = (crop.right * width).round().clamp(x0 + 1, width);
    final y1 = (crop.bottom * height).round().clamp(y0 + 1, height);

    const step = 4;
    int pixelCount = 0;
    int edgeCount = 0;
    double sumLuma = 0;
    double sumLumaSq = 0;

    for (int y = y0; y < y1 - step; y += step) {
      for (int x = x0; x < x1 - step; x += step) {
        final idx = y * yPlane.bytesPerRow + x;
        final luma = yPlane.bytes[idx].toDouble();

        sumLuma += luma;
        sumLumaSq += luma * luma;
        pixelCount++;

        final right = yPlane.bytes[idx + step].toDouble();
        final below = yPlane.bytes[(y + step) * yPlane.bytesPerRow + x].toDouble();
        final grad = (luma - right).abs() + (luma - below).abs();
        if (grad > 20) edgeCount++;
      }
    }

    if (pixelCount == 0) {
      return const CardDetectionResult(detected: false, confidence: 0);
    }

    final mean = sumLuma / pixelCount;
    // Fixed: actual standard deviation
    final variance = (sumLumaSq / pixelCount) - (mean * mean);
    final stdDev = variance > 0 ? variance.clamp(0, double.infinity) : 0.0;

    // Normalise stdDev: a blank wall ~5, a card ~30-60, max we care about ~80
    final contrastScore = (stdDev.clamp(0.0, 800.0) / 800.0);

    final edgeDensity = edgeCount / pixelCount;
    // Cards typically hit 0.15–0.35 edge density
    final edgeScore = (edgeDensity.clamp(0.0, 0.35) / 0.35);

    final score = (contrastScore * 0.4 + edgeScore * 0.6).clamp(0.0, 1.0);

    debugPrint('[IDCard] contrast=$contrastScore edge=$edgeScore score=$score');

    return CardDetectionResult(
      detected: score >= _confidenceThreshold,
      confidence: score,
    );
  }
}