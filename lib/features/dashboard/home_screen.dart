import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:seshlly/features/dashboard/challanges/presentation/bloc/challenge_bloc.dart';
import 'package:seshlly/features/dashboard/session/presentation/bloc/session_bloc.dart';
import 'package:seshlly/features/dashboard/session/presentation/bloc/session_event.dart';
import 'package:seshlly/routes/app_router.dart';

import '../../core/services/monitoring_service.dart';
import '../../core/services/push_service.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../di_injection/dependency_injection.dart';
import 'chat/data/repositories/chat_repository.dart';
import 'challanges/presentation/bloc/challenge_event.dart';
import 'chat/presentation/bloc/chat_bloc.dart';
import 'chat/presentation/bloc/match_request_bloc.dart';
import 'chat/presentation/screen/chats_list_screen.dart';
import 'discover/presentation/bloc/discover_bloc.dart';
import 'discover/presentation/bloc/discover_event.dart';
import 'profile/presentation/bloc/profile_bloc.dart';
import 'profile/presentation/bloc/profile_event.dart';
import 'session/data/repositories/session_repository.dart';
import 'session/data/response_ml/pending_proof_confirm.dart';
import 'session/presentation/widgets/proof_confirm_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Provide feature BLoCs scoped to the shell route lifetime
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) =>
              getIt<DiscoverBloc>()
                ..add(const DiscoverProfilesLoaded())
                ..add(const DiscoverBoostStatusRequested()),
        ),
        MultiBlocProvider(
          providers: [
            BlocProvider<ChatBloc>(
              create: (_) => getIt<ChatBloc>()..add(const ChatListLoaded()),
            ),
            BlocProvider<MatchRequestBloc>(
              create: (_) => getIt<MatchRequestBloc>(),
            ),
          ],
          child: const ChatsListScreen(),
        ),

        BlocProvider(
          create: (ctx) => getIt<SessionBloc>()..add(const SessionsLoaded()),
        ),
        BlocProvider(
          create: (ctx) =>
              getIt<ChallengeBloc>()..add(const ChallengesLoaded()),
        ),
        BlocProvider(
          create: (ctx) => getIt<ProfileBloc>()..add(const ProfileLoaded()),
        ),
      ],
      child: _HomeShell(child: child),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({required this.child});

  final Widget child;

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> with WidgetsBindingObserver {
  List<PendingProofConfirm> _pendingProofs = const [];
  StreamSubscription<Map<String, dynamic>>? _tapSub;
  StreamSubscription<RemoteMessage>? _fgSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Analytics / crash reports: tie to this user (ID only)
    MonitoringService.instance.setUser(context.read<AuthBloc>().state.user?.id);

    // Push: register token (logged-in area) + react to taps / foreground
    final push = PushService.instance;
    push.registerToken();
    _tapSub = push.onTap.listen(_handlePushTap);
    _fgSub = push.onForeground.listen(_handleForegroundPush);
    final initialTap = push.takeInitialTap();
    if (initialTap != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _handlePushTap(initialTap));
    }

    _loadPendingProofs();
    _loadUnread();
  }

  // Unread CHAT messages for the Chats tab badge. (It used to read a brand
  // new, never-loaded NotificationBloc from getIt — so it was always 0.)
  int _unreadChats = 0;
  Future<void> _loadUnread() async {
    try {
      final chats = await getIt<ChatRepository>().getChats();
      final n = chats.fold<int>(0, (sum, c) => sum + ((c['unreadCount'] as num?)?.toInt() ?? 0));
      if (mounted && n != _unreadChats) setState(() => _unreadChats = n);
    } catch (_) {/* badge is best-effort */}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapSub?.cancel();
    _fgSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPendingProofs();
      _loadUnread();
    }
  }

  // GET /sessions/pending-confirm → banner
  Future<void> _loadPendingProofs() async {
    try {
      final list = await getIt<SessionRepository>().getPendingConfirmations();
      if (mounted) {
        setState(() => _pendingProofs = list.where((p) => !p.isExpired).toList());
      }
    } catch (_) {
      // banner is best-effort
    }
  }

  Future<void> _openProof(PendingProofConfirm item) async {
    await showProofConfirmSheet(context, item);
    _loadPendingProofs();
  }

  Future<void> _openProofById(String sessionId) async {
    await _loadPendingProofs();
    if (!mounted) return;
    final match = _pendingProofs.where((p) => p.sessionId == sessionId);
    if (match.isNotEmpty) {
      _openProof(match.first);
    } else {
      context.push(AppRoutes.notifications);
    }
  }

  // Notification tapped → go to the right place
  void _handlePushTap(Map<String, dynamic> data) {
    if (!mounted) return;
    final kind = data['kind']?.toString();
    final sessionId = data['sessionId']?.toString();
    if (kind == 'proof_confirm' && sessionId != null) {
      _openProofById(sessionId);
    } else if (data['chatId'] != null) {
      context.go(AppRoutes.chats);
    } else {
      context.push(AppRoutes.notifications);
    }
  }

  // Notification while app is open → small snackbar (+ refresh banner)
  void _handleForegroundPush(RemoteMessage m) {
    if (!mounted) return;
    final data = Map<String, dynamic>.from(m.data);
    if (data['kind'] == 'proof_confirm') _loadPendingProofs();
    if (data['type'] == 'chat') _loadUnread();
    final title = m.notification?.title;
    if (title == null) return;
    // Chat messages already show live in the chat screen
    if (data['type'] == 'chat') return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          m.notification?.body != null ? '$title\n${m.notification!.body}' : title,
          maxLines: 3,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface3,
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => _handlePushTap(data),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final unread = _unreadChats;
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/chats')) currentIndex = 1;
    if (location.startsWith('/sessions')) currentIndex = 2;
    if (location.startsWith('/challenges')) currentIndex = 3;
    if (location.startsWith('/profile')) currentIndex = 4;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _pendingProofs.isEmpty
          ? child
          : Column(
              children: [
                // ── "Proof waiting for you" banner ──
                SafeArea(
                  bottom: false,
                  child: _PendingProofBanner(
                    items: _pendingProofs,
                    onTap: () => _openProof(_pendingProofs.first),
                  ),
                ),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: child,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) {
            _loadUnread();
            switch (i) {
              case 0:
                context.go(AppRoutes.home);
                break;
              case 1:
                context.go(AppRoutes.chats);
                break;
              case 2:
                context.go(AppRoutes.sessions);
                break;
              case 3:
                context.go(AppRoutes.challenges);
                break;
              case 4:
                context.go(AppRoutes.profile);
                break;
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: unread > 0
                  ? Badge(
                      label: Text('$unread'),
                      child: const Icon(Icons.chat_bubble_outline),
                    )
                  : const Icon(Icons.chat_bubble_outline),
              activeIcon: const Icon(Icons.chat_bubble),
              label: 'Chats',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Sessions',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Challenges',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner: "1 proof aapka wait kar raha hai" ──────────────
class _PendingProofBanner extends StatelessWidget {
  const _PendingProofBanner({required this.items, required this.onTap});

  final List<PendingProofConfirm> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final first = items.first;
    final count = items.length;
    final urgent = first.timeLeft.inMinutes < 15;
    final accent = urgent ? AppColors.error : AppColors.warning;
    return Material(
      color: accent.withOpacity(0.12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: accent.withOpacity(0.3))),
          ),
          child: Row(
            children: [
              const Text('📸', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? '${first.uploaderName ?? 'Your buddy'}\'s proof is waiting for you'
                          : '$count proofs are waiting for you',
                      style: AppTextStyles.bodySM(color: AppColors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${formatTimeLeft(first.timeLeft)} left · +${first.potentialXp} XP',
                      style: AppTextStyles.caption(color: accent),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Confirm',
                  style: AppTextStyles.bodySM(color: Colors.black)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
