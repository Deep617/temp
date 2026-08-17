// ─────────────────────────────────────────────────────────
//  influencer_apply_screen.dart
//  User applies as influencer — IG handle + code display
//  Navigate: context.push(AppRoutes.influencerApply)
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seshlly/features/auth/domain/repositories/auth_repository.dart';
import '../../../../di_injection/dependency_injection.dart';
import '../../data/response_ml/register_response.dart';

class InfluencerApplyScreen extends StatefulWidget {
  const InfluencerApplyScreen({super.key});

  @override
  State<InfluencerApplyScreen> createState() => _InfluencerApplyScreenState();
}

class _InfluencerApplyScreenState extends State<InfluencerApplyScreen> {
  final _handleCtrl    = TextEditingController();
  final _followersCtrl = TextEditingController();

  InfluencerApplicationStatus? _status;
  bool _loading  = true;
  bool _submitting = false;
  bool _markedAdded = false;
  String? _error;
late AuthRepository _authRepository;
  @override
  void initState() {
    super.initState();
    _authRepository = getIt<AuthRepository>();

    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final s = await _authRepository.getInfluencerStatus();
      if (mounted) setState(() { _status = s; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final handle    = _handleCtrl.text.trim().replaceAll('@', '');
    final followers = int.tryParse(_followersCtrl.text.trim()) ?? 0;

    if (handle.isEmpty)        { setState(() => _error = 'Instagram username required'); return; }
    if (followers < 50000)     { setState(() => _error = 'Minimum 50,000 followers required'); return; }

    setState(() { _submitting = true; _error = null; });
    try {
      await _authRepository.applyAsInfluencer(
        instagramHandle:  handle,
        claimedFollowers: followers,
      );
      await _loadStatus();
    } catch (e) {
      setState(() { _error = e.toString(); _submitting = false; });
    }
  }

  Future<void> _markCodeAdded() async {
    setState(() => _submitting = true);
    try {
      await _authRepository.markInfluencerCodeAdded();
      setState(() { _markedAdded = true; _submitting = false; });
      await _loadStatus();
    } catch (e) {
      setState(() { _error = e.toString(); _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07090F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white54, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Apply as Influencer',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A84FF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildBody(),
            ),
    );
  }

  Widget _buildBody() {
    // Already approved
    if (_status?.isApproved == true) {
      return _buildApprovedState();
    }

    // Has pending/code_added application
    if (_status?.applied == true && (_status!.isPending || _status!.isCodeAdded)) {
      return _buildCodeState();
    }

    // Rejected
    if (_status?.isRejected == true) {
      return _buildRejectedState();
    }

    // Apply form
    return _buildApplyForm();
  }

  // ── Apply Form ────────────────────────────────────────────
  Widget _buildApplyForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withOpacity(0.08),
          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            const Text('Become a Seshlly Influencer',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('50,000+ Instagram followers required',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          ],
        ),
      ),

      const SizedBox(height: 24),

      // Requirements
      ...[
        ('50K+ Instagram followers', '✅'),
        ('Public fitness account', '✅'),
        ('Elite plan subscription', '✅'),
        ('Admin approval (48 hrs)', '✅'),
      ].map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Text(e.$2, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(e.$1, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
          ],
        ),
      )),

      const SizedBox(height: 24),

      // Form
      _buildLabel('Instagram Username'),
      const SizedBox(height: 6),
      _buildInput(_handleCtrl, '@fitness_rahul', TextInputType.text),

      const SizedBox(height: 16),
      _buildLabel('Your Follower Count'),
      const SizedBox(height: 6),
      _buildInput(_followersCtrl, '87000', TextInputType.number),

      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 13)),
      ],

      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _submitting ? 'Submitting...' : 'Submit Application',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    ],
  );

  // ── Code Verification State ───────────────────────────────
  Widget _buildCodeState() {
    final code    = _status?.verificationCode ?? '';
    final expiry  = _status?.codeExpiresIn   ?? '';
    final handle  = _status?.instagramHandle ?? '';
    final added   = _status?.isCodeAdded == true || _markedAdded;

    return Column(
      children: [
        // Status header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0A84FF).withOpacity(0.08),
            border: Border.all(color: const Color(0xFF0A84FF).withOpacity(0.2)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Text('⭐ Application Submitted',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                added ? 'Under review • Admin will verify within 48 hours'
                      : 'Add the code below to your Instagram bio',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        if (!added) ...[
          // Code card
          const Text('Add this to your Instagram bio:',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF141C2E),
              border: Border.all(color: const Color(0xFF0A84FF).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(code,
                    style: const TextStyle(
                      color: Color(0xFF0A84FF),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      fontFamily: 'monospace',
                    )),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied!')),
                    );
                  },
                  child: const Icon(Icons.copy_outlined,
                      color: Color(0xFF0A84FF), size: 20),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          if (expiry.isNotEmpty)
            Text('Expires in: $expiry',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),

          const SizedBox(height: 20),

          // Steps
          ...[
            'Open Instagram',
            'Tap Edit Profile',
            'Paste the code in Bio section',
            'Save → Come back here',
          ].asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0A84FF).withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text('${e.key + 1}',
                        style: const TextStyle(
                          color: Color(0xFF0A84FF), fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(e.value,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
              ],
            ),
          )),

          const SizedBox(height: 20),

          // Open Instagram button
          OutlinedButton.icon(
            onPressed: () {
              // Launch instagram.com/handle
              // url_launcher use karo
            },
            icon: const Text('📸'),
            label: Text('Open Instagram @$handle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withOpacity(0.15)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 12),

          // Mark added button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _markCodeAdded,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D0A3),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _submitting ? 'Saving...' : "I've added it ✓",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ] else ...[
          // Already marked added
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00D0A3).withOpacity(0.08),
              border: Border.all(color: const Color(0xFF00D0A3).withOpacity(0.25)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '✅ Code marked as added\nAdmin will verify your profile within 48 hours.',
              style: TextStyle(color: Color(0xFF00D0A3), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  // ── Approved State ────────────────────────────────────────
  Widget _buildApprovedState() => Column(
    children: [
      const SizedBox(height: 40),
      const Text('🎉', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 16),
      const Text("You're a Seshlly Influencer!",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('Your profile is now live in the Influencer discover section.',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          textAlign: TextAlign.center),
    ],
  );

  // ── Rejected State ────────────────────────────────────────
  Widget _buildRejectedState() => Column(
    children: [
      const SizedBox(height: 40),
      const Text('😔', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 16),
      const Text('Application Not Approved',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
      if (_status?.rejectedReason != null) ...[
        const SizedBox(height: 8),
        Text(_status!.rejectedReason!,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            textAlign: TextAlign.center),
      ],
      if (_status?.canReapplyAt != null) ...[
        const SizedBox(height: 16),
        Text('You can reapply after ${_status!.canReapplyAt}',
            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 13)),
      ],
    ],
  );

  Widget _buildLabel(String text) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: Colors.white.withOpacity(0.4),
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: .5,
    ),
  );

  Widget _buildInput(TextEditingController ctrl, String hint, TextInputType type) =>
    TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
        filled: true,
        fillColor: const Color(0xFF141C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0A84FF)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

  @override
  void dispose() {
    _handleCtrl.dispose();
    _followersCtrl.dispose();
    super.dispose();
  }
}
