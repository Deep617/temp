// ─────────────────────────────────────────────────────────
//  Blocked Users — Settings › Privacy › Blocked Users
//  GET /safety/blocked · DELETE /safety/block/:userId
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';
import '../../../../di_injection/dependency_injection.dart';
import '../../data/datasource/safety_remote_datasource.dart';
import '../../data/repositories/safety_repository.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<BlockedUser> _users = const [];
  bool _loading = true;
  String? _error;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await getIt<SafetyRepository>().getBlocked();
      if (mounted) setState(() { _users = list; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is AppError ? e.message : 'Could not load';
        });
      }
    }
  }

  Future<void> _unblock(BlockedUser u) async {
    setState(() => _busy.add(u.id));
    try {
      await getIt<SafetyRepository>().unblock(u.id);
      if (!mounted) return;
      setState(() {
        _users = _users.where((x) => x.id != u.id).toList();
        _busy.remove(u.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${u.name.split(' ').first} unblocked'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy.remove(u.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is AppError ? e.message : 'Could not unblock'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      backgroundColor: AppColors.bg,
      title: Text('Blocked Users', style: AppTextStyles.h3()),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _error != null
            ? Center(
                child: TextButton(onPressed: _load, child: Text('$_error — Retry')),
              )
            : _users.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'You haven\'t blocked anyone.',
                        style: AppTextStyles.body(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final u = _users[i];
                      final busy = _busy.contains(u.id);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            AppAvatar(name: u.name, imageUrl: u.avatarUrl, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(u.name,
                                  style: AppTextStyles.subtitle(
                                      color: AppColors.textPrimary)),
                            ),
                            TextButton(
                              onPressed: busy ? null : () => _unblock(u),
                              child: busy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Unblock'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
  );
}
