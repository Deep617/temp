import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:seshlly/routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/services/growth_service.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/services/monitoring_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../../core/widgets/error_widget.dart';
import '../../../../../di_injection/dependency_injection.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../../gym_map/data/models/gym_map_utils.dart';
import '../../../../gym_map/data/repositories/gym_map_repository.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../data/response_ml/buddy_profile.dart';
import '../bloc/discover_bloc.dart';
import '../bloc/discover_event.dart';
import '../bloc/discover_state.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _swipeCtrl;
  Offset _dragStart = Offset.zero;
  Offset _dragCurrent = Offset.zero;

  final _location = const LocationService();

  // The "why we need location" sheet shows at most once per app run.
  static bool _locationPromptShown = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _swipeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncLocation());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _swipeCtrl.dispose();
    super.dispose();
  }

  // Back from the phone's settings (or the background) → read it again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed && mounted) _syncLocation(prompt: false);
  }

  // ── Location: ask, read, send to Discover, keep on the profile ──
  Future<void> _syncLocation({bool prompt = true}) async {
    if (_locating) return;
    _locating = true;
    try {
      final bloc = context.read<DiscoverBloc>();
      final access = await _location.access();
      if (!mounted) return;

      // Not asked yet (or "Don't allow" once) → explain first, then the
      // phone's own permission dialog.
      if (access == LocationAccess.denied) {
        if (!prompt || _locationPromptShown) {
          bloc.add(const DiscoverLocationUnavailable(LocationAccess.denied));
          return;
        }
        _locationPromptShown = true;
        final ok = await _showLocationPrompt();
        if (!mounted) return;
        if (!ok) {
          bloc.add(const DiscoverLocationUnavailable(LocationAccess.denied));
          return;
        }
      }

      final r = await _location.current(ask: true);
      if (!mounted) return;
      if (!r.hasPosition) {
        bloc.add(DiscoverLocationUnavailable(r.access));
        return;
      }
      // Save first: the server ignores a search point far from the saved
      // one (e.g. after travelling to another city) until it is updated.
      await _saveLocation(r.lat!, r.lng!);
      if (!mounted) return;
      bloc.add(DiscoverLocationUpdated(lat: r.lat!, lng: r.lng!));
      _maybePromptCheckin(r.lat!, r.lng!);
    } finally {
      _locating = false;
    }
  }

  // ── "Are you at <gym>? Check in" — one tap, so buddies see you training ──
  // Asked at most once per gym per day, and the gym list is looked up at
  // most every 20 minutes (or after moving 200 m) to keep Places calls low.
  static DateTime? _gymCheckAt;
  static double? _gymCheckLat, _gymCheckLng;

  Future<void> _maybePromptCheckin(double lat, double lng) async {
    final now = DateTime.now();
    if (_gymCheckAt != null &&
        now.difference(_gymCheckAt!) < const Duration(minutes: 20) &&
        _gymCheckLat != null &&
        distanceMeters(_gymCheckLat!, _gymCheckLng!, lat, lng) < 200) {
      return;
    }
    _gymCheckAt = now;
    _gymCheckLat = lat;
    _gymCheckLng = lng;
    try {
      final repo = getIt<GymMapRepository>();
      final prefs = await SharedPreferences.getInstance();
      final key = 'gym_prompted_${now.toIso8601String().substring(0, 10)}';
      final prompted = (prefs.getStringList(key) ?? const <String>[]).toSet();
      final mine = await repo.myCheckin();
      final gyms = await repo.nearby(lat: lat, lng: lng, radiusM: 500);
      final gym = pickGymToPrompt(
        gyms: gyms,
        lat: lat,
        lng: lng,
        alreadyCheckedIn: mine?.isActive == true,
        promptedPlaceIds: prompted,
      );
      if (gym == null || !mounted) return;
      await prefs.setStringList(key, [...prompted, gym.placeId]);
      if (!mounted) return;
      final ok = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: AppColors.surface1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.teal,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  'At ${gym.name}?',
                  style: AppTextStyles.h3(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Check in so your buddies see you\'re training. It shows for 2 hours.',
                  style: AppTextStyles.bodySM(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheet, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Check in'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(sheet, false),
                  child: Text(
                    'Not now',
                    style: AppTextStyles.bodySM(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (ok != true || !mounted) return;
      await repo.checkIn(gym, myLat: lat, myLng: lng);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Checked in at ${gym.name}. Your buddies can see it for 2 hours.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      // Not important enough to bother the user (no network, Places down…)
    }
  }

  // Others find you by distance from the profile's position (the server
  // shows them a rounded one). Saved only when it moved 500 m or more.
  Future<void> _saveLocation(double lat, double lng) async {
    final auth = context.read<AuthBloc>();
    final user = auth.state.user;
    if (user == null) return;
    if (!shouldSaveLocation(
      savedLat: user.latitude,
      savedLng: user.longitude,
      lat: lat,
      lng: lng,
    )) {
      return;
    }
    try {
      final updated = await getIt<ProfileRepository>().updateProfile({
        'latitude': lat,
        'longitude': lng,
      });
      if (mounted) auth.add(AuthUserUpdated(user: updated));
    } catch (_) {
      // Not fatal: Discover already uses the position; next open retries.
    }
  }

  // Banner button: ask again, or open the right settings page.
  Future<void> _turnOnLocation(LocationAccess access) async {
    if (access == LocationAccess.deniedForever ||
        access == LocationAccess.serviceOff) {
      await _location.openSettings(access); // resume → _syncLocation
      return;
    }
    _locationPromptShown = true;
    await _syncLocation(prompt: false);
  }

  Future<bool> _showLocationPrompt() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface1,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Find buddies near you',
                style: AppTextStyles.h3(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Seshlly shows people who train within 10 km of you. '
                'Others only see a rounded distance, never your exact location.',
                style: AppTextStyles.bodySM(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheet, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Turn on location'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheet, false),
                child: Text(
                  'Not now',
                  style: AppTextStyles.bodySM(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return ok == true;
  }

  Future<void> _onDragEnd(DragEndDetails d, DiscoverState discoverState) async {
    final dx = _dragCurrent.dx;
    if (dx.abs() > 80 && discoverState.currentProfile != null) {
      final profile = discoverState.currentProfile!;
      if (dx > 0) {
        context.read<DiscoverBloc>().add(
          DiscoverSwipedRight(userId: profile.id),
        );
      } else {
        context.read<DiscoverBloc>().add(
          DiscoverSwipedLeft(userId: profile.id),
        );
      }
    }
    setState(() {
      _dragCurrent = Offset.zero;
    });
  }

  void _showFilters(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: ctx.read<DiscoverBloc>(),
        child: _FiltersSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return MultiBlocListener(
      listeners: [
        // ── Match dialog (right swipe / super like → mutual) ──
        BlocListener<DiscoverBloc, DiscoverState>(
          listenWhen: (prev, curr) =>
              curr.matchedUserId != null &&
              curr.matchedUserId != prev.matchedUserId,
          listener: (context, state) {
            if (state.profiles.isEmpty) return;
            final profile = state.profiles.firstWhere(
              (p) => p.id == state.matchedUserId,
              orElse: () => state.profiles.first,
            );
            _showMatchDialog(
              profile,
              chatId: state.matchedChatId,
              matchId: state.matchedMatchId,
            );
          },
        ),

        // ── Like failed (e.g. daily limit) — say so instead of losing it ──
        BlocListener<DiscoverBloc, DiscoverState>(
          listenWhen: (prev, curr) => curr.swipeError != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.swipeError!, style: AppTextStyles.bodySM()),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),

        // ── Super Like sent ──
        BlocListener<DiscoverBloc, DiscoverState>(
          listenWhen: (prev, curr) =>
              !prev.superLikeSuccess && curr.superLikeSuccess,
          listener: (context, state) {
            MonitoringService.instance.log('super_like');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Text('⭐ '),
                    Text('Super Like sent!', style: AppTextStyles.bodySM()),
                  ],
                ),
                backgroundColor: AppColors.warning.withOpacity(0.9),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),

        // ── Super Like error ──
        BlocListener<DiscoverBloc, DiscoverState>(
          listenWhen: (prev, curr) =>
              curr.superLikeError != null &&
              curr.superLikeError != prev.superLikeError,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.superLikeError!,
                  style: AppTextStyles.bodySM(),
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),

        // ── Boost activated ──
        BlocListener<DiscoverBloc, DiscoverState>(
          listenWhen: (prev, curr) =>
              !prev.boostActivated && curr.boostActivated,
          listener: (context, state) {
            MonitoringService.instance.log('boost_activated');
            // Sync token badge with backend's remaining count
            final authBloc = context.read<AuthBloc>();
            final me = authBloc.state.user;
            if (me != null && state.tokensRemaining != null) {
              authBloc.add(
                AuthUserUpdated(
                  user: me.copyWith(chatTokens: state.tokensRemaining),
                ),
              );
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Text('⚡ '),
                    Text(
                      'Profile Boosted for 30 minutes!',
                      style: AppTextStyles.bodySM(),
                    ),
                  ],
                ),
                backgroundColor: AppColors.teal,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          },
        ),

        // ── Boost error ──
        BlocListener<DiscoverBloc, DiscoverState>(
          listenWhen: (prev, curr) =>
              curr.boostError != null && curr.boostError != prev.boostError,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.boostError!, style: AppTextStyles.bodySM()),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
      child: BlocBuilder<DiscoverBloc, DiscoverState>(
        builder: (context, state) {
          final user = context.watch<AuthBloc>().state.user;
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      // Top Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 5, 0),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Image.asset(
                                  AppImages.logo,
                                  height: 45,
                                  width: 45,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text('Discover', style: AppTextStyles.h3()),
                            const Spacer(),
                            if (user != null)
                              TokenBadge(count: user.chatTokens!),
                            const SizedBox(width: 5),
                            // Buddy Map (also: swipe left from the right edge)
                            Tooltip(
                              message: 'Buddy Map',
                              child: GestureDetector(
                                key: const ValueKey('discover-map-button'),
                                onTap: () => context.push(AppRoutes.buddyMap),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface2,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.border2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.map_outlined,
                                    color: AppColors.teal,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            GestureDetector(
                              onTap: () => _showFilters(context),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: state.selectedActivity != null
                                      ? AppColors.primary.withOpacity(0.15)
                                      : AppColors.surface2,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: state.selectedActivity != null
                                        ? AppColors.primary.withOpacity(0.3)
                                        : AppColors.border2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.tune,
                                  color: state.selectedActivity != null
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            GestureDetector(
                              onTap: () =>
                                  context.push(AppRoutes.notifications),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.surface2,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border2),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Location off → people from everywhere, no distance ──
                      if (state.locationAccess != LocationAccess.granted &&
                          state.locationAccess != LocationAccess.unknown)
                        LocationOffBanner(
                          access: state.locationAccess,
                          onTurnOn: () => _turnOnLocation(state.locationAccess),
                        ),

                      // Card Stack
                      if (state.status != DiscoverStatus.failure)
                        Expanded(
                          child: state.isLoading && state.profiles.isEmpty
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                )
                              : state.profiles.isEmpty &&
                                    state.status == DiscoverStatus.success
                              ? EmptyState(
                                  emoji: '🔍',
                                  title: 'No more profiles',
                                  subtitle:
                                      'Change filters or check back later',
                                  action: 'Change Filters',
                                  onAction: () => _showFilters(context),
                                )
                              : state.isExhausted
                              ? EmptyState(
                                  emoji: '✨',
                                  title: 'You\'ve seen everyone!',
                                  subtitle:
                                      'Come back tomorrow for fresh matches',
                                  action: 'Refresh',
                                  onAction: () =>
                                      context.read<DiscoverBloc>().add(
                                        const DiscoverProfilesLoaded(
                                          refresh: true,
                                        ),
                                      ),
                                )
                              : Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ...List.generate(2, (i) {
                                      final idx = state.currentIndex + 2 - i;
                                      if (idx >= state.profiles.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Positioned(
                                        top: 8.0 * (2 - i),
                                        child: Transform.scale(
                                          scale: 0.94 + 0.03 * (2 - i),
                                          child: SizedBox(
                                            width: size.width - 56,
                                            height: size.height * 0.57,
                                            child: _BuddyCard(
                                              profile: state.profiles[idx],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                    GestureDetector(
                                      onPanStart: (d) => setState(() {
                                        _dragStart = d.globalPosition;
                                      }),
                                      onPanUpdate: (d) => setState(
                                        () => _dragCurrent =
                                            d.globalPosition - _dragStart,
                                      ),
                                      onPanEnd: (d) => _onDragEnd(d, state),
                                      child: Transform.translate(
                                        offset: _dragCurrent,
                                        child: Transform.rotate(
                                          angle: _dragCurrent.dx * 0.001,
                                          child: Stack(
                                            children: [
                                              SizedBox(
                                                width: size.width - 40,
                                                height: size.height * 0.57,
                                                child: _BuddyCard(
                                                  profile:
                                                      state.profiles[state
                                                          .currentIndex],
                                                ),
                                              ),
                                              if (_dragCurrent.dx > 40)
                                                Positioned(
                                                  top: 24,
                                                  left: 24,
                                                  child: _SwipeLabel(
                                                    label: 'CONNECT!',
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              if (_dragCurrent.dx < -40)
                                                Positioned(
                                                  top: 24,
                                                  right: 24,
                                                  child: _SwipeLabel(
                                                    label: 'SKIP',
                                                    color: AppColors.error,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                      // Action Buttons
                      if (state.profiles.isNotEmpty && !state.isExhausted)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ActionBtn(
                                icon: Icons.close,
                                color: AppColors.error,
                                size: 56,
                                onTap: () => context.read<DiscoverBloc>().add(
                                  DiscoverSwipedLeft(
                                    userId: state.currentProfile!.id,
                                  ),
                                ),
                              ),
                              ActionBtn(
                                icon: Icons.star,
                                color: AppColors.warning,
                                size: 44,
                                onTap: () {
                                  if (state.currentProfile == null) return;
                                  context.read<DiscoverBloc>().add(
                                    DiscoverSuperLiked(
                                      userId: state.currentProfile!.id,
                                    ),
                                  );
                                },
                              ),
                              ActionBtn(
                                icon: Icons.favorite,
                                color: AppColors.primary,
                                size: 64,
                                onTap: () => context.read<DiscoverBloc>().add(
                                  DiscoverSwipedRight(
                                    userId: state.currentProfile!.id,
                                  ),
                                ),
                              ),
                              ActionBtn(
                                icon: Icons.bolt,
                                color: state.isBoostLive
                                    ? AppColors
                                          .warning // glowing when active
                                    : AppColors.teal,
                                size: 44,
                                onTap: () {
                                  if (state.isBoostLive) {
                                    // Already active — show remaining time
                                    final remaining =
                                        state.boostExpiresAt
                                            ?.difference(DateTime.now())
                                            .inMinutes ??
                                        0;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '⚡ Boost active — $remaining mins remaining',
                                          style: AppTextStyles.bodySM(),
                                        ),
                                        backgroundColor: AppColors.surface2,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  context.read<DiscoverBloc>().add(
                                    const DiscoverBoosted(),
                                  );
                                },
                              ),
                              ActionBtn(
                                icon: Icons.refresh,
                                color: AppColors.blue,
                                size: 56,
                                onTap: () => context.read<DiscoverBloc>().add(
                                  const DiscoverProfilesLoaded(refresh: true),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Error View with action
                      if (state.status == DiscoverStatus.failure)
                        ErrorView(
                          appError: state.error!,
                          onRetry: () {
                            context.read<DiscoverBloc>().add(
                              const DiscoverProfilesLoaded(),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                // Swipe left from the right edge → Buddy Map (Snap Map style)
                Positioned(
                  right: 0,
                  top: 130,
                  bottom: 120,
                  child: MapEdgeHandle(
                    onOpen: () => context.push(AppRoutes.buddyMap),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMatchDialog(
    BuddyProfile profile, {
    String? chatId,
    String? matchId,
  }) {
    GrowthService.instance.logFirst(GrowthService.firstMatch);
    showDialog(
      context: context,
      builder: (_) =>
          MatchDialog(profile: profile, chatId: chatId, matchId: matchId),
    );
  }
}

// ── Buddy Card, SwipeLabel, ActionBtn, MatchDialog, FiltersSheet ──
// (Identical UI to original — only state source changes)

class _BuddyCard extends StatelessWidget {
  const _BuddyCard({required this.profile});

  final BuddyProfile profile;

  @override
  Widget build(BuildContext context) {
    final actColor = profile.primaryActivity != null
        ? Color(
            AppConstants.activities.firstWhere(
                  (a) => a['id'] == profile.primaryActivity,
                  orElse: () => {'color': 0xFF0A84FF},
                )['color']
                as int,
          )
        : AppColors.primary;

    return InkWell(
      onTap: () {
        if (profile.isInfluencer) {
          context.push(
            AppRoutes.influencerProfile.replaceAll(':id', profile.id),
          );
        } else {
          context.push(
            AppRoutes.buddyView,
            extra: {
              'buddyProfile': profile,
              'discoverBloc': context.read<DiscoverBloc>(),
            },
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            children: [
              (profile.avatarUrl != null || profile.photos.isNotEmpty)
                  ? Positioned.fill(
                      child: PhotoCarousel(
                        photos: profile.photos,
                        avatarUrl: profile.avatarUrl,
                        name: profile.fullName,
                        height: double.maxFinite,
                        swipeable:
                            false, // drag = like/skip; tap edges = photos
                      ),
                    )
                  : _Placeholder(profile: profile),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.92),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  '${profile.firstName}, ${profile.level}',
                                  style: AppTextStyles.h2(),
                                ),
                                if (profile.idVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified,
                                    color: AppColors.blue,
                                    size: 18,
                                  ),
                                ],
                                if (profile.isInfluencer) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.star,
                                    color: AppColors.gold,
                                    size: 18,
                                  ),
                                ],
                                if (profile.isNew) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.teal.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: AppColors.teal.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      'NEW',
                                      style: AppTextStyles.label(
                                        color: AppColors.teal,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          CompatRing(
                            score: profile.compatibilityScore,
                            size: 64,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (profile.city != null) ...[
                            const Icon(
                              Icons.location_on,
                              color: AppColors.textMuted,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(profile.city!, style: AppTextStyles.bodySM()),
                            const SizedBox(width: 12),
                          ],
                          if (profile.distanceKm != null) ...[
                            const Icon(
                              Icons.near_me,
                              color: AppColors.textMuted,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${profile.distanceKm!.toStringAsFixed(1)} km',
                              style: AppTextStyles.bodySM(),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (profile.primaryActivity != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: actColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: actColor.withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppConstants.activities.firstWhere(
                                          (a) =>
                                              a['id'] ==
                                              profile.primaryActivity,
                                          orElse: () => {'emoji': '💪'},
                                        )['emoji']
                                        as String,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.primaryActivity!,
                                    style: AppTextStyles.bodySM(
                                      color: actColor,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              profile.levelName,
                              style: AppTextStyles.bodySM(
                                color: AppColors.textSecondary,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (profile.isPro)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.compatGradient,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'PRO',
                                style: AppTextStyles.label(color: Colors.black),
                              ),
                            ),
                        ],
                      ),
                      if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          profile.bio!,
                          style: AppTextStyles.bodySM(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.profile});

  final BuddyProfile profile;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: AppColors.cardGymGradient),
    child: Center(
      child: Text(
        profile.firstName.isNotEmpty ? profile.firstName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 80,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    ),
  );
}

class _SwipeLabel extends StatelessWidget {
  const _SwipeLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: color, width: 2.5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 2,
      ),
    ),
  );
}

class ActionBtn extends StatelessWidget {
  const ActionBtn({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)],
      ),
      child: Icon(icon, color: color, size: size * 0.42),
    ),
  );
}

class MatchDialog extends StatelessWidget {
  const MatchDialog({required this.profile, this.chatId, this.matchId});

  final BuddyProfile profile;
  final String? chatId; // real chat id from the server (null → chat list)
  final String? matchId;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [AppColors.primary.withOpacity(0.15), AppColors.surface1],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🎉',
            style: TextStyle(fontSize: 56),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            "It's a Match!",
            style: AppTextStyles.h1(color: AppColors.primary),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'You and ${profile.firstName} both want to train together!',
            style: AppTextStyles.body(),
            textAlign: TextAlign.center,
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 28),
          Row(
            children: [
              AppAvatar(
                name: profile.fullName,
                imageUrl: profile.avatarUrl,
                size: 60,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    gradient: AppColors.compatGradient,
                  ),
                ),
              ),
              const Icon(Icons.favorite, color: AppColors.primary, size: 28),
              Expanded(
                child: Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    gradient: AppColors.compatGradient,
                  ),
                ),
              ),
              AppAvatar(name: 'You', size: 60),
            ],
          ).animate(delay: 400.ms).fadeIn(),
          const SizedBox(height: 28),
          PrimaryButton(
            label: '💬 Send First Message',
            onPressed: () {
              Navigator.pop(context);
              // The server returns the real chat id; without it, open the chat list
              final id = chatId; // local → null-check promotes it
              if (id == null) {
                context.go(AppRoutes.chats);
                return;
              }
              context.push(
                AppRoutes.chat.replaceAll(':chatId', id),
                extra: {
                  'buddyName': profile.firstName,
                  'buddyAvatar': profile.avatarUrl,
                  'buddyId': profile.id,
                  'matchId': matchId,
                },
              );
            },
            height: 48,
          ).animate(delay: 500.ms).fadeIn(),
          const SizedBox(height: 12),
          GhostButton(
            label: 'Keep Swiping',
            onPressed: () => Navigator.pop(context),
            height: 44,
          ).animate(delay: 600.ms).fadeIn(),
        ],
      ),
    ),
  );
}

class _FiltersSheet extends StatefulWidget {
  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  String? _activity;
  String? _level;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.7,
    maxChildSize: 0.9,
    minChildSize: 0.5,
    expand: false,
    builder: (_, ctrl) => Container(
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        controller: ctrl,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Filter Matches', style: AppTextStyles.h3()),
          const SizedBox(height: 20),
          Text('ACTIVITY', style: AppTextStyles.label()),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.activities
                .map(
                  (a) => ActivityChip(
                    activity: a,
                    selected: _activity == a['id'],
                    onTap: () => setState(
                      () => _activity = _activity == a['id']
                          ? null
                          : a['id'] as String,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          Text('EXPERIENCE LEVEL', style: AppTextStyles.label()),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.levels
                .map(
                  (l) => GestureDetector(
                    onTap: () => setState(
                      () => _level = _level == l['id'] ? null : l['id'],
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _level == l['id']
                            ? AppColors.primary.withOpacity(0.15)
                            : AppColors.surface2,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: _level == l['id']
                              ? AppColors.primary.withOpacity(0.4)
                              : AppColors.border2,
                        ),
                      ),
                      child: Text(
                        l['label']!,
                        style: AppTextStyles.bodySM(
                          color: _level == l['id']
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Apply Filters',
            onPressed: () {
              context.read<DiscoverBloc>().add(
                DiscoverFilterChanged(activity: _activity, level: _level),
              );
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          GhostButton(
            label: 'Clear All',
            height: 44,
            onPressed: () {
              context.read<DiscoverBloc>().add(const DiscoverFilterChanged());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel({
    required this.photos,
    required this.avatarUrl,
    required this.name,
    required this.height,
    this.swipeable = true,
    this.onOpenGallery,
  });

  final List<String> photos;
  final String? avatarUrl;
  final String name;
  final double height;

  /// false on Discover cards: horizontal drags belong to the card
  /// (like / skip), so photos change by tapping left / right edges.
  final bool swipeable;

  /// Optional: tap in the middle opens a full-screen gallery
  final void Function(int index)? onOpenGallery;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  final _ctrl = PageController();
  int _current = 0;

  // Main photo first, then the rest (backend already sends this order)
  List<String> get _allPhotos {
    final list = <String>[...widget.photos];
    if (list.isEmpty && widget.avatarUrl != null) list.add(widget.avatarUrl!);
    return list;
  }

  @override
  void didUpdateWidget(covariant PhotoCarousel old) {
    super.didUpdateWidget(old);
    // Profile changed (e.g. new card) → back to first photo
    if (old.photos.join() != widget.photos.join() && _current != 0) {
      _current = 0;
      if (_ctrl.hasClients) _ctrl.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go(int delta, int count) {
    final next = (_current + delta).clamp(0, count - 1);
    if (next == _current) return;
    _ctrl.animateToPage(
      next,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = _allPhotos;

    if (photos.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(child: AppAvatar(name: widget.name, size: 80)),
      );
    }

    return Semantics(
      label: 'Photo ${_current + 1} of ${photos.length}',
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, box) {
            final zone =
                box.maxWidth / 3; // left third = back, right third = next
            return Stack(
              children: [
                PageView.builder(
                  controller: _ctrl,
                  itemCount: photos.length,
                  physics: widget.swipeable
                      ? const PageScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (_, i) => Image.network(
                    photos[i],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surface2,
                      child: Center(
                        child: AppAvatar(name: widget.name, size: 60),
                      ),
                    ),
                  ),
                ),

                if (photos.length > 1) ...[
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: zone,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _go(-1, photos.length),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: zone,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _go(1, photos.length),
                    ),
                  ),
                ],
                if (widget.onOpenGallery != null)
                  Positioned(
                    left: photos.length > 1 ? zone : 0,
                    right: photos.length > 1 ? zone : 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => widget.onOpenGallery!(_current),
                    ),
                  ),

                // Progress dashes — top
                if (photos.length > 1)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: List.generate(
                        photos.length,
                        (i) => Expanded(
                          child: AnimatedContainer(
                            key: ValueKey('photo-dash-$i'),
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 3,
                            decoration: BoxDecoration(
                              color: i == _current
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Full-screen photo gallery (swipe, pinch to zoom). Use:
///   showPhotoGallery(context, photos, initialIndex: 0, name: 'Rahul')
Future<void> showPhotoGallery(
  BuildContext context,
  List<String> photos, {
  int initialIndex = 0,
  String name = '',
}) {
  if (photos.isEmpty) return Future.value();
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _PhotoGallery(
        photos: photos,
        initialIndex: initialIndex.clamp(0, photos.length - 1),
        name: name,
      ),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

class _PhotoGallery extends StatefulWidget {
  const _PhotoGallery({
    required this.photos,
    required this.initialIndex,
    required this.name,
  });

  final List<String> photos;
  final int initialIndex;
  final String name;

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  late final PageController _ctrl = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.network(
                widget.photos[i],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white38,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    widget.name,
                    style: AppTextStyles.subtitle(color: Colors.white),
                  ),
                ),
                if (widget.photos.length > 1)
                  Text(
                    '${_index + 1} / ${widget.photos.length}',
                    style: AppTextStyles.bodySM(color: Colors.white70),
                  ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Shown on Discover while location is off.
class LocationOffBanner extends StatelessWidget {
  const LocationOffBanner({
    super.key,
    required this.access,
    required this.onTurnOn,
  });

  final LocationAccess access;
  final VoidCallback onTurnOn;

  @override
  Widget build(BuildContext context) {
    final text = access == LocationAccess.serviceOff
        ? 'Your phone\'s location is off. Turn it on to see people within 10 km.'
        : 'Location is off, so you see people from everywhere. Turn it on to see people within 10 km.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_off_rounded,
              color: AppColors.warning,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: AppTextStyles.bodySM())),
            TextButton(onPressed: onTurnOn, child: const Text('Turn on')),
          ],
        ),
      ),
    );
  }
}

/// Thin handle on Discover's right edge: swipe it left (or tap) to open the
/// Buddy Map, like Snap Map.
class MapEdgeHandle extends StatelessWidget {
  const MapEdgeHandle({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Open Buddy Map',
    child: GestureDetector(
      key: const ValueKey('map-edge-handle'),
      behavior: HitTestBehavior.translucent,
      onTap: onOpen,
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -150) onOpen();
      },
      child: SizedBox(
        width: 22,
        child: Center(
          child: Container(
            width: 6,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.55),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(6),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
