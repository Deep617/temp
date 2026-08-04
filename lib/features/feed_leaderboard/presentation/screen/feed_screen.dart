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
      final posts = await getIt<ChallengeRepository>().getGlobalFeed();
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

// ══════════════════════════════════════════════════════════
//  POST-SESSION FEED PROMPT
//  Show this dialog after session proof upload
//  Usage: showPostToFeedPrompt(context, session, challengeEntry)
// ══════════════════════════════════════════════════════════
Future<void> showPostToFeedPrompt(
    BuildContext context, {
      required WorkoutSession session,
      String?     challengeTitle,
      String?     challengeId,
      int         stationNum   = 0,
      String      stationTitle = 'Session Complete',
      int         xpAwarded    = 50,
      bool        isGroup      = false,
    }) async {
  if (!context.mounted) return;

  final result = await showModalBottomSheet<bool>(
    context:         context,
    backgroundColor: AppColors.surface1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PostToFeedSheet(
      session:        session,
      challengeTitle: challengeTitle,
      challengeId:    challengeId,
      stationNum:     stationNum,
      stationTitle:   stationTitle,
      xpAwarded:      xpAwarded,
      isGroup:        isGroup,
    ),
  );

  // result = true means user tapped "Post"
  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Posted to challenge feed! 🎉'),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

class _PostToFeedSheet extends StatefulWidget {
  const _PostToFeedSheet({
    required this.session,
    required this.stationTitle,
    required this.xpAwarded,
    required this.isGroup,
    this.challengeTitle,
    this.challengeId,
    this.stationNum = 0,
  });
  final WorkoutSession session;
  final String?        challengeTitle;
  final String?        challengeId;
  final int            stationNum;
  final String         stationTitle;
  final int            xpAwarded;
  final bool           isGroup;

  @override
  State<_PostToFeedSheet> createState() => _PostToFeedSheetState();
}

class _PostToFeedSheetState extends State<_PostToFeedSheet> {
  final _captionCtrl = TextEditingController();
  bool _posting = false;

  @override
  void dispose() { _captionCtrl.dispose(); super.dispose(); }

  Future<void> _post() async {
    setState(() => _posting = true);
    try {
      final api = getIt<ChallengeRepository>();
      await api.postToFeed({
        'challengeId':   widget.challengeId ?? widget.session.id,
        'stationNum':    widget.stationNum,
        'stationTitle':  widget.stationTitle,
        'xpAwarded':     widget.xpAwarded,
        'proofImageUrl': widget.session.proofImageUrl,
        'isCollab':      widget.session.buddyId != null,
        'caption':       _captionCtrl.text.trim().isEmpty
            ? null
            : _captionCtrl.text.trim(),
        if (widget.session.buddyId != null) ...{
          'collabUserId': widget.session.buddyId,
        },
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() => _posting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to post. Try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 20, right: 20, top: 20,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 36, height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.border2,
          borderRadius: BorderRadius.circular(2),
        ),
      ),

      // Trophy animation
      const Text('🏆', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 8),
      Text('Share to Feed?', style: AppTextStyles.h3()),
      const SizedBox(height: 6),
      Text(
        'Your achievement disappears after 24 hours',
        style: AppTextStyles.bodySM(color: AppColors.textMuted),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),

      // Proof photo thumbnail — auto-attached from upload
      if (widget.session.proofImageUrl != null) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            widget.session.proofImageUrl!,
            width:  double.infinity,
            height: 140,
            fit:    BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 140,
              decoration: BoxDecoration(
                color:        AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.image_not_supported,
                    color: AppColors.textMuted, size: 32),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],

      // Challenge info preview
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: AppColors.border2),
        ),
        child: Row(children: [
          const Text('⚡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.challengeTitle != null
                    ? '${widget.challengeTitle} • ${widget.stationTitle}'
                    : widget.stationTitle,
                style: AppTextStyles.bodySM(),
              ),
              Text('+${widget.xpAwarded} XP earned',
                  style: AppTextStyles.bodySM(
                      color: AppColors.warning)),
            ],
          )),
          // Photo attached indicator
          if (widget.session.proofImageUrl != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color:        AppColors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.teal.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.image,
                    color: AppColors.teal, size: 11),
                const SizedBox(width: 3),
                Text('Photo',
                    style: AppTextStyles.label(
                        color: AppColors.teal)
                        .copyWith(fontSize: 9)),
              ]),
            ),
        ]),
      ),

      const SizedBox(height: 12),

      // Caption field
      TextField(
        controller:    _captionCtrl,
        style:         AppTextStyles.body(),
        maxLines:      2,
        maxLength:     140,
        decoration: InputDecoration(
          hintText:    'Add a caption (optional)...',
          hintStyle:   AppTextStyles.bodySM(color: AppColors.textMuted),
          filled:      true,
          fillColor:   AppColors.surface2,
          counterStyle: AppTextStyles.caption(),
          border:      OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:   BorderSide.none,
          ),
        ),
      ),

      const SizedBox(height: 16),

      // Buttons
      Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: Text('Skip',
                style: AppTextStyles.btn(color: AppColors.textMuted)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _posting ? null : _post,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: _posting
                ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : Text('Post to Feed 🔥',
                style: AppTextStyles.btn()),
          ),
        ),
      ]),
    ]),
  );
}



