// lib/services/storage_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class StorageService {
  Future<String> uploadIdCard(String uid, Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/id_card_$uid.jpg');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<String> uploadProfileImage(String uid, Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/profile_$uid.jpg');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}