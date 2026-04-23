// lib/repositories/swipe_repository.dart
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class SwipeRepository {
  final FirestoreService _fs;
  SwipeRepository(this._fs);

  Future<MatchModel?> swipe({
    required String myUid,
    required String targetUid,
    required SwipeDirection direction,
  }) =>
      _fs.recordSwipeAndCheckMatch(
          myUid: myUid, targetUid: targetUid, direction: direction);

  Future<List<UserModel>> getCandidates({
    required String myUid,
    required UserRole seekingRole,
  }) =>
      _fs.fetchCandidates(myUid: myUid, seekingRole: seekingRole);
}