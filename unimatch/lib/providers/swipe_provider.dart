// lib/providers/swipe_provider.dart
import '../models/match_model.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/swipe_repository.dart';
class SwipeProvider extends ChangeNotifier {
  final SwipeRepository _repo;
  final String _myUid;
  final UserRole _myRole;

  List<UserModel> _candidates = [];
  bool _loading = false;
  MatchModel? _latestMatch;

  List<UserModel> get candidates => _candidates;
  bool get loading => _loading;
  MatchModel? get latestMatch => _latestMatch;
  void clearLatestMatch() {
    _latestMatch = null;
    notifyListeners();
  }

  SwipeProvider(this._repo, this._myUid, this._myRole) {
    loadCandidates();
  }

  Future<void> loadCandidates() async {
    _loading = true;
    notifyListeners();
    final seekRole =
        _myRole == UserRole.student ? UserRole.tutor : UserRole.student;
    _candidates = await _repo.getCandidates(myUid: _myUid, seekingRole: seekRole);
    _loading = false;
    notifyListeners();
  }

  Future<void> swipe(String targetUid, SwipeDirection direction) async {
    final match = await _repo.swipe(
        myUid: _myUid, targetUid: targetUid, direction: direction);
    if (match != null) {
      _latestMatch = match;
    }
    _candidates.removeWhere((u) => u.uid == targetUid);
    notifyListeners();
    // Refill when running low
    if (_candidates.length < 3) loadCandidates();
  }
}