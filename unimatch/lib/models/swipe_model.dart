// lib/models/swipe_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum SwipeDirection { like, pass }

class SwipeModel {
  final String targetUid;
  final SwipeDirection direction;
  final DateTime swipedAt;

  const SwipeModel({
    required this.targetUid,
    required this.direction,
    required this.swipedAt,
  });

  Map<String, dynamic> toFirestore() => {
        'targetUid': targetUid,
        'direction': direction.name,
        'swipedAt': Timestamp.fromDate(swipedAt),
      };

  factory SwipeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SwipeModel(
      targetUid: doc.id,
      direction: data['direction'] == 'like' ? SwipeDirection.like : SwipeDirection.pass,
      swipedAt: (data['swipedAt'] as Timestamp).toDate(),
    );
  }
}
