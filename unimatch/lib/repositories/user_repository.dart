// lib/repositories/user_repository.dart
import '../models/user_model.dart';
import '../services/firestore_service.dart';
class UserRepository {
  final FirestoreService _fs;
  UserRepository(this._fs);

  Stream<UserModel?> watchUser(String uid) => _fs.watchUser(uid);

  Future<UserModel?> getUser(String uid) => _fs.getUser(uid);

  Future<void> updateProfile(String uid, Map<String, dynamic> fields) =>
      _fs.updateUser(uid, fields);
}