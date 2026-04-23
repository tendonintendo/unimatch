// lib/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _fs;

  AuthRepository(this._fs);
  FirestoreService get firestoreService => _fs;
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> signUpStudent({
    required String email,
    required String password,
    required String name,
    GeoPoint? location,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
      role: UserRole.student,
      location: location,
      createdAt: DateTime.now(),
    );
    await _fs.createUser(user);
    return user;
  }

  Future<UserModel> signUpTutor({
    required String email,
    required String password,
    required String name,
    required List<String> subjects,
    double? hourlyRate,
    GeoPoint? location,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
      role: UserRole.tutor,
      subjects: subjects,
      hourlyRate: hourlyRate,
      location: location,
      createdAt: DateTime.now(),
    );
    await _fs.createUser(user);
    return user;
  }

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);
}
