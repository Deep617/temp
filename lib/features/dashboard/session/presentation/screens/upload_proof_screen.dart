import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seshlly/features/dashboard/session/data/repositories/session_repository.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../di_injection/dependency_injection.dart';
import '../../../challanges/data/repositories/challenge_repository.dart';
import '../../data/response_ml/workout_session.dart';

class UploadProofScreen extends StatefulWidget {
  const UploadProofScreen({
    super.key,
    required this.sessionId,
    required this.session,
  });

  final String sessionId;
  final WorkoutSession session;

  @override
  State<UploadProofScreen> createState() => _UploadProofScreenState();
}

class _UploadProofScreenState extends State<UploadProofScreen> {
  File? _image;
  bool _uploading = false;
  WorkoutSession? _session;
  bool _loadingSession = true;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  // Load session details to show info
  Future<void> _loadSession() async {
    try {
      final sessions = await getIt<SessionRepository>().getSessions(page: 1);
      if (!mounted) return;
      setState(() {
        try {
          _session = sessions.firstWhere((s) => s.id == widget.sessionId);
        } catch (_) {}
        _loadingSession = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSession = false);
    }
  }

  // Pick from gallery
  Future<void> _pickGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _image = File(picked.path));
    }
  }

  // Pick from camera
  Future<void> _pickCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _image = File(picked.path));
    }
  }

  // Upload proof → then show feed prompt
  Future<void> _upload() async {
    if (_image == null || _uploading) return;
    setState(() => _uploading = true);

    try {
      final api = getIt<SessionRepository>();

      // Upload proof image
      final updatedSession = await api.uploadProof(
        sessionId: widget.sessionId,
        imagePath: _image!.path,
      );

      if (!mounted) return;

      // Success snack
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Proof uploaded! +50 XP 🎉'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // ── Show "Post to Feed?" prompt ───────────────────
      // Proof photo is auto-attached — user just adds caption
      await showPostToFeedPrompt(
        context,
        session: updatedSession,
        // Pass challenge info if session is part of challenge
        challengeTitle: updatedSession.challengeTitle,
        challengeId: updatedSession.challengeId,
        stationNum: updatedSession.challengeStationNum ?? 0,
        stationTitle: updatedSession.challengeTitle != null
            ? 'Station ${updatedSession.challengeStationNum ?? 1}'
            : '${updatedSession.activity} Session',
        xpAwarded: updatedSession.xpEarned ?? 50,
        isGroup: updatedSession.buddyId != null,
      );

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Upload failed. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      backgroundColor: AppColors.surface1,
      title: Text('Upload Proof', style: AppTextStyles.h3()),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _uploading ? null : () => context.pop(),
      ),
    ),
    body: _loadingSession
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Session info card
                if (_session != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _activityEmoji(_session!.activity),
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _session!.activity,
                                style: AppTextStyles.subtitle(),
                              ),
                              if (_session!.buddyName != null)
                                Text(
                                  'with ${_session!.buddyName}',
                                  style: AppTextStyles.bodySM(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              Text(
                                _formatDate(_session!.scheduledAt),
                                style: AppTextStyles.bodySM(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // XP reward
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '+50 XP',
                            style: AppTextStyles.label(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),

                const SizedBox(height: 20),

                // Photo area
                Text('Session Photo', style: AppTextStyles.subtitle()),
                const SizedBox(height: 10),

                // Photo preview or picker
                GestureDetector(
                  onTap: _image == null ? _showPickerOptions : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _image != null
                            ? AppColors.primary.withOpacity(0.4)
                            : AppColors.border2,
                        width: _image != null ? 1.5 : 1,
                      ),
                    ),
                    child: _image != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(
                                  _image!,
                                  width: double.infinity,
                                  height: 220,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Change photo button
                              Positioned(
                                top: 10,
                                right: 10,
                                child: GestureDetector(
                                  onTap: _showPickerOptions,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Change',
                                          style: AppTextStyles.label(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_outlined,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Add Session Photo',
                                style: AppTextStyles.subtitle(
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Camera or Gallery',
                                style: AppTextStyles.bodySM(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 12),

                // Quick pick buttons (always visible)
                if (_image == null)
                  Row(
                    children: [
                      Expanded(
                        child: _PickButton(
                          icon: Icons.camera_alt_outlined,
                          label: 'Camera',
                          onTap: _pickCamera,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PickButton(
                          icon: Icons.photo_library_outlined,
                          label: 'Gallery',
                          onTap: _pickGallery,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 28),

                // Note about feed
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'After upload, you can share this to the Challenge Feed with your photo — visible for 24 hours.',
                          style: AppTextStyles.bodySM(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 180.ms),

                const SizedBox(height: 28),

                // Upload button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _image != null && !_uploading ? _upload : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.surface3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _uploading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('Uploading...', style: AppTextStyles.btn()),
                            ],
                          )
                        : Text(
                            _image != null
                                ? 'Upload Proof ✅'
                                : 'Select a photo first',
                            style: AppTextStyles.btn(),
                          ),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
  );

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
            Text('Select Photo', style: AppTextStyles.h3()),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
              title: Text('Camera', style: AppTextStyles.subtitle()),
              onTap: () {
                Navigator.pop(context);
                _pickCamera();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: Text('Gallery', style: AppTextStyles.subtitle()),
              onTap: () {
                Navigator.pop(context);
                _pickGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _activityEmoji(String activity) {
    const map = {
      'gym': '🏋️',
      'running': '🏃',
      'cycling': '🚴',
      'swimming': '🏊',
      'boxing': '🥊',
      'yoga': '🧘',
      'hiit': '💥',
      'crossfit': '🔥',
      'hyrox': '⚡',
      'climbing': '🧗',
      'tennis': '🎾',
    };
    return map[activity.toLowerCase()] ?? '💪';
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}

// ── Pick button widget ─────────────────────────────────────
class _PickButton extends StatelessWidget {
  const _PickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodySM(
              color: AppColors.primary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

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
