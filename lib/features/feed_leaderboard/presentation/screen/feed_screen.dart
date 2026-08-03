// ─────────────────────────────────────────────────────────
//  feed_screen.dart
//  Global 24hr ephemeral challenge feed
//  Share to social media with #Seshlly tag
//  Group photo support
//  Post-session "Share to feed?" prompt
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';
import '../../../../di_injection/dependency_injection.dart';
import '../../../../routes/app_router.dart';
import '../../../auth/data/response_ml/register_response.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../dashboard/challanges/data/repositories/challenge_repository.dart';
import '../../../dashboard/challanges/data/response_ml/challange_model.dart';
import '../../../dashboard/session/data/response_ml/workout_session.dart';



class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<ChallengeFeedPost> _posts  = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final challengeRepository = getIt<ChallengeRepository>();
      final posts = await challengeRepository.getGlobalFeed();
      if (mounted) setState(() {
        _posts   = posts.where((p) => !p.isExpired).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: Column(children: [

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Challenge Feed', style: AppTextStyles.h2()),
                Text('Posts disappear after 24 hours ⚡',
                    style: AppTextStyles.bodySM(color: AppColors.textMuted)),
              ],
            )),
            // Live indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:        AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(99),
                border:       Border.all(
                    color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text('LIVE',
                    style: AppTextStyles.label(color: AppColors.error)
                        .copyWith(fontSize: 9)),
              ]),
            ),
          ]),
        ),

        // Feed list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
                  color: AppColors.primary))
              : _posts.isEmpty
                  ? _EmptyFeed()
                  : RefreshIndicator(
                      color:     AppColors.primary,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: _posts.length,
                        itemBuilder: (_, i) => _FeedCard(
                          post: _posts[i],
                          me:   context.read<AuthBloc>().state.user,
                        ).animate(
                          delay: Duration(milliseconds: i * 60),
                        ).fadeIn().slideY(begin: 0.1),
                      ),
                    ),
        ),
      ]),
    ),
  );
}

// ── Empty Feed ─────────────────────────────────────────────
class _EmptyFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🏋️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('No posts yet today',
            style: AppTextStyles.h3()),
        const SizedBox(height: 8),
        Text('Complete a challenge station to be first!',
            style: AppTextStyles.bodySM(
                color: AppColors.textMuted),
            textAlign: TextAlign.center),
      ],
    ),
  );
}

// ── Feed Card ──────────────────────────────────────────────
class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.post, required this.me});
  final ChallengeFeedPost post;
  final UserModel?        me;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color:        AppColors.surface1,
      borderRadius: BorderRadius.circular(16),
      border:       Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── Header row ─────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Row(children: [
          // Avatar or group avatar
          GestureDetector(
            onTap: post.userId == me?.id
                ? null
                : () => context.push(
                    AppRoutes.buddyProfile
                        .replaceAll(':userId', post.userId)),
            child: AppAvatar(
              name:     post.displayName,
              imageUrl: post.avatarUrl,
              size:     38,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: GestureDetector(
                    onTap: post.userId == me?.id
                        ? null
                        : () => context.push(
                            AppRoutes.buddyProfile
                                .replaceAll(':userId', post.userId)),
                    child: Text(
                      post.groupName != null
                          ? post.groupName!
                          : post.displayName,
                      style: AppTextStyles.bodySM(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (post.userId == me?.id) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color:        AppColors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: AppColors.teal.withOpacity(0.3)),
                    ),
                    child: Text('You',
                        style: AppTextStyles.label(
                            color: AppColors.teal)
                            .copyWith(fontSize: 9)),
                  ),
                ],
              ]),
              Row(children: [
                if (post.city != null) ...[
                  const Icon(Icons.location_on,
                      size: 10, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Text(post.city!,
                      style: AppTextStyles.caption()
                          .copyWith(fontSize: 10)),
                  const SizedBox(width: 8),
                ],
                Text(_timeAgo(post.postedAt),
                    style: AppTextStyles.caption()),
              ]),
            ],
          )),
          // Time left badge
          _TimeLeftBadge(post: post),
        ]),
      ),

      const SizedBox(height: 10),

      // ── Challenge tag ──────────────────────────────────
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:        AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚡', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                post.challengeTitle != null
                    ? '${post.challengeTitle} • Station ${post.stationNum}'
                    : post.stationTitle,
                style: AppTextStyles.bodySM(color: AppColors.primary)
                    .copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text('+${post.xpAwarded} XP',
                style: AppTextStyles.label(color: AppColors.warning)),
          ]),
        ),
      ),

      // ── Caption ────────────────────────────────────────
      if (post.caption != null && post.caption!.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Text(post.caption!,
              style: AppTextStyles.body()),
        ),
      ],

      // ── Collab indicator ───────────────────────────────
      if (post.isCollab && post.collabUserName != null) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Row(children: [
            AppAvatar(
              name:     post.collabUserName!,
              imageUrl: post.collabAvatarUrl,
              size:     20,
            ),
            const SizedBox(width: 6),
            Text('with ${post.collabUserName}',
                style: AppTextStyles.bodySM(
                    color: AppColors.textMuted)),
          ]),
        ),
      ],

      // ── Photo ──────────────────────────────────────────
      if (post.groupPhotoUrl != null || post.proofImageUrl != null) ...[
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _showFullImage(context,
              post.groupPhotoUrl ?? post.proofImageUrl!),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15)),
            child: Image.network(
              post.groupPhotoUrl ?? post.proofImageUrl!,
              width:    double.infinity,
              height:   220,
              fit:      BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color:  AppColors.surface2,
                child: const Center(
                  child: Icon(Icons.image_not_supported,
                      color: AppColors.textMuted),
                ),
              ),
            ),
          ),
        ),
      ] else ...[
        const SizedBox(height: 14),
      ],

      // ── Actions ────────────────────────────────────────
      if (post.groupPhotoUrl == null && post.proofImageUrl == null)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: _ShareButton(post: post),
        )
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: _ShareButton(post: post),
        ),
    ]),
  );

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

// ── Time left badge ────────────────────────────────────────
class _TimeLeftBadge extends StatelessWidget {
  const _TimeLeftBadge({required this.post});
  final ChallengeFeedPost post;

  Color get _color {
    final h = post.timeLeft.inHours;
    if (h < 2)  return AppColors.error;
    if (h < 6)  return AppColors.warning;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color:        _color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border:       Border.all(color: _color.withOpacity(0.3)),
    ),
    child: Text(
      post.timeLeftLabel,
      style: AppTextStyles.label(color: _color).copyWith(fontSize: 9),
    ),
  );
}

// ── Share button ───────────────────────────────────────────
class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.post});
  final ChallengeFeedPost post;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _share(),
    child: Row(children: [
      const Icon(Icons.share_outlined,
          size: 16, color: AppColors.textMuted),
      const SizedBox(width: 6),
      Text('Share',
          style: AppTextStyles.bodySM(color: AppColors.textMuted)
              .copyWith(fontWeight: FontWeight.w600)),
    ]),
  );

  void _share() {
    final text = StringBuffer();
    text.write('🏆 Just completed "${post.stationTitle}"');
    if (post.challengeTitle != null) {
      text.write(' in the ${post.challengeTitle} challenge');
    }
    text.write(' and earned +${post.xpAwarded} XP! 💪\n\n');
    if (post.caption != null && post.caption!.isNotEmpty) {
      text.write('${post.caption}\n\n');
    }
    text.write('#Seshlly #FitnessChallenge #TrainTogether');

    Share.share(
      text.toString(),
      subject: 'Seshlly Challenge Complete! 🏆',
    );
  }
}

