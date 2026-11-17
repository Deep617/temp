import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../discover/data/response_ml/buddy_profile.dart';
import '../bloc/discover_bloc.dart';
import '../bloc/discover_event.dart';
import 'discover_screen.dart';
import '../../../../safety/presentation/widgets/safety_sheet.dart';

/// A Discover profile, opened by tapping the top card.
///
/// Layout (reference-app style): the main photo on top, the other photos
/// between the info cards, and Pass / Super Like / Like fixed at the bottom
/// so the user can answer from anywhere in the profile. Tapping any photo
/// opens the full-screen gallery with all of them.
class BuddyViewScreen extends StatelessWidget {
  const BuddyViewScreen({super.key, required this.buddyProfile});

  final BuddyProfile buddyProfile;

  List<String> get _photos {
    final p = buddyProfile;
    if (p.photos.isNotEmpty) return p.photos;
    return p.avatarUrl != null ? [p.avatarUrl!] : const [];
  }

  // Pass / Like / Super Like answer the top Discover card, then go back:
  // Discover shows the match dialog or the "limit reached" message.
  void _answer(BuildContext context, DiscoverEvent event) {
    context.read<DiscoverBloc>().add(event);
    Navigator.of(context).maybePop();
  }

  void _openGallery(BuildContext context, int index) => showPhotoGallery(
        context,
        _photos,
        initialIndex: index,
        name: buddyProfile.fullName,
      );

  @override
  Widget build(BuildContext context) {
    final p = buddyProfile;
    final photos = _photos;
    final width = MediaQuery.of(context).size.width;

    // Photo i (i ≥ 1) goes after the section with the same number; extra
    // photos (if a section is empty) are added at the end.
    Widget? photoAt(int i) => i < photos.length
        ? _InlinePhoto(
            key: ValueKey('profile-photo-$i'),
            url: photos[i],
            name: p.firstName,
            onTap: () => _openGallery(context, i),
          )
        : null;

    final sections = <Widget>[
      if (p.bio != null && p.bio!.trim().isNotEmpty)
        _Card(label: 'About me', child: Text(p.bio!.trim(), style: AppTextStyles.body())),
      _trainingCard(p),
      _statsRow(p),
      if (p.goals.isNotEmpty) _goalsCard(p),
      _compatCard(p),
    ];

    final body = <Widget>[];
    var nextPhoto = 1;
    for (final s in sections) {
      body.add(s);
      final ph = photoAt(nextPhoto);
      if (ph != null) {
        body.add(ph);
        nextPhoto++;
      }
    }
    while (nextPhoto < photos.length) {
      body.add(photoAt(nextPhoto)!);
      nextPhoto++;
    }
    if (p.city != null || p.distanceKm != null) body.add(_locationCard(p));
    body.add(_reportRow(context, p));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          SingleChildScrollView(
            key: const ValueKey('profile-scroll'),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Cover(
                  profile: p,
                  photoCount: photos.length,
                  height: width * 4 / 3,
                  photo: photos.isEmpty
                      ? null
                      : _NetPhoto(
                          key: const ValueKey('profile-photo-0'),
                          url: photos.first,
                          name: p.firstName,
                        ),
                  onTap: photos.isEmpty ? null : () => _openGallery(context, 0),
                ),
                for (final w in body)
                  Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: w),
              ],
            ),
          ),

          // Back + Report/Block, over the photo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.arrow_back,
                      tooltip: 'Back',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    SafetyMenuButton(
                      userId: p.id,
                      name: p.fullName,
                      source: 'profile',
                      boxed: true,
                      onBlocked: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sticky actions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ActionBar(
              onPass: () => _answer(context, DiscoverSwipedLeft(userId: p.id)),
              onSuper: () => _answer(context, DiscoverSuperLiked(userId: p.id)),
              onLike: () => _answer(context, DiscoverSwipedRight(userId: p.id)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sections (existing profile data only) ──

  Widget _trainingCard(BuddyProfile p) {
    String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
    Map<String, dynamic>? act(String id) {
      for (final a in AppConstants.activities) {
        if (a['id'] == id) return a;
      }
      return null;
    }

    final ids = <String>[
      if (p.primaryActivity != null) p.primaryActivity!,
      ...p.activities.where((a) => a != p.primaryActivity),
    ];
    final chips = <Widget>[
      for (final id in ids)
        _Chip(
          text: act(id)?['label'] as String? ?? cap(id),
          emoji: act(id)?['emoji'] as String?,
        ),
      if (p.experienceLevel != null) _Chip(text: cap(p.experienceLevel!), emoji: '📈'),
      if (p.primaryGym != null) _Chip(text: p.primaryGym!, emoji: '📍'),
    ];
    return _Card(
      label: 'Training',
      child: chips.isEmpty
          ? Text('No training details yet', style: AppTextStyles.bodySM())
          : Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _statsRow(BuddyProfile p) => Column(
        children: [
          Row(
            children: [
              _Stat(value: '${p.sessionCount}', label: 'Sessions'),
              const SizedBox(width: 10),
              _Stat(value: '${p.buddyCount}', label: 'Buddies'),
              const SizedBox(width: 10),
              _Stat(value: '${p.trustScore.toInt()}', label: 'Trust'),
            ],
          ),
          if (p.confirmRate != null) ...[
            const SizedBox(height: 10),
            _Card(
              child: Row(
                children: [
                  Expanded(child: Text('Confirms proofs on time', style: AppTextStyles.bodySM())),
                  Text(
                    '${p.confirmRate}%',
                    style: AppTextStyles.subtitle(
                      color: p.confirmRate! >= 80
                          ? AppColors.teal
                          : p.confirmRate! >= 50
                              ? AppColors.warning
                              : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );

  Widget _goalsCard(BuddyProfile p) => _Card(
        label: 'Goals',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final id in p.goals)
              () {
                final g = AppConstants.goals.firstWhere(
                  (x) => x['id'] == id,
                  orElse: () => {'id': id, 'emoji': '🎯', 'label': id},
                );
                return _Chip(text: '${g['label']}', emoji: '${g['emoji']}');
              }(),
          ],
        ),
      );

  Widget _compatCard(BuddyProfile p) {
    final s = p.compatibilityScore;
    final text = s >= 80
        ? 'Excellent match. You train the same way.'
        : s >= 60
            ? 'Good match. Similar fitness goals.'
            : s >= 40
                ? 'Decent match. Worth a try.'
                : 'Different styles. Might be complementary!';
    return _Card(
      child: Row(
        children: [
          CompatRing(score: s, size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Compatibility Score', style: AppTextStyles.subtitle()),
                const SizedBox(height: 4),
                Text(text, style: AppTextStyles.bodySM()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard(BuddyProfile p) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.teal]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${p.firstName} trains in',
                style: AppTextStyles.bodySM(color: Colors.white.withOpacity(0.85))),
            const SizedBox(height: 4),
            Text(
              [
                if (p.city != null) p.city!,
                if (p.distanceKm != null) '${p.distanceKm!.toStringAsFixed(1)} km away',
              ].join(' · '),
              style: AppTextStyles.h3(color: Colors.white),
            ),
          ],
        ),
      );

  Widget _reportRow(BuildContext context, BuddyProfile p) => Center(
        child: TextButton.icon(
          onPressed: () async {
            final blocked = await showSafetySheet(
              context,
              userId: p.id,
              name: p.fullName,
              source: 'profile',
            );
            if (blocked && context.mounted) Navigator.of(context).maybePop();
          },
          icon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.error),
          label: Text('Report or block', style: AppTextStyles.bodySM(color: AppColors.error)),
        ),
      );
}

// ── Pieces ──

class _Cover extends StatelessWidget {
  const _Cover({
    required this.profile,
    required this.photoCount,
    required this.height,
    required this.photo,
    required this.onTap,
  });

  final BuddyProfile profile;
  final int photoCount;
  final double height;
  final Widget? photo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: onTap,
            child: photo ??
                Container(
                  color: AppColors.surface2,
                  alignment: Alignment.center,
                  child: Text(
                    p.firstName.isEmpty ? '?' : p.firstName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.transparent,
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // How many photos there are (tap opens them all)
          if (photoCount > 1)
            Positioned(
              right: 16,
              bottom: 96,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Text('$photoCount photos',
                          style: AppTextStyles.caption(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.age != null ? '${p.firstName}, ${p.age}' : p.fullName,
                          style: AppTextStyles.h1(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (p.idVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: AppColors.blue, size: 22),
                      ],
                      if (p.isInfluencer) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star, color: AppColors.gold, size: 22),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppBadge(label: p.levelName, small: true),
                      if (p.isPro)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppColors.compatGradient,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text('PRO', style: AppTextStyles.label(color: Colors.black)),
                        ),
                      if (p.isOnline)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text('Online',
                                style: AppTextStyles.bodySM(color: AppColors.teal)
                                    .copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      if (p.distanceKm != null)
                        Text('${p.distanceKm!.toStringAsFixed(1)} km away',
                            style: AppTextStyles.bodySM(color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetPhoto extends StatelessWidget {
  const _NetPhoto({super.key, required this.url, required this.name});
  final String url;
  final String name;

  @override
  Widget build(BuildContext context) => Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surface2,
          child: Center(child: AppAvatar(name: name, size: 60)),
        ),
      );
}

class _InlinePhoto extends StatelessWidget {
  const _InlinePhoto({super.key, required this.url, required this.name, required this.onTap});
  final String url;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Photo of $name. Tap to see all photos',
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(aspectRatio: 4 / 5, child: _NetPhoto(url: url, name: name)),
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({this.label, required this.child});
  final String? label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(label!.toUpperCase(),
                  style: AppTextStyles.label(color: AppColors.textMuted)
                      .copyWith(letterSpacing: 1.1)),
              const SizedBox(height: 10),
            ],
            child,
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.emoji});
  final String text;
  final String? emoji;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.border2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySM(color: AppColors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(value, style: AppTextStyles.h3(color: AppColors.teal)),
              const SizedBox(height: 2),
              Text(label, style: AppTextStyles.caption()),
            ],
          ),
        ),
      );
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      );
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onPass, required this.onSuper, required this.onLike});
  final VoidCallback onPass;
  final VoidCallback onSuper;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bg.withOpacity(0), AppColors.bg.withOpacity(0.95), AppColors.bg],
            stops: const [0, 0.4, 1],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionCircle(
                  key: const ValueKey('action-pass'),
                  icon: Icons.close_rounded,
                  label: 'Pass',
                  size: 60,
                  color: AppColors.error,
                  onTap: onPass,
                ),
                const SizedBox(width: 20),
                _ActionCircle(
                  key: const ValueKey('action-super'),
                  icon: Icons.star_rounded,
                  label: 'Super Like',
                  size: 52,
                  color: AppColors.gold,
                  onTap: onSuper,
                ),
                const SizedBox(width: 20),
                _ActionCircle(
                  key: const ValueKey('action-like'),
                  icon: Icons.favorite_rounded,
                  label: 'Like',
                  size: 68,
                  color: AppColors.primary,
                  filled: true,
                  onTap: onLike,
                ),
              ],
            ),
          ),
        ),
      );
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    super.key,
    required this.icon,
    required this.label,
    required this.size,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final double size;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: filled ? color : AppColors.surface1,
          shape: CircleBorder(side: BorderSide(color: color.withOpacity(filled ? 0 : 0.45), width: 2)),
          elevation: filled ? 6 : 0,
          shadowColor: color.withOpacity(0.5),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: filled ? Colors.white : color, size: size * 0.45),
            ),
          ),
        ),
      );
}
