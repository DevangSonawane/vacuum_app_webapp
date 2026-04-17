import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum AppToastType { success, error, info }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        type: type,
        onClose: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
    Future<void>.delayed(const Duration(seconds: 3)).then((_) {
      if (entry.mounted) entry.remove();
    });
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.onClose,
  });

  final String message;
  final AppToastType type;
  final VoidCallback onClose;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _style(widget.type);
    final media = MediaQuery.of(context);

    return Positioned(
      top: media.padding.top + 12,
      right: 12,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: fg, size: 18),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: widget.onClose,
                  child: Icon(Icons.close, color: fg, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, IconData) _style(AppToastType type) {
    switch (type) {
      case AppToastType.success:
        return (AppColors.emerald500, Colors.white, Icons.check_circle);
      case AppToastType.error:
        return (AppColors.red500, Colors.white, Icons.error);
      case AppToastType.info:
        return (AppColors.blue600, Colors.white, Icons.info);
    }
  }
}
