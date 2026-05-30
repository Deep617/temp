import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';


// ── Primary Button ────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading  = false,
    this.disabled = false,
    this.icon,
    this.height   = 52.0,
    this.width,
  });
  final String   label;
  final VoidCallback? onPressed;
  final bool     loading;
  final bool     disabled;
  final IconData? icon;
  final double   height;
  final double?  width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width:  width ?? double.infinity,
      child: ElevatedButton(
        onPressed: (disabled || loading) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: (disabled || loading) ? AppColors.surface3 : AppColors.primary,
          foregroundColor: (disabled || loading) ? AppColors.textDim : Colors.black,
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(label, style: AppTextStyles.btn()),
                ],
              ),
      ),
    );
  }
}

// ── Ghost Button ──────────────────────────────────────────
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key, required this.label, this.onPressed,
    this.icon, this.height = 52.0, this.width,
    this.color,
  });
  final String   label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double   height;
  final double?  width;
  final Color?   color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width:  width ?? double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color ?? AppColors.textPrimary,
          side: BorderSide(color: color?.withOpacity(0.3) ?? AppColors.border2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(label, style: AppTextStyles.btn(color: color ?? AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ── App Input Field ───────────────────────────────────────
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.validator,
    this.obscure     = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffix,
    this.maxLines    = 1,
    this.enabled     = true,
    this.autofocus   = false,
    this.textCapitalization = TextCapitalization.none,
  });
  final String   label;
  final String?  hint;
  final TextEditingController? controller;
  final ValueChanged<String>?  onChanged;
  final FormFieldValidator<String>? validator;
  final bool     obscure;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget?  suffix;
  final int      maxLines;
  final bool     enabled;
  final bool     autofocus;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.label()),
        const SizedBox(height: 6),
        TextFormField(
          controller:         controller,
          onChanged:          onChanged,
          validator:          validator,
          obscureText:        obscure,
          keyboardType:       keyboardType,
          maxLines:           maxLines,
          enabled:            enabled,
          autofocus:          autofocus,
          textCapitalization: textCapitalization,
          style: AppTextStyles.body(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textDim, size: 18)
                : null,
            suffix: suffix,
          ),
        ),
      ],
    );
  }
}

// ── App Badge ─────────────────────────────────────────────
class AppBadge extends StatelessWidget {
  const AppBadge({ super.key, required this.label, this.color, this.small = false });
  final String label;
  final Color? color;
  final bool   small;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySM(color: c).copyWith(
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  const SectionHeader({ super.key, required this.title, this.subtitle, this.action, this.onAction });
  final String  title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h3()),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppTextStyles.bodySM()),
              ],
            ],
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: AppTextStyles.label(color: AppColors.primary)),
          ),
      ],
    );
  }
}

// ── Avatar ────────────────────────────────────────────────
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key, this.imageUrl, required this.name,
    this.size = 44, this.online = false, this.verified = false,
  });
  final String? imageUrl;
  final String  name;
  final double  size;
  final bool    online;
  final bool    verified;

  Color get _bgColor {
    final colors = [
      AppColors.primary, AppColors.blue, AppColors.teal,
      AppColors.purple, AppColors.orange,
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _bgColor,
            image: imageUrl != null
                ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: imageUrl == null
              ? Center(child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTextStyles.subtitle(color: Colors.black).copyWith(
                    fontSize: size * 0.35, fontWeight: FontWeight.w800,
                  ),
                ))
              : null,
        ),
        if (online) Positioned(
          bottom: 1, right: 1,
          child: Container(
            width: size * 0.26, height: size * 0.26,
            decoration: BoxDecoration(
              color: AppColors.teal,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.bg, width: 1.5),
            ),
          ),
        ),
        if (verified) Positioned(
          top: -2, right: -2,
          child: Container(
            width: size * 0.3, height: size * 0.3,
            decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
            child: Icon(Icons.verified, size: size * 0.2, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ── Skeleton Loader ───────────────────────────────────────
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({ super.key, required this.width, required this.height, this.radius = 8 });
  final double width, height, radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:      AppColors.surface2,
      highlightColor: AppColors.surface3,
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class SkeletonAvatar extends StatelessWidget {
  const SkeletonAvatar({ super.key, this.size = 44 });
  final double size;
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface2, highlightColor: AppColors.surface3,
      child: Container(
        width: size, height: size,
        decoration: const BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────
class EmptyState extends StatelessWidget {
  const EmptyState({ super.key, required this.emoji, required this.title, this.subtitle, this.action, this.onAction });
  final String emoji, title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.h3(), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: AppTextStyles.body(), textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(label: action!, onPressed: onAction, width: 180),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
    );
  }
}

// ── XP Progress Bar ───────────────────────────────────────
class XpBar extends StatelessWidget {
  const XpBar({ super.key, required this.xp, required this.level, required this.maxXp });
  final int xp, level, maxXp;

  @override
  Widget build(BuildContext context) {
    final progress = (xp / maxXp).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppBadge(label: 'Level $level', small: true),
            Text('$xp / $maxXp XP', style: AppTextStyles.caption()),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value:           progress,
            minHeight:       5,
            backgroundColor: AppColors.surface3,
            valueColor:      const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

// ── Activity Chip ─────────────────────────────────────────
class ActivityChip extends StatelessWidget {
  const ActivityChip({ super.key, required this.activity, this.selected = false, this.onTap });
  final Map<String,dynamic> activity;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(activity['color'] as int);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:        selected ? color.withOpacity(0.18) : AppColors.surface2,
          borderRadius: BorderRadius.circular(100),
          border:       Border.all(color: selected ? color.withOpacity(0.4) : AppColors.border2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(activity['emoji'] as String, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              activity['label'] as String,
              style: AppTextStyles.bodySM(color: selected ? color : AppColors.textSecondary)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compatibility Ring ────────────────────────────────────
class CompatRing extends StatelessWidget {
  const CompatRing({ super.key, required this.score, this.size = 80 });
  final double score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pct = score / 100;
    final color = score >= 80 ? AppColors.primary
        : score >= 60 ? AppColors.teal
        : score >= 40 ? AppColors.warning
        : AppColors.error;
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value:            pct,
            strokeWidth:      size * 0.08,
            backgroundColor:  AppColors.surface3,
            valueColor:       AlwaysStoppedAnimation<Color>(color),
            strokeCap:        StrokeCap.round,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${score.toInt()}%',
                  style: AppTextStyles.label(color: color).copyWith(fontSize: size * 0.2, fontWeight: FontWeight.w800)),
              Text('match', style: AppTextStyles.caption().copyWith(fontSize: size * 0.12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Token Badge ───────────────────────────────────────────
class TokenBadge extends StatelessWidget {
  const TokenBadge({ super.key, required this.count });
  final int count;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFBAEE0B), Color(0xFF0ABFCE)]),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎫', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text('$count tokens',
              style: AppTextStyles.label(color: Colors.black).copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
