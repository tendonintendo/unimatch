// lib/providers/match_provider.dart
import 'package:flutter/foundation.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
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
  bool _initialLoad = true;

  List<MatchModel> get matches => _matches;

  MatchProvider(this._repo, this._userRepo, this._myUid) {
    _repo.watchMatches(_myUid).listen((incoming) {
      if (!_initialLoad) {
        final existingIds = _matches.map((m) => m.id).toSet();
        final hasNew = incoming.any((m) => !existingIds.contains(m.id));
        if (hasNew) {
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
              channelKey: 'matches',
              title: 'New Match! 🎉',
              body: 'You have a new match. Say hello!',
            ),
          );
        }
      }
      _initialLoad = false;
      _matches = incoming;
      notifyListeners();
      _prefetchUsers(incoming);
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