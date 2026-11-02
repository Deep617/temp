// ─────────────────────────────────────────────────────────
//  GymMapScreen — Snap-Map style, built for gym buddies
//
//  • All gyms around you (Google Places, all-India)
//  • Orange pin = your buddies are training there right now
//  • "Check in" at a gym → your buddies see you there for 2 hours
//  • Nobody is tracked: you only appear when YOU check in, and only to
//    your buddies, and only at the gym (never your exact GPS).
// ─────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/services/monitoring_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';
import '../../../../di_injection/dependency_injection.dart';
import '../../data/models/gym_map_utils.dart';
import '../../data/models/gym_models.dart';
import '../../data/repositories/gym_map_repository.dart';
import '../../../../routes/app_router.dart';

class GymMapScreen extends StatefulWidget {
  const GymMapScreen({super.key});

  @override
  State<GymMapScreen> createState() => _GymMapScreenState();
}

class _GymMapScreenState extends State<GymMapScreen> {
  static const _india = LatLng(19.0760, 72.8777); // fallback: Mumbai
  static const _searchRadiusM = 3000;

  final _repo = getIt<GymMapRepository>();
  final _searchCtrl = TextEditingController();
  GoogleMapController? _map;
  Timer? _ticker;

  LatLng? _myPos;
  LatLng _lastFetchCenter = _india;
  LatLng _cameraCenter = _india;
  bool _locationDenied = false;

  List<Gym> _gyms = const [];
  List<BuddyCheckin> _buddies = const [];
  BuddyCheckin? _myCheckin;
  bool _loading = true;
  bool _showSearchArea = false;
  String? _error;
  bool _notConfigured = false;

  @override
  void initState() {
    super.initState();
    _init();
    // refresh "time left" labels
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _searchCtrl.dispose();
    _map?.dispose();
    super.dispose();
  }

  // ── Location ───────────────────────────────────────────
  Future<LatLng?> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      final pos =
          await Geolocator.getCurrentPosition(
            timeLimit: Duration(seconds: 10),
          ).catchError(
            (_) async =>
                (await Geolocator.getLastKnownPosition()) ??
                (throw Exception('no position')),
          );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _init() async {
    final pos = await _locate();
    if (!mounted) return;
    setState(() {
      _myPos = pos;
      _locationDenied = pos == null;
      _cameraCenter = pos ?? _india;
    });
    _map?.moveCamera(CameraUpdate.newLatLngZoom(_cameraCenter, 14));
    await Future.wait([_loadGyms(_cameraCenter), _loadBuddies()]);
  }

  // ── Data ───────────────────────────────────────────────
  Future<void> _loadGyms(LatLng center, {String? query}) async {
    setState(() {
      _loading = true;
      _error = null;
      _showSearchArea = false;
    });
    try {
      final gyms = await _repo.nearby(
        lat: center.latitude,
        lng: center.longitude,
        radiusM: _searchRadiusM,
        query: query,
      );
      if (!mounted) return;
      setState(() {
        _gyms = gyms;
        _lastFetchCenter = center;
        _loading = false;
        _notConfigured = false;
      });
      if (query != null && gyms.isNotEmpty) {
        _map?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(gyms.first.lat, gyms.first.lng),
            14,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final err = e is AppError ? e : AppError.fromException(e);
      setState(() {
        _loading = false;
        _notConfigured = err.statusCode == 503;
        _error = _notConfigured ? null : err.message;
      });
    }
  }

  Future<void> _loadBuddies() async {
    try {
      final results = await Future.wait([_repo.buddies(), _repo.myCheckin()]);
      if (!mounted) return;
      setState(() {
        _buddies = (results[0] as List<BuddyCheckin>)
            .where((b) => b.isActive)
            .toList();
        _myCheckin = results[1] as BuddyCheckin?;
      });
    } catch (_) {
      /* map still works without buddies */
    }
  }

  Future<void> _checkIn(Gym gym) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text('Check in at ${gym.name}?', style: AppTextStyles.h3()),
        content: Text(
          'Only your buddies will see you at this gym for the next 2 hours. '
          'Your exact location is never shared.',
          style: AppTextStyles.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Check in'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // Server checks that I'm really at the gym
    final here = await _locate() ?? _myPos;
    if (here == null) {
      _toast(const AppError(message: 'Turn on location to check in'));
      return;
    }
    try {
      final c = await _repo.checkIn(
        gym,
        myLat: here.latitude,
        myLng: here.longitude,
      );
      MonitoringService.instance.log('gym_checkin');
      if (!mounted) return;
      setState(() => _myCheckin = c);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📍 Checked in at ${gym.name} — your buddies have been notified 💪',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _toast(e);
    }
  }

  Future<void> _checkOut() async {
    try {
      await _repo.checkOut();
      if (mounted) setState(() => _myCheckin = null);
    } catch (e) {
      _toast(e);
    }
  }

  // Plain list of gyms (nearest first) — also works if map tiles fail to load
  void _showList() {
    final gyms = sortByDistance(
      _gyms,
      fromLat: _myPos?.latitude,
      fromLng: _myPos?.longitude,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Gyms near you (${gyms.length})',
                  style: AppTextStyles.h3(),
                ),
              ),
              Expanded(
                child: gyms.isEmpty
                    ? Center(
                        child: Text(
                          _loading
                              ? 'Loading gyms…'
                              : 'No gyms found in this area',
                          style: AppTextStyles.bodySM(),
                        ),
                      )
                    : ListView.separated(
                        itemCount: gyms.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (_, i) {
                          final g = gyms[i];
                          final here = _buddies
                              .where((b) => b.placeId == g.placeId)
                              .toList();
                          return ListTile(
                            leading: Icon(
                              Icons.fitness_center,
                              color: here.isNotEmpty
                                  ? AppColors.warning
                                  : AppColors.primary,
                            ),
                            title: Text(
                              g.name,
                              style: AppTextStyles.subtitle(),
                            ),
                            subtitle: Text(
                              [
                                if (_myPos != null)
                                  formatDistance(
                                    distanceMeters(
                                      _myPos!.latitude,
                                      _myPos!.longitude,
                                      g.lat,
                                      g.lng,
                                    ),
                                  ),
                                if (here.isNotEmpty)
                                  '💪 ${here.length} buddy here',
                                if (g.address != null) g.address!,
                              ].join(' · '),
                              style: AppTextStyles.caption(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.pop(sheet);
                              _map?.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(g.lat, g.lng),
                                  16,
                                ),
                              );
                              _openGym(g, here);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e is AppError ? e.message : 'Something went wrong'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Map ────────────────────────────────────────────────
  Set<Marker> get _markers {
    final markers = <Marker>{};
    final buddyByPlace = <String, List<BuddyCheckin>>{};
    for (final b in _buddies) {
      buddyByPlace.putIfAbsent(b.placeId, () => []).add(b);
    }
    final gyms = [..._gyms];
    // Buddies may be at gyms outside the current search area
    for (final b in _buddies) {
      if (!gyms.any((g) => g.placeId == b.placeId)) {
        gyms.add(
          Gym(
            placeId: b.placeId,
            name: b.gymName,
            address: b.address,
            lat: b.lat,
            lng: b.lng,
          ),
        );
      }
    }
    for (final g in gyms) {
      final here = buddyByPlace[g.placeId] ?? g.buddiesHere;
      final mine = _myCheckin?.placeId == g.placeId;
      markers.add(
        Marker(
          markerId: MarkerId(g.placeId),
          position: LatLng(g.lat, g.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            mine
                ? BitmapDescriptor.hueGreen
                : here.isNotEmpty
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueAzure,
          ),
          zIndex: here.isNotEmpty || mine ? 2 : 1,
          infoWindow: InfoWindow(
            title: g.name,
            snippet: here.isNotEmpty
                ? '💪 ${here.length} buddy${here.length > 1 ? 's' : ''} here now'
                : (g.rating != null ? '⭐ ${g.rating}' : null),
          ),
          onTap: () => _openGym(g, here),
        ),
      );
    }
    return markers;
  }

  void _onCameraMove(CameraPosition p) => _cameraCenter = p.target;

  void _onCameraIdle() {
    final moved = Geolocator.distanceBetween(
      _lastFetchCenter.latitude,
      _lastFetchCenter.longitude,
      _cameraCenter.latitude,
      _cameraCenter.longitude,
    );
    if (moved > 1500 && !_showSearchArea && mounted) {
      setState(() => _showSearchArea = true);
    }
  }

  void _focusBuddy(BuddyCheckin b) {
    _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(b.lat, b.lng), 15));
    final gym = _gyms.firstWhere(
      (g) => g.placeId == b.placeId,
      orElse: () => Gym(
        placeId: b.placeId,
        name: b.gymName,
        address: b.address,
        lat: b.lat,
        lng: b.lng,
      ),
    );
    _openGym(gym, _buddies.where((x) => x.placeId == b.placeId).toList());
  }

  void _openGym(Gym gym, List<BuddyCheckin> here) {
    final mine = _myCheckin?.placeId == gym.placeId;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(gym.name, style: AppTextStyles.h3()),
              const SizedBox(height: 4),
              Wrap(
                spacing: 10,
                children: [
                  if (gym.rating != null)
                    Text(
                      '⭐ ${gym.rating} (${gym.ratingCount})',
                      style: AppTextStyles.bodySM(color: AppColors.warning),
                    ),
                  if (gym.openNow != null)
                    Text(
                      gym.openNow! ? '🟢 Open now' : '🔴 Closed',
                      style: AppTextStyles.bodySM(),
                    ),
                ],
              ),
              if (gym.address != null) ...[
                const SizedBox(height: 4),
                Text(gym.address!, style: AppTextStyles.caption()),
              ],
              if (_myPos != null) ...[
                const SizedBox(height: 4),
                Text(
                  '📍 ${formatDistance(distanceMeters(_myPos!.latitude, _myPos!.longitude, gym.lat, gym.lng))} away',
                  style: AppTextStyles.caption(color: AppColors.teal),
                ),
              ],
              if (here.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Buddies here now', style: AppTextStyles.label()),
                const SizedBox(height: 8),
                ...here.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        AppAvatar(
                          name: b.name ?? 'Buddy',
                          imageUrl: b.avatarUrl,
                          size: 32,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            b.firstName ?? b.name ?? 'Buddy',
                            style: AppTextStyles.body(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${b.timeLeft.inMinutes}m left',
                          style: AppTextStyles.caption(color: AppColors.teal),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: mine ? '✓ Checked in' : '📍 Check in here',
                      height: 46,
                      onPressed: mine
                          ? null
                          : () {
                              Navigator.pop(sheet);
                              _checkIn(gym);
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GhostButton(
                      label: 'Directions',
                      icon: Icons.directions,
                      height: 46,
                      onPressed: () => launchUrl(
                        directionsUri(gym),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: GhostButton(
                  label: 'Plan a session here',
                  icon: Icons.event_available,
                  height: 46,
                  onPressed: () {
                    Navigator.pop(sheet);
                    MonitoringService.instance.log('plan_from_map');
                    context.push(
                      AppRoutes.scheduleSession,
                      extra: {'gymName': gym.name},
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _myPos ?? _india,
              zoom: 14,
            ),
            onMapCreated: (c) {
              _map = c;
              if (_myPos != null)
                c.moveCamera(CameraUpdate.newLatLngZoom(_myPos!, 14));
            },
            markers: _markers,
            myLocationEnabled: !_locationDenied,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            style: _darkMapStyle,
          ),

          // ── Top bar: back + search ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _RoundButton(
                        icon: Icons.arrow_back,
                        onTap: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surface1.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.border2),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            textInputAction: TextInputAction.search,
                            style: AppTextStyles.body(
                              color: AppColors.textPrimary,
                            ),
                            onSubmitted: (q) =>
                                _loadGyms(_cameraCenter, query: q.trim()),
                            decoration: InputDecoration(
                              hintText: 'Search gyms (e.g. Gold\'s, Cult)…',
                              hintStyle: AppTextStyles.bodySM(),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoundButton(icon: Icons.list_rounded, onTap: _showList),
                      const SizedBox(width: 8),
                      _RoundButton(
                        icon: Icons.my_location,
                        onTap: () async {
                          final p = _myPos ?? await _locate();
                          if (p == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Allow location access to see gyms near you',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          setState(() {
                            _myPos = p;
                            _locationDenied = false;
                          });
                          _map?.animateCamera(
                            CameraUpdate.newLatLngZoom(p, 14),
                          );
                          _loadGyms(p);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_myCheckin != null && _myCheckin!.isActive)
                    _MyCheckinBanner(checkin: _myCheckin!, onEnd: _checkOut),
                  if (_notConfigured)
                    const _InfoPill(
                      text:
                          '🛠 Gym list is unavailable right now — try again later',
                    ),
                  if (!_loading &&
                      _error == null &&
                      _gyms.isEmpty &&
                      !_notConfigured)
                    _InfoPill(
                      text:
                          'No gyms found here — move the map and tap "Search this area"',
                      onTap: () => _loadGyms(_cameraCenter),
                    ),
                  if (_error != null)
                    _InfoPill(
                      text: _error!,
                      onTap: () => _loadGyms(_cameraCenter),
                    ),
                  if (_showSearchArea && !_loading)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: ActionChip(
                        backgroundColor: AppColors.primary,
                        label: Text(
                          'Search this area',
                          style: AppTextStyles.bodySM(
                            color: Colors.black,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => _loadGyms(_cameraCenter),
                      ),
                    ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── OpenStreetMap credit (required by its licence) ──
          if (needsOsmCredit(_gyms))
            Positioned(
              right: 8,
              bottom: _buddies.isEmpty ? 70 : 104,
              child: Text(
                'Gym data © OpenStreetMap contributors',
                style: AppTextStyles.caption().copyWith(fontSize: 10),
              ),
            ),

          // ── Bottom: buddies training now ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _buddies.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: _InfoPill(
                        text: _locationDenied
                            ? '📍 Location is off — turn it on to see gyms near you'
                            : '💡 Tap a gym to check in — your buddies will be notified',
                      ),
                    )
                  : SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        itemCount: _buddies.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final b = _buddies[i];
                          return GestureDetector(
                            onTap: () => _focusBuddy(b),
                            child: Container(
                              width: 210,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface1.withOpacity(0.96),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.warning.withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  AppAvatar(
                                    name: b.name ?? 'Buddy',
                                    imageUrl: b.avatarUrl,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          b.firstName ?? b.name ?? 'Buddy',
                                          style: AppTextStyles.subtitle(
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '💪 ${b.gymName}',
                                          style: AppTextStyles.caption(
                                            color: AppColors.warning,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${b.timeLeft.inMinutes}m left',
                                          style: AppTextStyles.caption(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface1.withOpacity(0.95),
    shape: const CircleBorder(side: BorderSide(color: AppColors.border2)),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    ),
  );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface1.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border2),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySM(color: AppColors.textSecondary),
      ),
    ),
  );
}

class _MyCheckinBanner extends StatelessWidget {
  const _MyCheckinBanner({required this.checkin, required this.onEnd});

  final BuddyCheckin checkin;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final left = checkin.timeLeft;
    final label = left.inHours > 0
        ? '${left.inHours}h ${left.inMinutes.remainder(60)}m'
        : '${left.inMinutes}m';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.teal.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.teal.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Text('📍', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Checked in at ${checkin.gymName} · $label left',
              style: AppTextStyles.bodySM(
                color: AppColors.textPrimary,
              ).copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(onPressed: onEnd, child: const Text('End')),
        ],
      ),
    );
  }
}

// Dark map to match the app theme
const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#111827"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a94a6"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0a0f1c"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1f2937"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2a3448"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0b1726"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]}
]
''';
