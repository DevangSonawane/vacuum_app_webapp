import 'package:flutter/material.dart';

import 'app_button.dart';
import 'app_card.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Confirm',
  AppButtonVariant confirmVariant = AppButtonVariant.danger,
}) async {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 520) {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child: _ConfirmBody(
            title: title,
            body: body,
            cancelLabel: cancelLabel,
            confirmLabel: confirmLabel,
            confirmVariant: confirmVariant,
          ),
        ),
      ),
    );
    return result ?? false;
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(16),
      content: _ConfirmBody(
        title: title,
        body: body,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        confirmVariant: confirmVariant,
      ),
    ),
  );
  return result ?? false;
}

class _ConfirmBody extends StatelessWidget {
  const _ConfirmBody({
    required this.title,
    required this.body,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.confirmVariant,
  });

  final String title;
  final String body;
  final String cancelLabel;
  final String confirmLabel;
  final AppButtonVariant confirmVariant;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: cancelLabel,
                variant: AppButtonVariant.secondary,
                expanded: true,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: confirmLabel,
                variant: confirmVariant,
                expanded: true,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

