import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// ─────────────────────────────────────────────────────────
//  SeshCameraView — full screen in-app camera (camera package)
//  Used by: Sesh Flash (chat) and Session Proof (camera-only).
//  Camera is only initialised while [active] is true and is
//  released when inactive / app goes to background.
// ─────────────────────────────────────────────────────────
class SeshCameraView extends StatefulWidget {
  const SeshCameraView({
    super.key,
    required this.active,
    required this.title,
    required this.onClose,
    required this.onCapture,
    this.badge,
    this.onGallery, // null → no gallery button (proof = live photo only)
  });

  final bool active;
  final String title;
  final String? badge;
  final VoidCallback onClose;
  final void Function(File) onCapture;
  final VoidCallback? onGallery;

  @override
  State<SeshCameraView> createState() => _SeshCameraViewState();
}

class _SeshCameraViewState extends State<SeshCameraView>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _initializing = false;
  bool _capturing = false;
  String? _cameraError;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.active) _startCamera();
  }

  @override
  void didUpdateWidget(covariant SeshCameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _startCamera();
    } else if (!widget.active && oldWidget.active) {
      _stopCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.active) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (_initializing || (_controller?.value.isInitialized ?? false)) return;
    setState(() {
      _initializing = true;
      _cameraError = null;
    });
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('NoCamera', 'No camera found on this device');
      }
      // Prefer the back camera first
      if (_cameraIndex == 0) {
        final back = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        if (back >= 0) _cameraIndex = back;
      }
      await _initController(_cameras[_cameraIndex]);
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _cameraError = e.code == 'CameraAccessDenied'
            ? 'Camera permission denied'
            : (e.description ?? 'Camera unavailable'));
      }
    } catch (_) {
      if (mounted) setState(() => _cameraError = 'Camera unavailable');
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _initController(CameraDescription description) async {
    final old = _controller;
    _controller = null;
    if (mounted) setState(() {});
    await old?.dispose();

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false, // photo only — no mic prompt
    );
    await controller.initialize();
    try {
      await controller.setFlashMode(_flashMode);
    } catch (_) {
      // Front cameras often don't support flash — ignore
    }
    if (!mounted || !widget.active) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  Future<void> _stopCamera() async {
    final old = _controller;
    if (old == null) return;
    if (mounted) setState(() => _controller = null);
    await old.dispose();
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _initializing || _capturing) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    setState(() => _initializing = true);
    try {
      await _initController(_cameras[_cameraIndex]);
    } catch (_) {
      if (mounted) setState(() => _cameraError = 'Could not switch camera');
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _toggleFlash() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final next = switch (_flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      _ => FlashMode.off,
    };
    try {
      await c.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } catch (_) {
      // Lens without flash
    }
  }

  Future<void> _capture() async {
    final c = _controller;
    if (_capturing) return;

    // Fallback: no live preview → system camera (old behaviour)
    if (c == null || !c.value.isInitialized) {
      final img = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (img != null) widget.onCapture(File(img.path));
      return;
    }
    if (c.value.isTakingPicture) return;

    setState(() => _capturing = true);
    try {
      final shot = await c.takePicture();
      if (!mounted) return;
      widget.onCapture(File(shot.path));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not capture photo. Try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  IconData get _flashIcon => switch (_flashMode) {
        FlashMode.auto => Icons.flash_auto,
        FlashMode.always => Icons.flash_on,
        _ => Icons.flash_off,
      };

  Widget _buildViewfinder() {
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      // Fill the screen (cover) while keeping the sensor aspect ratio
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 100,
            height: 100 * c.value.aspectRatio,
            child: CameraPreview(c),
          ),
        ),
      );
    }
    return Container(
      color: const Color(0xFF07090F),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_cameraError == null)
            const CircularProgressIndicator(color: Colors.white54)
          else ...[
            const Text('📸', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              _cameraError!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (_cameraError == 'Camera permission denied') {
                  openAppSettings();
                } else {
                  _startCamera();
                }
              },
              child: Text(
                _cameraError == 'Camera permission denied'
                    ? 'Open Settings'
                    : 'Retry',
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live camera viewfinder
          Positioned.fill(child: _buildViewfinder()),

          SafeArea(
            child: Stack(
              children: [
                // Top bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Close
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '✕',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                        ),

                        // Buddy + streak info
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.badge != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  widget.badge!,
                                  style: const TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Flip camera
                        GestureDetector(
                          onTap: _flipCamera,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.flip_camera_ios_outlined,
                              color: _cameras.length > 1
                                  ? Colors.white
                                  : Colors.white24,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Gallery button (hidden when onGallery is null)
                        if (widget.onGallery == null)
                          const SizedBox(width: 48, height: 48)
                        else
                        GestureDetector(
                          onTap: widget.onGallery,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: const Center(
                              child:
                                  Text('🖼️', style: TextStyle(fontSize: 22)),
                            ),
                          ),
                        ),

                        // Shutter button
                        GestureDetector(
                          onTap: _capture,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: _capturing ? 62 : 70,
                            height: _capturing ? 62 : 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 4,
                              ),
                            ),
                            child: _capturing
                                ? const Padding(
                                    padding: EdgeInsets.all(18),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black54,
                                    ),
                                  )
                                : null,
                          ),
                        ),

                        // Flash toggle (off → auto → on)
                        GestureDetector(
                          onTap: _toggleFlash,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              _flashIcon,
                              color: _flashMode == FlashMode.off
                                  ? Colors.white70
                                  : const Color(0xFFF59E0B),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
