import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';

class VerifyIdScreen extends StatefulWidget {
  const VerifyIdScreen({super.key});
  @override
  State<VerifyIdScreen> createState() => _VerifyIdScreenState();
}

class _VerifyIdScreenState extends State<VerifyIdScreen> {
  final _picker  = ImagePicker();
  File?  _idDoc;
  String _idType = 'Aadhaar';
  bool   _loading = false;
  bool   _done    = false;
  String? _error;

  Future<void> _pickId() async {
    final img = await _picker.pickImage(
      source:       ImageSource.gallery,
      imageQuality: 90,
    );
    if (img == null || !mounted) return;
    setState(() { _idDoc = File(img.path); _error = null; });
  }

  Future<void> _submit() async {
    if (_idDoc == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      // TODO: Upload to backend
      // await profileRepo.submitIdVerification(_idDoc!, _idType);
      await Future.delayed(const Duration(seconds: 2));
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
        title: Text('ID Verification',
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
        Text('ID Submitted!', style: AppTextStyles.h2()),
        const SizedBox(height: 8),
        Text(
          'Admin will verify your ID within 48 hours.\n'
              'You will get a notification once approved.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body(color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label:     'Back to Profile',
          onPressed: () => context.pop(),
        ),
      ],
    ),
  );

  Widget _buildForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ID type selector
      Text('Select ID Type',
          style: AppTextStyles.subtitle()),
      const SizedBox(height: 10),
      Row(
        children: ['Aadhaar', 'PAN', 'Passport'].map((type) {
          final selected = _idType == type;
          return GestureDetector(
            onTap: () => setState(() => _idType = type),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryDim
                    : AppColors.surface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Text(type,
                  style: AppTextStyles.bodySM(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  )),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),

      // Upload area
      Text('Upload $_idType Photo',
          style: AppTextStyles.subtitle()),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _pickId,
        child: Container(
          height: 200,
          width:  double.infinity,
          decoration: BoxDecoration(
            color:        AppColors.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _idDoc != null
                  ? AppColors.primary
                  : AppColors.border,
              width: _idDoc != null ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _idDoc != null
              ? Image.file(_idDoc!, fit: BoxFit.cover)
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.upload_file,
                  color: AppColors.textMuted, size: 40),
              const SizedBox(height: 10),
              Text('Upload clear photo of your $_idType',
                  style: AppTextStyles.bodySM(
                      color: AppColors.textMuted),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),

      const SizedBox(height: 12),
      // Privacy note
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Text('🔒', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your ID is only used for verification '
                    'and is never shared with other users.',
                style: AppTextStyles.caption(
                    color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),

      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!,
            style: AppTextStyles.bodySM(color: AppColors.error)),
      ],

      const Spacer(),

      PrimaryButton(
        label:     _loading ? 'Submitting...' : 'Submit for Verification',
        onPressed: (_idDoc == null || _loading) ? null : _submit,
        height:    50,
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          'Verified within 48 hours · 🔒 Secure',
          style: AppTextStyles.caption(color: AppColors.textMuted),
        ),
      ),
    ],
  );
}