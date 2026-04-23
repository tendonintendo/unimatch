// lib/screens/matches/matches_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_provider.dart';

import '../chat/chat_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: Consumer<MatchProvider>(builder: (ctx, prov, _) {
        final myUid = ctx.read<AuthProvider>().user!.uid;
        final matches = prov.matches;
        if (matches.isEmpty) {
          return const _EmptyMatches();
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: matches.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
          itemBuilder: (_, i) {
            final match = matches[i];
            final otherUid = match.otherUserId(myUid);
            final otherUser = prov.cachedUser(otherUid);
            return _MatchTile(
              match: match,
              otherUser: otherUser,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(matchId: match.id)),
              ),
            );
          },
        );
      }),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final MatchModel match;
  final UserModel? otherUser;
  final VoidCallback onTap;
  const _MatchTile(
      {required this.match, required this.otherUser, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = otherUser?.name ?? '…';
    final lastMsg = match.lastMessageText ?? 'Say hello! 👋';
    final timeStr = match.lastMessageAt != null
        ? DateFormat.jm().format(match.lastMessageAt!)
        : '';

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: _Avatar(user: otherUser),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        lastMsg,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(timeStr,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final UserModel? user;
  const _Avatar({this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: const CircleAvatar(radius: 26),
      );
    }
    if (user!.photoUrl != null) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: CachedNetworkImageProvider(user!.photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 26,
      child: Text(user!.name[0].toUpperCase()),
    );
  }
}

class _EmptyMatches extends StatelessWidget {
  const _EmptyMatches();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No matches yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Keep swiping to find your perfect tutor!',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}