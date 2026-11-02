// ─────────────────────────────────────────────────────────
//  Session Proof camera — LIVE photo only (no gallery)
//  + date/time stamp burned into the image, so old or
//  downloaded photos can't be used as proof.
// ─────────────────────────────────────────────────────────
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/widgets/camera/sesh_camera_view.dart';

/// Opens the in-app camera full screen. Returns the stamped photo,
/// or null if the user closed the camera / permission was denied.
Future<File?> captureProofPhoto(
  BuildContext context, {
  String activity = 'Workout',
}) async {
  final status = await Permission.camera.request();
  if (!context.mounted) return null;
  if (status.isDenied || status.isPermanentlyDenied) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Camera permission is required for session proof'),
        action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return null;
  }

  final shot = await Navigator.of(context).push<File>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => SeshCameraView(
        active: true,
        title: 'Session Proof 📸',
        badge: activity,
        onClose: () => Navigator.of(ctx).pop(),
        onCapture: (file) => Navigator.of(ctx).pop(file),
        // onGallery: null → live photo only
      ),
    ),
  );
  if (shot == null) return null;

  try {
    return await stampProofPhoto(shot, label: activity);
  } catch (_) {
    return shot; // stamping is best-effort — never block the upload
  }
}

/// Draws "SESHLLY · <activity> · 09 Oct 2026, 7:42 PM" on the photo.
/// Output is PNG (max 1080px wide) in the temp folder.
Future<File> stampProofPhoto(File source, {String label = 'Workout'}) async {
  final bytes = await source.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1080);
  final frame = await codec.getNextFrame();
  final img = frame.image;

  final w = img.width.toDouble();
  final h = img.height.toDouble();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
  canvas.drawImage(img, Offset.zero, Paint());

  final stamp =
      'SESHLLY · $label · ${DateFormat('dd MMM yyyy, h:mm a').format(DateTime.now())}';
  final fontSize = (w * 0.032).clamp(18.0, 40.0);
  final tp = TextPainter(
    text: TextSpan(
      text: stamp,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: w - fontSize * 2);

  // Dark strip at the bottom for readability
  final pad = fontSize * 0.6;
  final stripH = tp.height + pad * 2;
  canvas.drawRect(
    Rect.fromLTWH(0, h - stripH, w, stripH),
    Paint()..color = const Color(0x99000000),
  );
  tp.paint(canvas, Offset(pad * 1.5, h - stripH + pad));

  final out = await recorder
      .endRecording()
      .toImage(img.width, img.height);
  final png = await out.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  out.dispose();
  if (png == null) return source;

  final file = File(
    '${Directory.systemTemp.path}/proof_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(png.buffer.asUint8List(), flush: true);
  return file;
}
