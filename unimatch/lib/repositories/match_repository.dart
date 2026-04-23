import '../models/match_model.dart';
import '../services/firestore_service.dart';

class MatchRepository {
  final FirestoreService _fs;
  MatchRepository(this._fs);

  Stream<List<MatchModel>> watchMatches(String uid) =>
      _fs.watchMatches(uid);
}