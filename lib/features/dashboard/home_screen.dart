import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:seshlly/routes/app_router.dart';

import '../../core/theme/app_colors.dart';
import '../../di_injection/dependency_injection.dart';
import '../auth/domain/repositories/profile_repository.dart';
import '../auth/presentation/bloc/profile_bloc.dart';
import '../auth/presentation/bloc/profile_event.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Provide feature BLoCs scoped to the shell route lifetime
    return MultiBlocProvider(
      providers: [
       /* BlocProvider(
          create: (ctx) => DiscoverBloc(
            discoverRepository: ctx.read<DiscoverRepository>(),
          )..add(const DiscoverProfilesLoaded()),
        ),
        BlocProvider(
          create: (ctx) => SessionBloc(
            sessionRepository: ctx.read<SessionRepository>(),
          )..add(const SessionsLoaded()),
        ),
        BlocProvider(
          create: (ctx) => ChatBloc(
            chatRepository: ctx.read<ChatRepository>(),
          )..add(const ChatListLoaded()),
        ),*/
        BlocProvider(
          create: (ctx) => getIt<ProfileBloc>()..add(const ProfileLoaded()),
        ),
      ],
      child: _HomeShell(child: child),
    );
  }
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
   // final unread = context.watch<NotificationBloc>().state.unreadCount;
    final unread = 3;
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/chats'))    currentIndex = 1;
    if (location.startsWith('/sessions')) currentIndex = 2;
    if (location.startsWith('/profile'))  currentIndex = 3;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) {
            switch (i) {
              case 0: context.go(AppRoutesPath.home);     break;
              case 1: context.go(AppRoutesPath.chats);    break;
              case 2: context.go(AppRoutesPath.sessions); break;
              case 3: context.go(AppRoutesPath.profile);  break;
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: unread > 0
                  ? Badge(label: Text('\$unread'), child: const Icon(Icons.chat_bubble_outline))
                  : const Icon(Icons.chat_bubble_outline),
              activeIcon: const Icon(Icons.chat_bubble),
              label: 'Chats',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined), activeIcon: Icon(Icons.fitness_center), label: 'Sessions',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
