// lib/services/geo_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class GeoService {
  /// Requests permission and returns current GeoPoint, or null on failure.
  static Future<GeoPoint?> getCurrentLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) return null;

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium);
    return GeoPoint(pos.latitude, pos.longitude);
  }

  /// Returns distance in km between two GeoPoints using the Haversine formula.
  static double distanceKm(GeoPoint a, GeoPoint b) {
    const earthR = 6371.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);
    final x = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(a.latitude)) *
            cos(_toRad(b.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return 2 * earthR * atan2(sqrt(x), sqrt(1 - x));
  }

  static double _toRad(double deg) => deg * pi / 180;
}