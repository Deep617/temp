import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstCtrl, _lastCtrl, _usernameCtrl,
      _bioCtrl, _cityCtrl, _gymCtrl, _instagramCtrl;

  String?      _primaryActivity;
  List<String> _activities = [];
  String?      _level;
  List<String> _goals      = [];
  File?        _newAvatar;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _firstCtrl     = TextEditingController(text: user?.firstName       ?? '');
    _lastCtrl      = TextEditingController(text: user?.lastName        ?? '');
    _usernameCtrl  = TextEditingController(text: user?.username        ?? '');
    _bioCtrl       = TextEditingController(text: user?.bio             ?? '');
    _cityCtrl      = TextEditingController(text: user?.city            ?? '');
    _gymCtrl       = TextEditingController(text: user?.primaryGym      ?? '');
    _instagramCtrl = TextEditingController(text: user?.instagramHandle ?? '');
    _primaryActivity = user?.primaryActivity;
    _activities      = List.from(user?.activities     ?? []);
    _level           = user?.experienceLevel;
    _goals           = List.from(user?.goals          ?? []);
  }

  @override
  void dispose() {
    for (final c in [_firstCtrl, _lastCtrl, _usernameCtrl,
                     _bioCtrl, _cityCtrl, _gymCtrl, _instagramCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (picked != null) setState(() => _newAvatar = File(picked.path));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileBloc>().add(ProfileUpdated(
      avatarPath: _newAvatar?.path,
      data: {
        'firstName':       _firstCtrl.text.trim(),
        'lastName':        _lastCtrl.text.trim(),
        'username':        _usernameCtrl.text.trim().isNotEmpty  ? _usernameCtrl.text.trim()  : null,
        'bio':             _bioCtrl.text.trim().isNotEmpty        ? _bioCtrl.text.trim()        : null,
        'city':            _cityCtrl.text.trim().isNotEmpty       ? _cityCtrl.text.trim()       : null,
        'primaryGym':      _gymCtrl.text.trim().isNotEmpty        ? _gymCtrl.text.trim()        : null,
        'instagramHandle': _instagramCtrl.text.trim().isNotEmpty  ? _instagramCtrl.text.trim()  : null,
        'primaryActivity': _primaryActivity,
        'activities':      _activities,
        'experienceLevel': _level,
        'goals':           _goals,
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.isUpdated) {
          // Sync the updated user back into AuthBloc so the profile screen reflects changes
          if (state.user != null) {
            context.read<AuthBloc>().add(AuthUserUpdated(user: state.user!));
          }
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated! ✅', style: AppTextStyles.body())),
          );
        }
        if (state.status == ProfileStatus.failure && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!.message,
                style: AppTextStyles.bodySM(color: AppColors.error))),
          );
        }
      },
      builder: (context, state) {
        final user = context.watch<AuthBloc>().state.user;

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            title: Text('Edit Profile', style: AppTextStyles.h3()),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: state.isUpdating ? null : _save,
                  child: state.isUpdating
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary))
                      : Text('Save', style: AppTextStyles.subtitle(color: AppColors.primary)),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Error banner
                if (state.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Text(state.error!.message,
                        style: AppTextStyles.bodySM(color: AppColors.error)),
                  ),

                // ── Avatar ──────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(clipBehavior: Clip.none, children: [
                      _newAvatar != null
                          ? Container(
                              width: 96, height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 2),
                                image: DecorationImage(image: FileImage(_newAvatar!), fit: BoxFit.cover),
                              ))
                          : AppAvatar(name: user?.fullName ?? '', imageUrl: user?.avatarUrl, size: 96),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle,
                            border: Border.all(color: AppColors.bg, width: 2)),
                          child: const Icon(Icons.camera_alt, color: Colors.black, size: 15),
                        ),
                      ),
                    ]),
                  ),
                ).animate().scale(duration: 400.ms),

                const SizedBox(height: 28),

                // ── Basic Info ──────────────────────────
                Text('BASIC INFO', style: AppTextStyles.label()),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(child: AppInput(
                    label: 'First Name', controller: _firstCtrl,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: AppInput(
                    label: 'Last Name', controller: _lastCtrl,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  )),
                ]).animate(delay: 100.ms).fadeIn(),

                const SizedBox(height: 14),
                AppInput(
                  label: 'Username', hint: '@username',
                  controller: _usernameCtrl, prefixIcon: Icons.alternate_email,
                ).animate(delay: 120.ms).fadeIn(),

                const SizedBox(height: 14),
                AppInput(
                  label: 'Bio',
                  hint: 'Tell potential buddies about yourself...',
                  controller: _bioCtrl, maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ).animate(delay: 140.ms).fadeIn(),

                const SizedBox(height: 14),
                AppInput(
                  label: 'City', hint: 'Mumbai', controller: _cityCtrl,
                  prefixIcon: Icons.location_on_outlined,
                  textCapitalization: TextCapitalization.words,
                ).animate(delay: 160.ms).fadeIn(),

                const SizedBox(height: 14),
                AppInput(
                  label: 'Primary Gym', hint: "Gold's Gym, Andheri",
                  controller: _gymCtrl, prefixIcon: Icons.fitness_center,
                  textCapitalization: TextCapitalization.words,
                ).animate(delay: 180.ms).fadeIn(),

                const SizedBox(height: 28),

                // ── Fitness Info ────────────────────────
                Text('FITNESS INFO', style: AppTextStyles.label()),
                const SizedBox(height: 12),
                Text('Primary Activity', style: AppTextStyles.bodySM()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: AppConstants.activities.map((a) => ActivityChip(
                    activity: a,
                    selected: _primaryActivity == a['id'],
                    onTap: () => setState(() => _primaryActivity = a['id'] as String),
                  )).toList(),
                ).animate(delay: 200.ms).fadeIn(),

                const SizedBox(height: 18),
                Text('Experience Level', style: AppTextStyles.bodySM()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: AppConstants.levels.map((l) => GestureDetector(
                    onTap: () => setState(() => _level = l['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color:        _level == l['id'] ? AppColors.primary.withOpacity(0.15) : AppColors.surface2,
                        borderRadius: BorderRadius.circular(100),
                        border:       Border.all(color: _level == l['id'] ? AppColors.primary.withOpacity(0.4) : AppColors.border2),
                      ),
                      child: Text(l['label']!,
                          style: AppTextStyles.bodySM(color: _level == l['id'] ? AppColors.primary : AppColors.textSecondary)
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                  )).toList(),
                ).animate(delay: 220.ms).fadeIn(),

                const SizedBox(height: 18),
                Text('Goals (select all that apply)', style: AppTextStyles.bodySM()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: AppConstants.goals.map((g) {
                    final selected = _goals.contains(g['id']);
                    return GestureDetector(
                      onTap: () => setState(() =>
                          selected ? _goals.remove(g['id']) : _goals.add(g['id']!)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color:        selected ? AppColors.primary.withOpacity(0.15) : AppColors.surface2,
                          borderRadius: BorderRadius.circular(100),
                          border:       Border.all(color: selected ? AppColors.primary.withOpacity(0.4) : AppColors.border2),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(g['emoji']!, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(g['label']!,
                              style: AppTextStyles.bodySM(color: selected ? AppColors.primary : AppColors.textSecondary)
                                  .copyWith(fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    );
                  }).toList(),
                ).animate(delay: 240.ms).fadeIn(),

                const SizedBox(height: 28),

                // ── Social ──────────────────────────────
                Text('SOCIAL', style: AppTextStyles.label()),
                const SizedBox(height: 12),
                AppInput(
                  label: 'Instagram Handle', hint: '@yourhandle',
                  controller: _instagramCtrl, prefixIcon: Icons.camera_alt_outlined,
                ).animate(delay: 260.ms).fadeIn(),

                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Save Changes',
                  loading: state.isUpdating,
                  onPressed: _save,
                ).animate(delay: 280.ms).fadeIn().slideY(begin: 0.3),

                const SizedBox(height: 60),
              ]),
            ),
          ),
        );
      },
    );
  }
}
