import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum AppAvatarSize { sm, md, lg }

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initials,
    this.size = AppAvatarSize.md,
  });

  final String initials;
  final AppAvatarSize size;

  double get _dimension => switch (size) {
    AppAvatarSize.sm => 28,
    AppAvatarSize.md => 36,
    AppAvatarSize.lg => 48,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _dimension,
      height: _dimension,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [AppColors.blue500, Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: _dimension * 0.38,
        ),
      ),
    );
  }
}
