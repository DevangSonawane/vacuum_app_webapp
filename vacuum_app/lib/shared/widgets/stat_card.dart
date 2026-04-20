import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'app_card.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.changePercent,
  });

  final String title;
  final String value;
  final String? subtitle;
  final num? changePercent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.gray400 : AppColors.gray500;

    Color? changeColor;
    String? changeText;
    if (changePercent != null) {
      final v = changePercent!;
      changeColor = v >= 0 ? AppColors.emerald500 : AppColors.red500;
      final signed = v >= 0 ? '+${v.toString()}' : v.toString();
      changeText = '$signed% vs last month';
    }

    return AppCard(
      hover: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 92;
          final showFooter = constraints.maxHeight >= 72;
          final valueFontSize = compact ? 26.0 : 32.0;

          Widget footer = const SizedBox.shrink();
          if (subtitle != null) {
            footer = Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: titleColor),
            );
          } else if (changeText != null) {
            footer = Text(
              changeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: changeColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => ClipRect(
                    child: Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, (1 - t) * 10),
                        child: child,
                      ),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontSize: valueFontSize,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              if (showFooter) ...[const SizedBox(height: 4), footer],
            ],
          );
        },
      ),
    );
  }
}
