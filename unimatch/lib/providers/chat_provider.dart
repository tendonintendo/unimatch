// lib/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';
class ChatProvider extends ChangeNotifier {
  final ChatRepository _repo;
  final String _matchId;
  final String _myUid;

  List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  ChatProvider(this._repo, this._matchId, this._myUid) {
    _repo.watchMessages(_matchId).listen((msgs) {
      _messages = msgs;
      notifyListeners();
    });
    _repo.markRead(_matchId, _myUid);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    await _repo.send(matchId: _matchId, senderId: _myUid, text: text.trim());
  }
}