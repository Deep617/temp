import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';

class UploadProofScreen extends StatefulWidget {
  const UploadProofScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<UploadProofScreen> createState() => _UploadProofScreenState();
}

class _UploadProofScreenState extends State<UploadProofScreen> {
  File? _image;

  Future<void> _pick(ImageSource src) async {
    final picked = await ImagePicker().pickImage(
      source: src,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) setState(() => _image = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionBloc, SessionState>(
      listener: (context, state) {
        if (state.status == SessionStatus.uploaded) {
          context.pop();
        }
        if (state.status == SessionStatus.failure && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.error!.message,
                style: AppTextStyles.bodySM(color: AppColors.error),
              ),
            ),
          );
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          title: Text('Upload Workout Proof', style: AppTextStyles.h3()),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('⏰', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload within 8 hours',
                            style: AppTextStyles.subtitle(
                              color: AppColors.warning,
                            ),
                          ),
                          Text(
                            'Late or missing proof deducts chat tokens.',
                            style: AppTextStyles.bodySM(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 24),

              if (state.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    state.error!.message,
                    style: AppTextStyles.bodySM(color: AppColors.error),
                  ),
                ),

              GestureDetector(
                onTap: () => _pick(ImageSource.gallery),
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _image != null
                          ? AppColors.primary.withOpacity(0.4)
                          : AppColors.border2,
                      width: 2,
                    ),
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            _image!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.textMuted,
                              size: 56,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to add photo',
                              style: AppTextStyles.subtitle(),
                            ),
                            Text(
                              'Show yourself at the gym or during workout',
                              style: AppTextStyles.bodySM(),
                            ),
                          ],
                        ),
                ),
              ).animate(delay: 100.ms).fadeIn(),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: '📷 Camera',
                      height: 44,
                      onPressed: () => _pick(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GhostButton(
                      label: '🖼 Gallery',
                      height: 44,
                      onPressed: () => _pick(ImageSource.gallery),
                    ),
                  ),
                ],
              ).animate(delay: 200.ms).fadeIn(),

              const Spacer(),

              PrimaryButton(
                label: '✅ Upload Proof (+50 XP)',
                loading: state.isUploading,
                disabled: _image == null,
                onPressed: () => context.read<SessionBloc>().add(
                  SessionProofUploaded(
                    sessionId: widget.sessionId,
                    imagePath: _image!.path,
                  ),
                ),
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 16),
              Text(
                'Your proof will be verified by our system and your buddy',
                style: AppTextStyles.bodySM(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
