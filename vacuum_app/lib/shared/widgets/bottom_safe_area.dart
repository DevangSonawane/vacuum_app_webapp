import 'package:flutter/material.dart';

class BottomSafeArea extends StatelessWidget {
  const BottomSafeArea({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.minimumBottom = 12,
  });

  final Widget child;
  final EdgeInsets padding;
  final double minimumBottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      minimum: EdgeInsets.only(bottom: minimumBottom),
      child: Padding(padding: padding, child: child),
    );
  }
}
