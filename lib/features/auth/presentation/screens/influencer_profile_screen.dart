// ─────────────────────────────────────────────────────────
//  influencer_profile_screen.dart
//  Full influencer profile — Elite vs Locked states
//
//  Navigate:
//    context.push(AppRoutes.influencerProfile
//      .replaceAll(':id', influencer.id))
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../di_injection/dependency_injection.dart';
import '../../../../routes/app_router.dart';
import '../../data/response_ml/register_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import 'elite_upgrade_sheet.dart';

class InfluencerProfileScreen extends StatefulWidget {
  const InfluencerProfileScreen({super.key, required this.influencerId});
  final String influencerId;

  @override
  State<InfluencerProfileScreen> createState() =>
      _InfluencerProfileScreenState();
}

class _InfluencerProfileScreenState
    extends State<InfluencerProfileScreen> {

  InfluencerProfile? _profile;
  bool               _loading  = true;
  bool               _matching = false;
  String?            _error;
  late AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = getIt<AuthRepository>();
    _load();
  }



Future<void> _load() async {
    try {
      final p = await _authRepository
          .getInfluencerProfile(widget.influencerId);
      if (!mounted) return;
      setState(() { _profile = p; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Could not load profile'; _loading = false; });
    }
  }

  Future<void> _match() async {
    final profile = _profile;
    if (profile == null) return;

    // Not elite → show upgrade sheet
    final user = context.read<AuthBloc>().state.user;
    if (user?.subscriptionPlan != 'elite') {
      _showUpgradeSheet();
      return;
    }

    // Session limit check
    if (!profile.canBook) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'You\'ve used all ${profile.influencerSessionLimit} sessions '
          'with ${profile.firstName} this month. Try next month!',
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _matching = true);
    try {
      final res = await _authRepository.swipeUser(
        targetId: profile.id,
        action:   'like',
      );
      if (!mounted) return;

      if (res['matched'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🎉 It\'s a match! Start chatting now.'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ));
        context.push(
          AppRoutes.chat.replaceAll(':chatId', res['matchId']),
          extra: {
            'buddyName':   profile.fullName,
            'buddyId':     profile.id,
            'buddyAvatar': profile.avatarUrl,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Request sent to ${profile.firstName}! Waiting for them to accept.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('ELITE_REQUIRED')) {
        _showUpgradeSheet();
      } else if (msg.contains('SESSION_LIMIT')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Monthly session limit reached for this influencer.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _matching = false);
    }
  }

  void _showUpgradeSheet() {
    if (_profile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EliteUpgradeSheet(influencer: _profile!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _buildProfile(),
    );
  }

  Widget _buildError() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: AppColors.textMuted, size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: AppTextStyles.body(color: AppColors.textMuted)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _load, child: const Text('Retry')),
    ]),
  );

  Widget _buildProfile() {
    final p       = _profile!;
    final isElite = context.read<AuthBloc>().state.user?.subscriptionPlan == 'elite';

    return CustomScrollView(
      slivers: [
        // ── App bar with cover ──────────────────────────────
        SliverAppBar(
          expandedHeight: 200,
          backgroundColor: AppColors.surface1,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left,
                color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Cover
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end:   Alignment.bottomCenter,
                      colors: [Color(0xFF141C2E), Color(0xFF07090F)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _coverEmoji(p.primaryActivity),
                      style: const TextStyle(fontSize: 72),
                    ),
                  ),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end:   Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.bg.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Column(
            children: [
              // ── Avatar ───────────────────────────────────
              Transform.translate(
                offset: const Offset(0, -30),
                child: Column(children: [
                  // Avatar circle
                  Container(
                    width:  72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFFF6B00)],
                        begin:  Alignment.topLeft,
                        end:    Alignment.bottomRight,
                      ),
                      border: Border.all(
                          color: AppColors.bg, width: 3),
                    ),
                    child: p.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(p.avatarUrl!,
                                fit: BoxFit.cover))
                        : Center(
                            child: Text(
                              p.firstName[0].toUpperCase(),
                              style: const TextStyle(
                                color:      Colors.white,
                                fontSize:   28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 8),

                  // Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(p.fullName,
                          style: AppTextStyles.h3()),
                      const SizedBox(width: 6),
                      const Text('⭐',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Instagram handle
                  if (p.instagramHandle != null)
                    Text(
                      '📸 @${p.instagramHandle} · ${p.followers} followers',
                      style: AppTextStyles.bodySM(
                          color: AppColors.textMuted),
                    ),

                  const SizedBox(height: 8),

                  // Verified badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      border: Border.all(
                          color:
                              const Color(0xFFF59E0B).withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      '✅ Verified Influencer',
                      style: TextStyle(
                        color:      Color(0xFFF59E0B),
                        fontSize:   12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 4),

              // ── Stats ─────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color:        AppColors.surface1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _Stat(p.followers,         'Followers'),
                    _Divider(),
                    _Stat('${p.totalSessions}','Sessions'),
                    _Divider(),
                    _Stat('${p.trustScore}★','Trust'),
                    _Divider(),
                    _Stat('Lv ${p.level}',     'Level'),
                  ],
                ),
              ),

              // ── Bio ───────────────────────────────────────
              if (p.influencerBio != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    p.influencerBio!,
                    style: AppTextStyles.body(
                        color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),

              // ── Session limit (Elite only) ────────────────
              if (isElite)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sessions this month',
                          style: AppTextStyles.bodySM(
                              color: AppColors.textMuted)),
                      Text(
                        '${p.sessionsUsed} / ${p.influencerSessionLimit} used · ${p.sessionsRemaining} left',
                        style: AppTextStyles.bodySM(
                                color: p.sessionsRemaining > 0
                                    ? AppColors.teal
                                    : AppColors.error)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),

              // ── Activity ──────────────────────────────────
              if (p.primaryActivity != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(children: [
                    Text(_coverEmoji(p.primaryActivity),
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      '${p.primaryActivity} · ${p.city ?? ''}',
                      style: AppTextStyles.body(
                          color: AppColors.textSecondary),
                    ),
                  ]),
                ),

              const SizedBox(height: 16),

              // ── CTA ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: isElite
                    ? _buildEliteCTA(p)
                    : _buildLockedCTA(p),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Elite user — match button
  Widget _buildEliteCTA(InfluencerProfile p) {
    final canBook = p.canBook;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_matching || !canBook) ? null : _match,
        style: ElevatedButton.styleFrom(
          backgroundColor: canBook ? AppColors.primary : AppColors.surface2,
          foregroundColor: Colors.white,
          padding:         const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: _matching
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(
                canBook
                    ? 'Match with ${p.firstName} →'
                    : 'Monthly limit reached · Try next month',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }

  // Non-elite user — locked CTA
  Widget _buildLockedCTA(InfluencerProfile p) => Column(
    children: [
      // Lock badge
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withOpacity(0.06),
          border: Border.all(
              color: const Color(0xFFF59E0B).withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          const Text('🔒 Match Locked',
              style: TextStyle(
                color:      Color(0xFFF59E0B),
                fontSize:   16,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 4),
          Text(
            'Upgrade to Elite to connect with\ntop fitness influencers',
            style: AppTextStyles.bodySM(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ]),
      ),

      const SizedBox(height: 12),

      // Upgrade button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _showUpgradeSheet,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.black,
            padding:         const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text(
            'Upgrade to Elite ₹599/mo',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ),

      const SizedBox(height: 10),

      // Next profile
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Next Profile →',
          style: AppTextStyles.body(color: AppColors.textMuted),
        ),
      ),
    ],
  );

  // Helpers
  Widget _Divider() => Container(
    width: 1, height: 36,
    color: AppColors.border,
  );

  String _coverEmoji(String? act) {
    const m = {
      'gym':'🏋️','running':'🏃','cycling':'🚴',
      'yoga':'🧘','boxing':'🥊','swimming':'🏊',
    };
    return m[act?.toLowerCase()] ?? '💪';
  }
}

// Stat widget
class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value,
          style: const TextStyle(
            color:      Colors.white,
            fontSize:   15,
            fontWeight: FontWeight.w800,
          )),
      const SizedBox(height: 3),
      Text(label,
          style: TextStyle(
            color:    Colors.white.withOpacity(0.35),
            fontSize: 10,
          )),
    ]),
  );
}
