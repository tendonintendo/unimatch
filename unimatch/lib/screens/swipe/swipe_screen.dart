// lib/screens/swipe/swipe_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/user_model.dart';
import '../../models/match_model.dart';
import '../../providers/swipe_provider.dart';
import 'match_popup.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController _controller = CardSwiperController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SwipeProvider>(builder: (ctx, prov, _) {
      if (prov.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (prov.candidates.isEmpty) {
        return _EmptyState(onRefresh: prov.loadCandidates);
      }

      // Show match popup when a new match arrives
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (prov.latestMatch != null) {
          _showMatchPopup(context, prov.latestMatch!);
          prov.clearLatestMatch();
        }
      });

      return Stack(
        children: [
          CardSwiper(
            controller: _controller,
            cardsCount: prov.candidates.length,
            numberOfCardsDisplayed:
                prov.candidates.length < 3 ? prov.candidates.length : 3,
            backCardOffset: const Offset(0, -20),
            scale: 0.92,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
            onSwipe: (prev, current, direction) {
              final target = prov.candidates[prev];
              final swipeDir = direction == CardSwiperDirection.right
                  ? SwipeDirection.like
                  : SwipeDirection.pass;
              prov.swipe(target.uid, swipeDir);
              return true;
            },
            cardBuilder: (ctx, index, pct, pct2) {
              if (index >= prov.candidates.length) return const SizedBox();
              return _TutorCard(user: prov.candidates[index]);
            },
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: _ActionRow(
              onPass: () => _controller.swipe(CardSwiperDirection.left),
              onLike: () => _controller.swipe(CardSwiperDirection.right),
            ),
          ),
        ],
      );
    });
  }

  void _showMatchPopup(BuildContext context, MatchModel match) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => MatchPopup(match: match),
    );
  }
}

class _TutorCard extends StatelessWidget {
  final UserModel user;
  const _TutorCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            if (user.photoUrl != null)
              CachedNetworkImage(
                imageUrl: user.photoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: theme.colorScheme.surfaceVariant),
                errorWidget: (_, __, ___) => _PlaceholderAvatar(name: user.name),
              )
            else
              _PlaceholderAvatar(name: user.name),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Info overlay
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (user.idVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Verified',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (user.bio != null)
                    Text(
                      user.bio!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final s in user.subjects.take(4))
                        _SubjectChip(label: s),
                      if (user.hourlyRate != null)
                        _SubjectChip(
                          label: '\$${user.hourlyRate!.toStringAsFixed(0)}/hr',
                          color: Colors.amber.shade700,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0);
  }
}

class _SubjectChip extends StatelessWidget {
  final String label;
  final Color? color;
  const _SubjectChip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: (color ?? Colors.white).withOpacity(0.5), width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onPass;
  final VoidCallback onLike;
  const _ActionRow({required this.onPass, required this.onLike});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          onTap: onPass,
          icon: Icons.close_rounded,
          color: Colors.red.shade400,
          size: 56,
        ),
        const SizedBox(width: 40),
        _ActionButton(
          onTap: onLike,
          icon: Icons.check_rounded,
          color: Colors.green.shade400,
          size: 64,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final double size;
  const _ActionButton(
      {required this.onTap,
      required this.icon,
      required this.color,
      required this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  final String name;
  const _PlaceholderAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No more profiles nearby',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Check back soon!',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
