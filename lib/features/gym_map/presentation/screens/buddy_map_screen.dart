// ─────────────────────────────────────────────────────────
//  BuddyMapScreen — Snap Map style, opened by swiping left on Discover
//  (or the Map button in Discover's top bar).
//
//  • Buddies only. Never an exact position:
//      – checked in at a gym (last 2 h) → shown at the gym, "Training now"
//      – otherwise active today          → a ~3 km area
//  • Ghost Mode hides you (3 h / 24 h / until turned off)
//  • Gyms → the Gym Map (all gyms, check in)
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';
import '../../../../routes/app_router.dart';
import '../../data/models/gym_models.dart';
import '../bloc/buddy_map_bloc.dart';
import 'gym_map_screen.dart' show kDarkMapStyle;

/// "20 min ago" / "3 h ago"
String timeAgo(DateTime? t, {DateTime? now}) {
  if (t == null) return '';
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

class BuddyMapScreen extends StatefulWidget {
  const BuddyMapScreen({super.key});

  @override
  State<BuddyMapScreen> createState() => _BuddyMapScreenState();
}

class _BuddyMapScreenState extends State<BuddyMapScreen> {
  static const _india = LatLng(19.0760, 72.8777);
  GoogleMapController? _map;
  LatLng? _me;

  @override
  void initState() {
    super.initState();
    context.read<BuddyMapBloc>().add(const BuddyMapLoaded());
    _locate();
  }

  Future<void> _locate() async {
    final r = await const LocationService().current(ask: false);
    if (!mounted || !r.hasPosition) return;
    setState(() => _me = LatLng(r.lat!, r.lng!));
    _map?.animateCamera(CameraUpdate.newLatLngZoom(_me!, 13));
  }

  void _recenter(List<BuddyOnMap> buddies) {
    final target = _me ?? (buddies.isNotEmpty ? LatLng(buddies.first.lat, buddies.first.lng) : _india);
    _map?.animateCamera(CameraUpdate.newLatLngZoom(target, 13));
  }

  Set<Marker> _markers(List<BuddyOnMap> buddies) => {
        for (final b in buddies)
          Marker(
            markerId: MarkerId(b.userId),
            position: LatLng(b.lat, b.lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              b.trainingNow ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: b.firstName,
              snippet: b.trainingNow ? 'Training at ${b.gymName ?? 'the gym'}' : 'Around here',
            ),
            onTap: () => _openBuddy(b),
          ),
      };

  // A ~3 km area, drawn as a soft circle
  Set<Circle> _circles(List<BuddyOnMap> buddies) => {
        for (final b in buddies.where((x) => !x.atGym))
          Circle(
            circleId: CircleId('area-${b.userId}'),
            center: LatLng(b.lat, b.lng),
            radius: (b.areaKm ?? 3) * 500,
            fillColor: AppColors.blue.withOpacity(0.10),
            strokeColor: AppColors.blue.withOpacity(0.35),
            strokeWidth: 1,
          ),
      };

  void _openBuddy(BuddyOnMap b) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppAvatar(name: b.firstName, imageUrl: b.avatarUrl, size: 56),
                  const SizedBox(width: 14),
                  Expanded(child: Text(b.firstName, style: AppTextStyles.h2())),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      b.trainingNow ? Icons.fitness_center_rounded : Icons.near_me_outlined,
                      color: b.trainingNow ? AppColors.teal : AppColors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b.trainingNow
                            ? 'Training now at ${b.gymName ?? 'the gym'} · checked in ${timeAgo(b.at)}'
                            : 'Around this area (about ${(b.areaKm ?? 3).toStringAsFixed(0)} km) · active ${timeAgo(b.at)}',
                        style: AppTextStyles.body(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheet);
                        context.push(AppRoutes.buddyProfile.replaceAll(':userId', b.userId));
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: AppColors.border2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('View profile', style: AppTextStyles.subtitle()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheet);
                        context.push(AppRoutes.scheduleSession, extra: {
                          'buddyId': b.userId,
                          'buddyName': b.firstName,
                          if (b.gymName != null) 'gymName': b.gymName,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(b.trainingNow ? 'Join · Plan session' : 'Plan session'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Buddies see the gym you check in at, or a ~3 km area. Never your exact location.',
                  style: AppTextStyles.caption(),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openGhost(BuddyMapState s) {
    final bloc = context.read<BuddyMapBloc>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) {
        Widget option(String mode, String title, String sub, bool selected) => ListTile(
              key: ValueKey('ghost-$mode'),
              onTap: () {
                Navigator.pop(sheet);
                bloc.add(BuddyMapGhostChanged(mode));
              },
              leading: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
              title: Text(title, style: AppTextStyles.subtitle()),
              subtitle: Text(sub, style: AppTextStyles.caption()),
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Ghost Mode', style: AppTextStyles.h3()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    'Hide yourself from your buddies\' map. Your gym check-ins are hidden too.',
                    style: AppTextStyles.bodySM(),
                  ),
                ),
                option('off', 'Off', 'Buddies can see where you train', !s.ghostMode),
                option('3h', 'Hide for 3 hours', 'Turns off by itself', false),
                option('24h', 'Hide for 24 hours', 'Turns off by itself', false),
                option('on', 'Until I turn it off', 'Stay hidden', s.ghostMode && (s.ghostUntil?.year ?? 0) > 2900),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BuddyMapBloc, BuddyMapState>(
      listenWhen: (p, c) => c.error != null && c.error != p.error && c.status != BuddyMapStatus.failure,
      listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.error!), behavior: SnackBarBehavior.floating),
      ),
      builder: (context, s) {
        final buddies = s.visible;
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _me ?? _india, zoom: 12),
                onMapCreated: (c) {
                  _map = c;
                  _recenter(s.buddies);
                },
                markers: _markers(buddies),
                circles: _circles(buddies),
                myLocationEnabled: _me != null,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                style: kDarkMapStyle,
              ),

              // Top bar + filters
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _CircleButton(
                            icon: Icons.arrow_back,
                            tooltip: 'Back to Discover',
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text('Buddy Map', style: AppTextStyles.h3()),
                                Text(
                                  s.status == BuddyMapStatus.loading && s.buddies.isEmpty
                                      ? 'Loading…'
                                      : '${s.buddies.length} buddies · ${s.trainingCount} training now',
                                  style: AppTextStyles.caption(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          _CircleButton(
                            key: const ValueKey('ghost-button'),
                            icon: s.ghostMode ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            tooltip: 'Ghost Mode',
                            highlighted: s.ghostMode,
                            onTap: () => _openGhost(s),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All buddies',
                              selected: !s.trainingOnly,
                              onTap: () => context
                                  .read<BuddyMapBloc>()
                                  .add(const BuddyMapFilterChanged(trainingOnly: false)),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Training now',
                              dot: true,
                              selected: s.trainingOnly,
                              onTap: () => context
                                  .read<BuddyMapBloc>()
                                  .add(const BuddyMapFilterChanged(trainingOnly: true)),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Gyms',
                              icon: Icons.fitness_center_rounded,
                              selected: false,
                              onTap: () => context.push(AppRoutes.gymMap),
                            ),
                          ],
                        ),
                      ),
                      if (s.ghostMode) ...[
                        const SizedBox(height: 10),
                        Material(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openGhost(s),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.visibility_off_rounded, size: 18, color: AppColors.warning),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Ghost Mode is on: buddies can\'t see you on the map',
                                      style: AppTextStyles.bodySM(color: AppColors.textPrimary),
                                    ),
                                  ),
                                  Text('Change', style: AppTextStyles.bodySM(color: AppColors.primary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Recenter
              Positioned(
                right: 16,
                bottom: 200,
                child: _CircleButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Center on me',
                  onTap: () => _recenter(s.buddies),
                ),
              ),

              // Bottom: buddies list
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BottomList(
                      state: s,
                      buddies: buddies,
                      onTap: (b) {
                        _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(b.lat, b.lng), 14));
                        _openBuddy(b);
                      },
                      onRetry: () => context.read<BuddyMapBloc>().add(const BuddyMapLoaded()),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomList extends StatelessWidget {
  const _BottomList({required this.state, required this.buddies, required this.onTap, required this.onRetry});
  final BuddyMapState state;
  final List<BuddyOnMap> buddies;
  final ValueChanged<BuddyOnMap> onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    Widget box(Widget child) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        );

    if (state.status == BuddyMapStatus.failure) {
      return box(Row(
        children: [
          Expanded(child: Text(state.error ?? 'Could not load the map', style: AppTextStyles.bodySM())),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ));
    }
    if (state.status != BuddyMapStatus.ready && state.buddies.isEmpty) {
      return const SizedBox.shrink();
    }
    if (buddies.isEmpty) {
      return box(Text(
        state.trainingOnly
            ? 'None of your buddies is checked in at a gym right now.'
            : 'No buddies on the map yet. Buddies show up when they open the app or check in at a gym.',
        style: AppTextStyles.bodySM(),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            state.trainingOnly ? 'Training now' : 'Your buddies',
            style: AppTextStyles.subtitle(),
          ),
        ),
        SizedBox(
          height: 84,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: buddies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final b = buddies[i];
              return Material(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onTap(b),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        AppAvatar(name: b.firstName, imageUrl: b.avatarUrl, size: 44, online: b.trainingNow),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(b.firstName, style: AppTextStyles.subtitle(), overflow: TextOverflow.ellipsis),
                              Text(
                                b.trainingNow ? (b.gymName ?? 'At the gym') : 'Around here',
                                style: AppTextStyles.caption(color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                b.trainingNow ? 'Checked in ${timeAgo(b.at)}' : 'Active ${timeAgo(b.at)}',
                                style: AppTextStyles.caption(
                                  color: b.trainingNow ? AppColors.teal : AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({super.key, required this.icon, required this.tooltip, required this.onTap, this.highlighted = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: highlighted ? AppColors.warning.withOpacity(0.2) : AppColors.surface1,
          shape: const CircleBorder(side: BorderSide(color: AppColors.border2)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, size: 20, color: highlighted ? AppColors.warning : AppColors.textPrimary),
            ),
          ),
        ),
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.dot = false, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.primary : AppColors.surface1,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.primary : AppColors.border2)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dot) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                ],
                if (icon != null) ...[
                  Icon(icon, size: 15, color: AppColors.textPrimary),
                  const SizedBox(width: 6),
                ],
                Text(label, style: AppTextStyles.bodySM(color: AppColors.textPrimary).copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
}
