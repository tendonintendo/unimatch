// lib/repositories/chat_repository.dart
import '../models/message_model.dart';
import '../services/firestore_service.dart';
class ChatRepository {
  final FirestoreService _fs;
  ChatRepository(this._fs);

  Stream<List<MessageModel>> watchMessages(String matchId) =>
      _fs.watchMessages(matchId);

  Future<void> send({
    required String matchId,
    required String senderId,
    required String text,
  }) =>
      _fs.sendMessage(matchId: matchId, senderId: senderId, text: text);

  Future<void> markRead(String matchId, String uid) =>
      _fs.markMessagesRead(matchId, uid);
}