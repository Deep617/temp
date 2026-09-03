import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';

class VerifyPhotoScreen extends StatefulWidget {
  const VerifyPhotoScreen({super.key});
  @override
  State<VerifyPhotoScreen> createState() => _VerifyPhotoScreenState();
}

class _VerifyPhotoScreenState extends State<VerifyPhotoScreen> {
  final _picker    = ImagePicker();
  File?  _selfie;
  bool   _loading  = false;
  bool   _done     = false;
  String? _error;

  Future<void> _takeSelfie() async {
    final img = await _picker.pickImage(
      source:                 ImageSource.camera,
      preferredCameraDevice:  CameraDevice.front,
      imageQuality:           90,
    );
    if (img == null || !mounted) return;
    setState(() {
      _selfie = File(img.path);
      _error  = null;
    });
  }

  Future<void> _submit() async {
    if (_selfie == null) return;
    setState(() { _loading = true; _error = null; });

    try {
      // TODO: Upload selfie to backend
      // await profileRepo.submitPhotoVerification(_selfie!);
      await Future.delayed(const Duration(seconds: 2)); // placeholder
      if (mounted) setState(() { _loading = false; _done = true; });
    } catch (e) {
      if (mounted) {
        setState(() {
        _loading = false;
        _error   = 'Submission failed. Please try again.';
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        title: Text('Photo Verification',
            style: AppTextStyles.subtitle()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _done ? _buildDone() : _buildForm(),
      ),
    );
  }

  Widget _buildDone() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('✅', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 16),
        Text('Selfie Submitted!',
            style: AppTextStyles.h2()),
        const SizedBox(height: 8),
        Text(
          'We will verify your photo within 48 hours.\n'
              'You will get a notification once done.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body(color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Back to Profile',
          onPressed: () => context.pop(),
        ),
      ],
    ),
  );

  Widget _buildForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Instructions
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to verify:',
                style: AppTextStyles.subtitle()),
            const SizedBox(height: 8),
            _InstrRow('1.', 'Take a selfie in good lighting'),
            _InstrRow('2.', 'Face clearly visible, no filters'),
            _InstrRow('3.', 'Hold up ✌️ two fingers'),
            _InstrRow('4.', 'Match your profile photo'),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // Selfie preview
      GestureDetector(
        onTap: _takeSelfie,
        child: Container(
          height: 280,
          width:  double.infinity,
          decoration: BoxDecoration(
            color:        AppColors.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selfie != null
                  ? AppColors.primary
                  : AppColors.border,
              width: _selfie != null ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _selfie != null
              ? Image.file(_selfie!, fit: BoxFit.cover)
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_front,
                  color: AppColors.textMuted, size: 48),
              const SizedBox(height: 12),
              Text('Tap to take selfie',
                  style: AppTextStyles.body(
                      color: AppColors.textMuted)),
            ],
          ),
        ),
      ),

      if (_selfie != null) ...[
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: _takeSelfie,
            child: Text('Retake selfie',
                style: AppTextStyles.bodySM(
                    color: AppColors.primary)),
          ),
        ),
      ],

      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!,
            style: AppTextStyles.bodySM(color: AppColors.error)),
      ],

      const Spacer(),

      // Submit button
      PrimaryButton(
        label:    _loading ? 'Submitting...' : 'Submit for Verification',
        onPressed: (_selfie == null || _loading) ? null : _submit,
        height:   50,
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          'Verified within 48 hours',
          style: AppTextStyles.caption(color: AppColors.textMuted),
        ),
      ),
    ],
  );
}

class _InstrRow extends StatelessWidget {
  const _InstrRow(this.num, this.text);
  final String num, text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Text(num,
          style: AppTextStyles.bodySM(color: AppColors.primary)),
      const SizedBox(width: 8),
      Text(text,
          style: AppTextStyles.bodySM()),
    ]),
  );
}