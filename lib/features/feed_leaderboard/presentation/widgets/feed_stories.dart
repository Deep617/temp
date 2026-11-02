// ─────────────────────────────────────────────────────────
//  feed_stories.dart — Challenge Feed as Stories (IG / Snap style)
//
//  • FeedStoryRow    → horizontal avatars (coloured ring = unseen)
//  • StoryViewerScreen → full screen, progress bars, 5s per slide,
//                       tap left/right, hold to pause, swipe down to close
//  • StorySeenStore  → "seen" state saved on the phone (v1, no backend)
//
//  Data: GET /feed (posts already expire after 24h on the server).
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';
import '../../../../di_injection/dependency_injection.dart';
import '../../../../routes/app_router.dart';
import '../../../dashboard/challanges/data/repositories/challenge_repository.dart';
import '../../../dashboard/challanges/data/response_ml/challange_model.dart';

// ══════════════════════════════════════════════════════════
//  Model — one user's stories
// ══════════════════════════════════════════════════════════
class StoryGroup {
  StoryGroup({required this.userId, required this.posts});

  final String userId;
  final List<ChallengeFeedPost> posts; // oldest → newest (story order)

  String get name => posts.last.displayName;
  String? get avatarUrl => posts.last.avatarUrl;
  DateTime get latest => posts.last.postedAt;

  bool allSeen(Set<String> seen) => posts.every((p) => seen.contains(p.id));

  /// First unseen slide (or 0 if all seen)
  int firstUnseen(Set<String> seen) {
    final i = posts.indexWhere((p) => !seen.contains(p.id));
    return i < 0 ? 0 : i;
  }

  /// Group posts by user; unseen users first, then newest first
  static List<StoryGroup> fromPosts(
    List<ChallengeFeedPost> posts,
    Set<String> seen,
  ) {
    final map = <String, List<ChallengeFeedPost>>{};
    for (final p in posts.where((p) => !p.isExpired)) {
      map.putIfAbsent(p.userId, () => []).add(p);
    }
    final groups = map.entries.map((e) {
      e.value.sort((a, b) => a.postedAt.compareTo(b.postedAt));
      return StoryGroup(userId: e.key, posts: e.value);
    }).toList();
    groups.sort((a, b) {
      final sa = a.allSeen(seen), sb = b.allSeen(seen);
      if (sa != sb) return sa ? 1 : -1;
      return b.latest.compareTo(a.latest);
    });
    return groups;
  }
}

// ══════════════════════════════════════════════════════════
//  Seen store — SharedPreferences, auto-prunes expired ids
// ══════════════════════════════════════════════════════════
class StorySeenStore {
  static const _key = 'feed_story_seen'; // "postId|expiresAtMillis"

  static Future<Set<String>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final raw = prefs.getStringList(_key) ?? const [];
      final alive = raw.where((e) {
        final parts = e.split('|');
        return parts.length == 2 && (int.tryParse(parts[1]) ?? 0) > now;
      }).toList();
      if (alive.length != raw.length) await prefs.setStringList(_key, alive);
      return alive.map((e) => e.split('|').first).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> markSeen(ChallengeFeedPost post) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key) ?? <String>[];
      if (list.any((e) => e.startsWith('${post.id}|'))) return;
      list.add('${post.id}|${post.expiresAt.millisecondsSinceEpoch}');
      await prefs.setStringList(_key, list);
    } catch (_) {}
  }
}

// ══════════════════════════════════════════════════════════
//  FeedStoryRow — used on Challenges screen + Feed screen
// ══════════════════════════════════════════════════════════
class FeedStoryRow extends StatefulWidget {
  const FeedStoryRow({super.key, this.showFeedButton = true});

  /// "Feed" tile at the start → opens the full feed list
  final bool showFeedButton;

  @override
  State<FeedStoryRow> createState() => _FeedStoryRowState();
}

class _FeedStoryRowState extends State<FeedStoryRow> {
  List<StoryGroup> _groups = const [];
  Set<String> _seen = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        getIt<ChallengeRepository>().getGlobalFeed(),
        StorySeenStore.load(),
      ]);
      final posts = results[0] as List<ChallengeFeedPost>;
      final seen = results[1] as Set<String>;
      if (!mounted) return;
      setState(() {
        _seen = seen;
        _groups = StoryGroup.fromPosts(posts, seen);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(int index) async {
    await context.push(
      AppRoutes.storyViewer,
      extra: {'groups': _groups, 'index': index},
    );
    // Refresh rings after viewing
    final seen = await StorySeenStore.load();
    if (mounted) setState(() => _seen = seen);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 96);
    if (_groups.isEmpty && !widget.showFeedButton) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: [
          if (widget.showFeedButton)
            _StoryTile(
              label: 'Feed',
              onTap: () => context.push(AppRoutes.feed),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface2,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.dynamic_feed_rounded,
                    color: AppColors.primary, size: 24),
              ),
            ),
          if (_groups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 18),
              child: Text(
                'No stories yet —\ncomplete a challenge to post the first one 💪',
                style: AppTextStyles.caption(),
              ),
            ),
          for (var i = 0; i < _groups.length; i++)
            _StoryTile(
              label: _groups[i].name.split(' ').first,
              seen: _groups[i].allSeen(_seen),
              onTap: () => _open(i),
              child: AppAvatar(
                name: _groups[i].name,
                imageUrl: _groups[i].avatarUrl,
                size: 56,
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({
    required this.label,
    required this.onTap,
    required this.child,
    this.seen = true,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;
  final bool seen;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: seen ? null : AppColors.primaryGradientDiag,
                border: seen
                    ? Border.all(color: AppColors.border2, width: 1.5)
                    : null,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.bg,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(child: SizedBox.expand(child: child)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(
                color: seen ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  StoryViewerScreen — full screen
// ══════════════════════════════════════════════════════════
class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.groups,
    this.initialIndex = 0,
  });

  final List<StoryGroup> groups;
  final int initialIndex;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _slideDuration = Duration(seconds: 5);

  late final PageController _pages;
  late final AnimationController _progress;
  late int _group;
  int _slide = 0;
  Set<String> _seen = {};
  double _dragDy = 0;

  StoryGroup get _current => widget.groups[_group];
  ChallengeFeedPost get _post => _current.posts[_slide];

  @override
  void initState() {
    super.initState();
    _group = widget.initialIndex.clamp(0, widget.groups.length - 1);
    _pages = PageController(initialPage: _group);
    _progress = AnimationController(vsync: this, duration: _slideDuration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _next();
      });
    StorySeenStore.load().then((seen) {
      if (!mounted) return;
      _seen = seen;
      setState(() => _slide = _current.firstUnseen(seen));
      _startSlide();
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _startSlide() {
    StorySeenStore.markSeen(_post);
    _seen.add(_post.id);
    // Preload next image for a smooth tap-through
    final nextUrl = _slide + 1 < _current.posts.length
        ? _imageOf(_current.posts[_slide + 1])
        : null;
    if (nextUrl != null) precacheImage(NetworkImage(nextUrl), context);
    _progress
      ..reset()
      ..forward();
  }

  void _next() {
    if (_slide + 1 < _current.posts.length) {
      setState(() => _slide++);
      _startSlide();
    } else if (_group + 1 < widget.groups.length) {
      _pages.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _close();
    }
  }

  void _prev() {
    if (_slide > 0) {
      setState(() => _slide--);
      _startSlide();
    } else if (_group > 0) {
      _pages.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _startSlide(); // restart first slide
    }
  }

  void _onGroupChanged(int i) {
    setState(() {
      _group = i;
      _slide = _current.firstUnseen(_seen);
    });
    _startSlide();
  }

  void _close() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  static String? _imageOf(ChallengeFeedPost p) =>
      p.proofImageUrl ?? p.groupPhotoUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Swipe down to close
        onVerticalDragUpdate: (d) =>
            setState(() => _dragDy = (_dragDy + d.delta.dy).clamp(0.0, 400.0)),
        onVerticalDragEnd: (d) {
          if (_dragDy > 120 || (d.primaryVelocity ?? 0) > 700) {
            _close();
          } else {
            setState(() => _dragDy = 0);
          }
        },
        child: Transform.translate(
          offset: Offset(0, _dragDy),
          child: Opacity(
            opacity: (1 - _dragDy / 600).clamp(0.4, 1.0),
            child: PageView.builder(
              controller: _pages,
              itemCount: widget.groups.length,
              onPageChanged: _onGroupChanged,
              itemBuilder: (_, gi) {
                final group = widget.groups[gi];
                final isActive = gi == _group;
                final slide = isActive
                    ? _slide.clamp(0, group.posts.length - 1)
                    : group.firstUnseen(_seen);
                return _StoryPage(
                  group: group,
                  slide: slide,
                  progress: isActive ? _progress : null,
                  onTapLeft: _prev,
                  onTapRight: _next,
                  onHold: () => _progress.stop(),
                  onRelease: () => _progress.forward(),
                  onClose: _close,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  const _StoryPage({
    required this.group,
    required this.slide,
    required this.progress,
    required this.onTapLeft,
    required this.onTapRight,
    required this.onHold,
    required this.onRelease,
    required this.onClose,
  });

  final StoryGroup group;
  final int slide;
  final AnimationController? progress;
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;
  final VoidCallback onHold;
  final VoidCallback onRelease;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final post = group.posts[slide];
    final image = post.proofImageUrl ?? post.groupPhotoUrl;
    final width = MediaQuery.of(context).size.width;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Slide content ──
        if (image != null)
          Image.network(
            image,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, p) => p == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
            errorBuilder: (_, __, ___) => _TextSlide(post: post),
          )
        else
          _TextSlide(post: post),

        // Top & bottom shade for readability
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x99000000),
                Colors.transparent,
                Colors.transparent,
                Color(0xCC000000),
              ],
              stops: [0, 0.18, 0.6, 1],
            ),
          ),
        ),

        // ── Tap zones: left 1/3 = back, right = next, hold = pause ──
        Row(
          children: [
            SizedBox(
              width: width / 3,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTapLeft,
                onLongPressStart: (_) => onHold(),
                onLongPressEnd: (_) => onRelease(),
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTapRight,
                onLongPressStart: (_) => onHold(),
                onLongPressEnd: (_) => onRelease(),
              ),
            ),
          ],
        ),

        // ── Progress bars + header ──
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < group.posts.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _ProgressBar(
                            value: i < slide
                                ? 1
                                : i > slide
                                    ? 0
                                    : null,
                            controller: i == slide ? progress : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    AppAvatar(
                      name: group.name,
                      imageUrl: group.avatarUrl,
                      size: 34,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: AppTextStyles.subtitle(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${timeago.format(post.postedAt, locale: 'en_short')}'
                            '${post.city != null ? ' · ${post.city}' : ''}',
                            style: AppTextStyles.caption(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Bottom: caption + challenge + XP ──
        Positioned(
          left: 16,
          right: 16,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (post.caption != null && post.caption!.isNotEmpty) ...[
                    Text(
                      post.caption!,
                      style: AppTextStyles.body(color: Colors.white)
                          .copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(
                        icon: '🏆',
                        text: [
                          if (post.challengeTitle != null) post.challengeTitle!,
                          post.stationTitle,
                        ].join(' · '),
                      ),
                      if (post.xpAwarded > 0)
                        _Chip(
                          icon: '⚡',
                          text: '+${post.xpAwarded} XP',
                          color: AppColors.teal,
                        ),
                      if (post.isCollab && post.collabUserName != null)
                        _Chip(icon: '🤝', text: 'with ${post.collabUserName}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TextSlide extends StatelessWidget {
  const _TextSlide({required this.post});

  final ChallengeFeedPost post;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: AppColors.primaryGradientDiag),
    alignment: Alignment.center,
    padding: const EdgeInsets.all(32),
    child: Text(
      '💪\n${post.stationTitle}',
      textAlign: TextAlign.center,
      style: AppTextStyles.h1(color: Colors.white),
    ),
  );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({this.value, this.controller});

  /// Fixed value (0 or 1) for non-active bars
  final double? value;
  final AnimationController? controller;

  @override
  Widget build(BuildContext context) {
    Widget bar(double v) => ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: v,
        minHeight: 3,
        backgroundColor: Colors.white24,
        valueColor: const AlwaysStoppedAnimation(Colors.white),
      ),
    );
    final c = controller;
    if (c == null) return bar(value ?? 0);
    return AnimatedBuilder(animation: c, builder: (_, __) => bar(c.value));
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, this.color});

  final String icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: (color ?? Colors.white).withOpacity(0.16),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: (color ?? Colors.white).withOpacity(0.35)),
    ),
    child: Text(
      '$icon $text',
      style: AppTextStyles.bodySM(color: color ?? Colors.white)
          .copyWith(fontWeight: FontWeight.w700),
    ),
  );
}
