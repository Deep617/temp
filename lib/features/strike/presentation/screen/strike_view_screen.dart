// ─────────────────────────────────────────────────────────
//  strike_view_screen.dart
//  Strike 2 — One-time view screen (Snap style)
//  Navigation:
//    - From chat screen: context.push(AppRoutes.strikeView, extra: strike)
//    - From notification: context.push(AppRoutes.strikeView, extra: strike)
//    - From pending list: context.push(AppRoutes.strikeView, extra: strike)
// ─────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di_injection/dependency_injection.dart';
import '../../../auth/data/response_ml/register_response.dart';
import '../../data/repositories/strike_repository.dart';

// ── Emoji reaction options ────────────────────────────────
const _kEmojis = [
  ('💪', 'Let\'s go!'),
  ('🔥', 'Fire!'),
  ('😤', 'Beast mode'),
  ('🏆', 'Goals!'),
  ('🤝', 'Same time tmrw?'),
  ('😮', 'Impressed!'),
];

class StrikeViewScreen extends StatefulWidget {
  const StrikeViewScreen({
    super.key,
    required this.strike,
    required this.buddyName,
    required this.streak,
  });

  final BuddyStrike strike;
  final String buddyName;
  final int streak;

  @override
  State<StrikeViewScreen> createState() => _StrikeViewScreenState();
}

class _StrikeViewScreenState extends State<StrikeViewScreen>
    with SingleTickerProviderStateMixin {
  // State
  BuddyStrike? _strike;
  bool _loading = true;
  bool _reacted = false;
  bool _disappeared = false;
  String? _selectedEmoji;
  int _secondsLeft = 0;
  Timer? _countdownTimer;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late StrikeRepository strikeRepository;

  @override
  void initState() {
    super.initState();
    strikeRepository = getIt<StrikeRepository>();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _viewStrike();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── View strike (one-time) ───────────────────────────────
  Future<void> _viewStrike() async {
    try {
      final viewed = await strikeRepository.viewStrike(widget.strike.id);
      if (!mounted) return;

      setState(() {
        _strike = viewed;
        _loading = false;
      });

      _fadeCtrl.forward();
      _startCountdown(viewed.expiresAt);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load strike';
        _loading = false;
      });
    }
  }

  // ── Countdown timer (5 min after view) ──────────────────
  void _startCountdown(DateTime expiresAt) {
    _updateSecondsLeft(expiresAt);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _countdownTimer?.cancel();
        return;
      }
      _updateSecondsLeft(expiresAt);
    });
  }

  void _updateSecondsLeft(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    if (diff <= 0) {
      _countdownTimer?.cancel();
      if (mounted) setState(() => _disappeared = true);
    } else {
      if (mounted) setState(() => _secondsLeft = diff);
    }
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ── React to strike ──────────────────────────────────────
  Future<void> _react(String emoji) async {
    if (_reacted || _disappeared) return;
    HapticFeedback.mediumImpact();
    setState(() => _selectedEmoji = emoji);

    try {
      await strikeRepository.reactToStrike(widget.strike.id, emoji);
      if (!mounted) return;
      setState(() => _reacted = true);

      // Auto-dismiss after showing reaction
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() => _disappeared = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _selectedEmoji = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not send reaction')));
    }
  }

  // ── UI ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      body: SafeArea(
        child: Column(
          children: [
            _buildNav(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // Nav bar — buddy name + streak
  Widget _buildNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.chevron_left,
              color: Colors.white54,
              size: 28,
            ),
          ),
          // Center
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.buddyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.streak > 0)
                  Text(
                    '🔥 ${widget.streak} day streak',
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          // Right placeholder
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_disappeared) return _buildDisappeared();
    return _buildStrikeContent();
  }

  // Loading
  Widget _buildLoading() =>
      const Center(child: CircularProgressIndicator(color: Color(0xFF0A84FF)));

  // Error
  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.white24, size: 48),
        const SizedBox(height: 12),
        Text(
          _error ?? 'Error',
          style: const TextStyle(color: Colors.white38, fontSize: 14),
        ),
      ],
    ),
  );

  // Disappeared state
  Widget _buildDisappeared() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.photo_camera_outlined,
          color: Colors.white24,
          size: 52,
        ),
        const SizedBox(height: 14),
        Text(
          _reacted
              ? '${_selectedEmoji ?? ''} Reaction sent!'
              : 'Strike disappeared',
          style: TextStyle(
            color: _reacted ? const Color(0xFF00D0A3) : Colors.white38,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'One-time view · gone forever',
          style: TextStyle(color: Colors.white24, fontSize: 12),
        ),
      ],
    ),
  );

  // Main strike content
  Widget _buildStrikeContent() {
    final strike = _strike ?? widget.strike;
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          // Strike image
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    _buildStrikeImage(strike.imageUrl),

                    // Top pills
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _TimerPill(label: _timerLabel),
                    ),
                    Positioned(top: 10, left: 10, child: _buildViewedPill()),

                    // Bottom overlay — sender info + caption
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildOverlay(strike),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Emoji reactions
          if (!_reacted) _buildEmojiRow() else _buildReactedState(),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStrikeImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        color: const Color(0xFF0A1225),
        child: const Icon(
          Icons.fitness_center,
          color: Colors.white24,
          size: 64,
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF0A1225),
        child: const Icon(
          Icons.broken_image_outlined,
          color: Colors.white24,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildViewedPill() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFF00D0A3).withOpacity(0.12),
      border: Border.all(color: const Color(0xFF00D0A3).withOpacity(0.3)),
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Text(
      'Viewed',
      style: TextStyle(
        color: Color(0xFF00D0A3),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _buildOverlay(BuddyStrike strike) => Container(
    padding: const EdgeInsets.fromLTRB(12, 32, 12, 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sender row
        Row(
          children: [
            _AvatarCircle(initials: widget.buddyName[0].toUpperCase()),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.buddyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Just now',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        // Caption
        if (strike.caption != null && strike.caption!.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            '"${strike.caption}"',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    ),
  );

  // Emoji row
  Widget _buildEmojiRow() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
    child: Column(
      children: [
        const Text(
          'REACT TO THIS STRIKE',
          style: TextStyle(
            color: Colors.white30,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _kEmojis.map((e) {
            final selected = _selectedEmoji == e.$1;
            return _EmojiButton(
              emoji: e.$1,
              tooltip: e.$2,
              selected: selected,
              onTap: () => _react(e.$1),
            );
          }).toList(),
        ),
      ],
    ),
  );

  // Reacted state
  Widget _buildReactedState() => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${_selectedEmoji ?? ''}', style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        const Text(
          'Reaction sent!',
          style: TextStyle(
            color: Color(0xFF00D0A3),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

// ── Sub-widgets ───────────────────────────────────────────

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.65),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [Color(0xFF0A84FF), Color(0xFF00D0A3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    required this.emoji,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? const Color(0xFFF59E0B).withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        border: Border.all(
          color: selected
              ? const Color(0xFFF59E0B).withOpacity(0.4)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
    ),
  );
}
