// ─────────────────────────────────────────────────────────
//  pending_strikes_screen.dart
//  List of unviewed Strike 2s
//  Navigate to: context.push(AppRoutes.pendingStrikes)
//  Usually opened from chat list badge or notification
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../di_injection/dependency_injection.dart';
import '../../../../routes/app_router.dart';
import '../../../auth/data/response_ml/register_response.dart';
import '../../data/repositories/strike_repository.dart';

class PendingStrikesScreen extends StatefulWidget {
  const PendingStrikesScreen({super.key});

  @override
  State<PendingStrikesScreen> createState() => _PendingStrikesScreenState();
}

class _PendingStrikesScreenState extends State<PendingStrikesScreen> {
  List<BuddyStrike> _pending  = [];
  List<BuddyStrike> _viewed   = [];
  bool              _loading  = true;
  late StrikeRepository strikeRepository;

  @override
  void initState() {
    super.initState();
    strikeRepository = getIt<StrikeRepository>();

    _load();
  }

  Future<void> _load() async {
    try {
      final strikes = await strikeRepository.getPendingStrikes();
      if (!mounted) return;
      setState(() {
        _pending = strikes.where((s) => !s.isViewed).toList();
        _viewed  = strikes.where((s) =>  s.isViewed).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openStrike(BuddyStrike strike) {
    context.push(
      AppRoutes.strikeView,
      extra: {
        'strike':    strike,
        'buddyName': strike.sender?['firstName'] as String? ?? 'Buddy',
        'streak':    strike.streak,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07090F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left,
              color: Colors.white54, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Strikes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: Colors.white.withOpacity(0.06)),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0A84FF)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF0A84FF),
              child: _buildList(),
            ),
    );
  }

  Widget _buildList() {
    if (_pending.isEmpty && _viewed.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_outlined, color: Colors.white12, size: 52),
            SizedBox(height: 12),
            Text('No strikes yet',
                style: TextStyle(color: Colors.white30, fontSize: 15)),
            SizedBox(height: 6),
            Text('Go to a chat and tap ⚡ to send one',
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (_pending.isNotEmpty) ...[
          _SectionHeader(
            label: 'PENDING',
            count: _pending.length,
          ),
          ..._pending.map((s) => _StrikeItem(
                strike:   s,
                isPending: true,
                onTap:    () => _openStrike(s),
              )),
        ],
        if (_viewed.isNotEmpty) ...[
          _SectionHeader(
            label: 'VIEWED TODAY',
            count: _viewed.length,
          ),
          ..._viewed.map((s) => _StrikeItem(
                strike:    s,
                isPending: false,
                onTap:     () {},
              )),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});
  final String label;
  final int    count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
    child: Text(
      '$label  $count',
      style: TextStyle(
        color: Colors.white.withOpacity(0.3),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: .5,
      ),
    ),
  );
}

// ── Strike list item ──────────────────────────────────────
class _StrikeItem extends StatelessWidget {
  const _StrikeItem({
    required this.strike,
    required this.isPending,
    required this.onTap,
  });

  final BuddyStrike strike;
  final bool        isPending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = strike.sender?['firstName'] as String? ?? 'Buddy';

    return GestureDetector(
      onTap: isPending ? onTap : null,
      child: Opacity(
        opacity: isPending ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              // Blue dot for pending
              if (isPending)
                Container(
                  width: 7, height: 7,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0A84FF),
                  ),
                )
              else
                const SizedBox(width: 17),

              // Avatar
              _Avatar(initial: name[0].toUpperCase()),
              const SizedBox(width: 10),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      isPending
                          ? 'Tap to view · disappears after'
                          : strike.reactEmoji != null
                              ? 'You reacted ${strike.reactEmoji}'
                              : 'Viewed',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Streak badge
              if (strike.streak > 0)
                Text(
                  '🔥${strike.streak}',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) => Container(
    width: 36, height: 36,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [Color(0xFF0A84FF), Color(0xFF00D0A3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          )),
    ),
  );
}
