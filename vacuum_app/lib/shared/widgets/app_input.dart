import 'package:flutter/material.dart';

enum AppInputType { text, email, password, number }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.required ? '${widget.label} *' : widget.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          keyboardType: switch (widget.type) {
            AppInputType.email => TextInputType.emailAddress,
            AppInputType.number => TextInputType.number,
            _ => TextInputType.text,
          },
          obscureText: isPassword ? _obscure : false,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            prefixIcon: widget.prefix,
            suffixIcon: suffix,
          ),
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
      ],
    );
  }
}

