import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum AppButtonVariant { primary, secondary, danger, ghost, outline }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.leading,
    this.loading = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leading;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _colorsFor(context);
    final padding = switch (size) {
      AppButtonSize.sm => const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      AppButtonSize.md => const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      AppButtonSize.lg => const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    };

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (leading != null)
          IconTheme(data: IconThemeData(color: fg, size: 18), child: leading!),
        if (leading != null || loading) const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );

    final button = Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: loading ? null : onPressed,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: border == null ? null : Border.all(color: border),
          ),
          child: child,
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  (Color bg, Color fg, Color? border) _colorsFor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (variant) {
      case AppButtonVariant.primary:
        return (AppColors.blue600, Colors.white, null);
      case AppButtonVariant.secondary:
        return (
          isDark ? const Color(0xFF111827) : AppColors.gray100,
          isDark ? Colors.white : AppColors.gray700,
          null
        );
      case AppButtonVariant.danger:
        return (AppColors.red500, Colors.white, null);
      case AppButtonVariant.ghost:
        return (Colors.transparent, isDark ? Colors.white : AppColors.gray700, null);
      case AppButtonVariant.outline:
        return (Colors.transparent, AppColors.blue600, AppColors.blue600);
    }
  }
}

