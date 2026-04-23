// lib/services/storage_service.dart
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadIdCard(String uid, Uint8List bytes) async {
    final ref = _storage.ref().child('id_cards/$uid.jpg');
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  Future<String> uploadProfileImage(String uid, Uint8List bytes) async {
    final ref = _storage.ref().child('profile_images/$uid.jpg');
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }
}