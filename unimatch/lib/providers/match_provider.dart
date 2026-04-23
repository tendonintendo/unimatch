// lib/providers/match_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../repositories/user_repository.dart';
import '../repositories/match_repository.dart';
class MatchProvider extends ChangeNotifier {
  final MatchRepository _repo;
  final UserRepository _userRepo;
  final String _myUid;

  List<MatchModel> _matches = [];
  final Map<String, UserModel> _userCache = {};

  List<MatchModel> get matches => _matches;

  MatchProvider(this._repo, this._userRepo, this._myUid) {
    _repo.watchMatches(_myUid).listen((m) {
      _matches = m;
      notifyListeners();
      _prefetchUsers(m);
    });
  }

  void _prefetchUsers(List<MatchModel> matches) async {
    for (final m in matches) {
      final other = m.otherUserId(_myUid);
      if (!_userCache.containsKey(other)) {
        final u = await _userRepo.getUser(other);
        if (u != null) _userCache[other] = u;
      }
    }
    notifyListeners();
  }

  UserModel? cachedUser(String uid) => _userCache[uid];
}