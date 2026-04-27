// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  final StorageService _storageService = StorageService();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;
  bool _loading = false;
  bool _suppressAuthStateRebuild = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get loading => _loading;

  AuthProvider(this._repo) {
    _repo.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> updateProfile({
    Uint8List? photoBytes,
    Uint8List? cvBytes,
    String? bio,
  }) async {
    final uid = _user?.uid;
    if (uid == null) return;

    final updates = <String, dynamic>{};

    if (photoBytes != null) {
      updates['photoUrl'] = await _storageService.uploadProfileImage(uid, photoBytes);
    }
    if (cvBytes != null) {
      updates['cvPdfUrl'] = await _storageService.uploadCvPdf(uid, cvBytes);
    }
    if (bio != null) updates['bio'] = bio;

    if (updates.isEmpty) return;

    await _repo.firestoreService.updateUser(uid, updates);
    _user = _user!.copyWith(
      photoUrl: updates['photoUrl'] as String?,
      cvPdfUrl: updates['cvPdfUrl'] as String?,
      bio: updates['bio'] as String?,
    );
    notifyListeners();
  }

  void _onAuthStateChanged(User? firebaseUser) async {
    if (_suppressAuthStateRebuild) return;
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      _status = AuthStatus.authenticated;
      _user = await _repo.firestoreService.getUser(firebaseUser.uid);
    }
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _repo.resetPassword(email);
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _repo.signIn(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpStudent({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    try {
      _user = await _repo.signUpStudent(
          email: email, password: password, name: name);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpTutor({
    required String email,
    required String password,
    required String name,
    required List<String> subjects,
    double? hourlyRate,
  }) async {
    _loading = true;
    notifyListeners();
    _suppressAuthStateRebuild = true;
    try {
      _user = await _repo.signUpTutor(
        email: email,
        password: password,
        name: name,
        subjects: subjects,
        hourlyRate: hourlyRate,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _suppressAuthStateRebuild = false;
      _error = _mapAuthError(e.code);
      notifyListeners();
      return false;
    } finally {
      _loading = false;
    }
  }

  Future<void> storeTutorIdCard(String uid, String idCardUrl) async {
    await _repo.firestoreService.updateUser(uid, {'idCardUrl': idCardUrl});
    if (_user != null) {
      _user = _user!.copyWith(idCardUrl: idCardUrl);
      notifyListeners();
    }
  }

  void completeSignUp() {
    _suppressAuthStateRebuild = false;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> signOut() => _repo.signOut();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  String _mapAuthError(String code) {
    return switch (code) {
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password.',
      'email-already-in-use' => 'An account already exists with this email.',
      'weak-password' => 'Password must be at least 6 characters.',
      'invalid-email' => 'Please enter a valid email address.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}