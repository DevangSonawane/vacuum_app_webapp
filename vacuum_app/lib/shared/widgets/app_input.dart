import 'package:flutter/material.dart';

enum AppInputType { text, email, phone, password, number }

class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    required this.label,
    required this.controller,
    this.type = AppInputType.text,
    this.placeholder,
    this.required = false,
    this.suffix,
    this.prefix,
    this.helperText,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final AppInputType type;
  final String? placeholder;
  final bool required;
  final Widget? suffix;
  final Widget? prefix;
  final String? helperText;
  final bool enabled;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.type == AppInputType.password;
    final suffix = isPassword
        ? IconButton(
            tooltip: _obscure ? 'Show password' : 'Hide password',
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          )
        : widget.suffix;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark
        ? const Color(0xFFE5E7EB)
        : const Color(0xFF374151);
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 420 || size.height < 760;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: widget.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: compact ? 12 : 13,
              color: labelColor,
            ),
            children: widget.required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]
                : const [],
          ),
        ),
        SizedBox(height: compact ? 4 : 8),
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          keyboardType: switch (widget.type) {
            AppInputType.email => TextInputType.emailAddress,
            AppInputType.phone => TextInputType.phone,
            AppInputType.number => TextInputType.number,
            _ => TextInputType.text,
          },
          obscureText: isPassword ? _obscure : false,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            prefixIcon: widget.prefix,
            suffixIcon: suffix,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 10 : 12,
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
        if (widget.helperText != null) ...[
          SizedBox(height: compact ? 4 : 6),
          Text(
            widget.helperText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          ),
        ],
      ],
    );
  }
}
