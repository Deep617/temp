import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../../di_injection/dependency_injection.dart';
import '../../../challanges/data/repositories/challenge_repository.dart';
import '../../data/response_ml/workout_session.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';

class UploadProofScreen extends StatefulWidget {
  const UploadProofScreen({
    super.key,
    required this.sessionId,
    required this.session,
  });

  final WorkoutSession session;
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
      builder: (context, state) {
        if (state.status == SessionStatus.uploaded) {
          showPostToFeedPrompt(context, session: widget.session);
        }
        return Scaffold(
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
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
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
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                      ),
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
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
//  POST-SESSION FEED PROMPT
//  Show this dialog after session proof upload
//  Usage: showPostToFeedPrompt(context, session, challengeEntry)
// ══════════════════════════════════════════════════════════
Future<void> showPostToFeedPrompt(
  BuildContext context, {
  required WorkoutSession session,
  String? challengeTitle,
  String? challengeId,
  int stationNum = 0,
  String stationTitle = 'Session Complete',
  int xpAwarded = 50,
  bool isGroup = false,
}) async {
  if (!context.mounted) return;

  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surface1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PostToFeedSheet(
      session: session,
      challengeTitle: challengeTitle,
      challengeId: challengeId,
      stationNum: stationNum,
      stationTitle: stationTitle,
      xpAwarded: xpAwarded,
      isGroup: isGroup,
    ),
  );

  // result = true means user tapped "Post"
  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Posted to challenge feed! 🎉'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _PostToFeedSheet extends StatefulWidget {
  const _PostToFeedSheet({
    required this.session,
    required this.stationTitle,
    required this.xpAwarded,
    required this.isGroup,
    this.challengeTitle,
    this.challengeId,
    this.stationNum = 0,
  });

  final WorkoutSession session;
  final String? challengeTitle;
  final String? challengeId;
  final int stationNum;
  final String stationTitle;
  final int xpAwarded;
  final bool isGroup;

  @override
  State<_PostToFeedSheet> createState() => _PostToFeedSheetState();
}

class _PostToFeedSheetState extends State<_PostToFeedSheet> {
  final _captionCtrl = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    setState(() => _posting = true);
    try {
      final challengeRepository = getIt<ChallengeRepository>();
      challengeRepository.postToFeed({
        'challengeId': widget.challengeId ?? widget.session.id,
        'stationNum': widget.stationNum,
        'stationTitle': widget.stationTitle,
        'xpAwarded': widget.xpAwarded,
        'proofImageUrl': widget.session.proofImageUrl,
        'isCollab': widget.session.buddyId != null,
        'caption': _captionCtrl.text.trim().isEmpty
            ? null
            : _captionCtrl.text.trim(),
        if (widget.session.buddyId != null) ...{
          'collabUserId': widget.session.buddyId,
        },
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() => _posting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to post. Try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 20,
      right: 20,
      top: 20,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.border2,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Trophy animation
        const Text('🏆', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Text('Share to Feed?', style: AppTextStyles.h3()),
        const SizedBox(height: 6),
        Text(
          'Your achievement disappears after 24 hours',
          style: AppTextStyles.bodySM(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // What will be posted preview
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border2),
          ),
          child: Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.challengeTitle != null
                          ? '${widget.challengeTitle} • ${widget.stationTitle}'
                          : widget.stationTitle,
                      style: AppTextStyles.bodySM(),
                    ),
                    Text(
                      '+${widget.xpAwarded} XP earned',
                      style: AppTextStyles.bodySM(color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Caption field
        TextField(
          controller: _captionCtrl,
          style: AppTextStyles.body(),
          maxLines: 2,
          maxLength: 140,
          decoration: InputDecoration(
            hintText: 'Add a caption (optional)...',
            hintStyle: AppTextStyles.bodySM(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface2,
            counterStyle: AppTextStyles.caption(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(
                  'Skip',
                  style: AppTextStyles.btn(color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _posting ? null : _post,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: _posting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('Post to Feed 🔥', style: AppTextStyles.btn()),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
