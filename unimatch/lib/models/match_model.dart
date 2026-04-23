// lib/models/match_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
enum SwipeDirection { like, pass }

class MatchModel {
  final String id;
  final List<String> participantIds;
  final DateTime createdAt;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;

  const MatchModel({
    required this.id,
    required this.participantIds,
    required this.createdAt,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastMessageSenderId,
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastMessageText: data['lastMessageText'],
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: data['lastMessageSenderId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'participantIds': participantIds,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastMessageText': lastMessageText,
        'lastMessageAt':
            lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
        'lastMessageSenderId': lastMessageSenderId,
      };

  /// Deterministic match ID — always sorted so both users compute the same ID
  static String generateId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  String otherUserId(String myUid) =>
      participantIds.firstWhere((id) => id != myUid);
}
