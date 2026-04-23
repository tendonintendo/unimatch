// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collections ──────────────────────────────────────────────────
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _matches => _db.collection('matches');

  DocumentReference _userDoc(String uid) => _users.doc(uid);
  CollectionReference _swipes(String uid) =>
      _users.doc(uid).collection('swipes');
  CollectionReference _messages(String matchId) =>
      _matches.doc(matchId).collection('messages');

  // ─── User CRUD ────────────────────────────────────────────────────
  Future<void> createUser(UserModel user) =>
      _userDoc(user.uid).set(user.toFirestore());

  Future<void> updateUser(String uid, Map<String, dynamic> fields) =>
      _userDoc(uid).update(fields);

  Future<UserModel?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> watchUser(String uid) => _userDoc(uid)
      .snapshots()
      .map((s) => s.exists ? UserModel.fromFirestore(s) : null);

  // ─── Candidate Discovery ──────────────────────────────────────────
  /// Returns tutors (or students) the current user has NOT already swiped on.
  Future<List<UserModel>> fetchCandidates({
    required String myUid,
    required UserRole seekingRole,
    int limit = 20,
  }) async {
    // Get already-swiped UIDs to exclude
    final swipedDocs = await _swipes(myUid).get();
    final swipedUids = swipedDocs.docs.map((d) => d.id).toList();

    // Firestore whereNotIn supports up to 10 values; chunk if needed
    Query query = _users.where('role', isEqualTo: seekingRole.name).limit(limit);

    final snap = await query.get();
    return snap.docs
        .map((d) => UserModel.fromFirestore(d))
        .where((u) => u.uid != myUid && !swipedUids.contains(u.uid))
        .toList();
  }

  // ─── Atomic Matching Logic ────────────────────────────────────────
  /// Records a swipe AND checks for a mutual match in one transaction.
  /// Returns the MatchModel if a new match was created, null otherwise.
  Future<MatchModel?> recordSwipeAndCheckMatch({
    required String myUid,
    required String targetUid,
    required SwipeDirection direction,
  }) async {
    final swipeRef = _swipes(myUid).doc(targetUid);
    final matchId = MatchModel.generateId(myUid, targetUid);
    final matchRef = _matches.doc(matchId);

    // Write own swipe first (no transaction needed for a single write)
    await swipeRef.set({
      'targetUid': targetUid,
      'direction': direction.name,
      'swipedAt': FieldValue.serverTimestamp(),
    });

    if (direction != SwipeDirection.like) return null;

    // Now read their swipe — allowed because auth.uid == targetUid (the path's {targetUid})
    final theirSwipe = await _swipes(targetUid).doc(myUid).get();
    final theyLikedMe = theirSwipe.exists &&
        (theirSwipe.data() as Map)['direction'] == 'like';

    if (!theyLikedMe) return null;

    // Check + create match atomically
    return await _db.runTransaction((tx) async {
      final existingMatch = await tx.get(matchRef);
      if (existingMatch.exists) return null;

      final newMatch = MatchModel(
        id: matchId,
        participantIds: [myUid, targetUid],
        createdAt: DateTime.now(),
      );
      tx.set(matchRef, newMatch.toFirestore());
      return newMatch;
    });
  }
// ─── Matches ──────────────────────────────────────────────────────
  Stream<List<MatchModel>> watchMatches(String uid) => _matches
    .where('participantIds', arrayContains: uid)
    .orderBy('createdAt', descending: true) // use a field that always exists
    .snapshots()
    .map((s) => s.docs.map((d) => MatchModel.fromFirestore(d)).toList());

  // ─── Messages ─────────────────────────────────────────────────────
  Stream<List<MessageModel>> watchMessages(String matchId) => _messages(matchId)
      .orderBy('sentAt', descending: false)
      .snapshots()
      .map((s) => s.docs.map((d) => MessageModel.fromFirestore(d)).toList());

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
  }) async {
    final batch = _db.batch();
    final msgRef = _messages(matchId).doc();

    batch.set(msgRef, {
      'senderId': senderId,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    // Denormalize last message onto match doc for efficient list view
    batch.update(_matches.doc(matchId), {
      'lastMessageText': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
    });

    await batch.commit();
  }

  Future<void> markMessagesRead(String matchId, String readerUid) =>
      _messages(matchId)
          .where('senderId', isNotEqualTo: readerUid)
          .where('read', isEqualTo: false)
          .get()
          .then((snap) {
        final batch = _db.batch();
        for (final doc in snap.docs) {
          batch.update(doc.reference, {'read': true});
        }
        return batch.commit();
      });
}
