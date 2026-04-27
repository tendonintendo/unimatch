// lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../repositories/chat_repository.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  const ChatScreen({super.key, required this.matchId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AuthProvider>().user!.uid;

    return ChangeNotifierProvider(
      create: (ctx) => ChatProvider(
        ctx.read<ChatRepository>(),
        widget.matchId,
        myUid,
      ),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: const _ChatAppBarTitle(),
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: _MessageList(
                myUid: myUid,
                scrollController: _scroll,
              ),
            ),
            _InputBar(
              controller: _input,
              onAfterSend: _scrollToBottom,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatAppBarTitle extends StatelessWidget {
  const _ChatAppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20)),
        const SizedBox(width: 10),
        Text('Chat', style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  final String myUid;
  final ScrollController scrollController;
  const _MessageList({required this.myUid, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(builder: (ctx, prov, _) {
      final msgs = prov.messages;
      if (msgs.isEmpty) {
        return const Center(
          child: Text('Say hello! 👋', style: TextStyle(color: Colors.grey)),
        );
      }
      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: msgs.length,
        itemBuilder: (_, i) {
          final msg = msgs[i];
          final isMe = msg.senderId == myUid;
          return _MessageBubble(
              text: msg.text, isMe: isMe, time: msg.sentAt);
        },
      );
    });
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime time;
  const _MessageBubble(
      {required this.text, required this.isMe, required this.time});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: isMe
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? theme.colorScheme.onPrimary.withOpacity(0.6)
                        : theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAfterSend;
  const _InputBar({required this.controller, required this.onAfterSend});

  void _send(BuildContext context, String text) {
    if (text.trim().isEmpty) return;
    controller.clear();
    context.read<ChatProvider>().sendMessage(text).then((_) => onAfterSend());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (text) => _send(context, text),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _send(context, controller.text),
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}