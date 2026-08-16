import 'package:flutter/material.dart';

class AppDropdownItem<T> {
  const AppDropdownItem({required this.value, required this.label});
  final T value;
  final String label;
}

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.allowNull = false,
    this.nullLabel = '— Please select —',
  });

  final String label;
  final T? value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;
  final bool allowNull;
  final String nullLabel;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF1B2A44)
        : const Color(0xFFE5E7EB);

    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
    );

    Widget menuRow(String text) => Row(
      children: [Expanded(child: Text(text, overflow: TextOverflow.ellipsis))],
    );

    final dropdownItems = <DropdownMenuItem<T?>>[];
    final seenValues = <Object?>{};

    if (allowNull) {
      seenValues.add(null);
      dropdownItems.add(
        DropdownMenuItem<T?>(value: null, child: menuRow(nullLabel)),
      );
    }

    for (final item in items) {
      if (seenValues.contains(item.value)) continue;
      seenValues.add(item.value);
      dropdownItems.add(
        DropdownMenuItem<T?>(value: item.value, child: menuRow(item.label)),
      );
    }

    final hasCurrentValue =
        dropdownItems.where((item) => item.value == value).length == 1;
    final selectedValue = hasCurrentValue
        ? value
        : (allowNull
              ? null
              : (dropdownItems.isNotEmpty ? dropdownItems.first.value : null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        if (dropdownItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              'No options available',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          )
        else
          DropdownButtonFormField<T?>(
            initialValue: selectedValue,
            isExpanded: true,
            menuMaxHeight: 360,
            borderRadius: BorderRadius.circular(16),
            dropdownColor: surface,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            decoration: InputDecoration(
              isDense: false,
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0B1220)
                  : const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 13,
              ),
              border: baseBorder,
              enabledBorder: baseBorder,
              focusedBorder: focusedBorder,
            ),
            items: dropdownItems,
            onChanged: enabled ? onChanged : null,
          ),
      ],
    );
  }
}
