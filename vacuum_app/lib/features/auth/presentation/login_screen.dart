import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_toast.dart';
import '../application/auth_notifier.dart';
import 'branding_panel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum _LoginMode { email, phone }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  _LoginMode _mode = _LoginMode.email;
  String? _errorMessage;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showBranding = width >= 900;
    final isLoading = _isLoggingIn;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          if (showBranding)
            const Expanded(
              flex: 45,
              child: BrandingPanel(
                title: 'Welcome',
                subtitle: 'Service operations dashboard',
                bullets: [
                  (
                    Icons.dashboard_outlined,
                    'Unified dashboard',
                    'Track jobs, reports, quotations, AMC, and attendance.',
                  ),
                  (
                    Icons.security,
                    'Role-based access',
                    'Admin-only controls for users and email settings.',
                  ),
                  (
                    Icons.offline_bolt,
                    'Fast workflows',
                    'Designed for field-service operations and quick triage.',
                  ),
                ],
              ),
            ),
          Expanded(
            flex: 55,
            child: Container(
              color: isDark ? AppColors.darkBg : AppColors.gray50,
              padding: const EdgeInsets.all(18),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to access your dashboard',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.gray400
                                        : AppColors.gray500,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            _LoginTabs(
                              value: _mode,
                              onChanged: isLoading
                                  ? null
                                  : (next) => setState(() {
                                      _mode = next;
                                      _errorMessage = null;
                                      _password.clear();
                                    }),
                            ),
                            const SizedBox(height: 20),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: _mode == _LoginMode.email
                                  ? AppInput(
                                      key: const ValueKey('email'),
                                      label: 'Email Address',
                                      controller: _email,
                                      type: AppInputType.email,
                                      placeholder: 'email@vdti.com',
                                      prefix: const Icon(Icons.mail_outline),
                                      enabled: !isLoading,
                                      required: true,
                                    )
                                  : _PhoneField(
                                      key: const ValueKey('phone'),
                                      controller: _phone,
                                      enabled: !isLoading,
                                    ),
                            ),
                            const SizedBox(height: 16),
                            AppInput(
                              label: 'Password',
                              controller: _password,
                              type: AppInputType.password,
                              placeholder: '••••••••',
                              enabled: !isLoading,
                              required: true,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: _remember,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      onChanged: isLoading
                                          ? null
                                          : (v) => setState(
                                              () => _remember = v ?? true,
                                            ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Remember me',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    minimumSize: const Size(0, 40),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () => context.go('/forgot-password'),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Forgot password?'),
                                  ),
                                ),
                              ],
                            ),
                            AnimatedOpacity(
                              opacity: (_errorMessage?.isNotEmpty ?? false)
                                  ? 1
                                  : 0,
                              duration: const Duration(milliseconds: 160),
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 160),
                                child: (_errorMessage?.isNotEmpty ?? false)
                                    ? Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFFEE2E2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: AppColors.red500,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: const TextStyle(
                                                  color: AppColors.red500,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              label: 'Sign In',
                              expanded: true,
                              loading: isLoading,
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      debugPrint(
                                        '[Login] submit -> ${_mode == _LoginMode.email ? "email" : "phone"}',
                                      );
                                      setState(() => _errorMessage = null);
                                      setState(() => _isLoggingIn = true);
                                      final identifier =
                                          _mode == _LoginMode.email
                                          ? _email.text
                                          : (_phone.text.trim().startsWith('+')
                                                ? _phone.text
                                                : '+91${_phone.text.trim()}');
                                      try {
                                        await ref.read(authProvider.notifier).login(
                                            identifier: identifier,
                                            password: _password.text,
                                          );
                                        if (!mounted) return;
                                        setState(() => _isLoggingIn = false);
                                        debugPrint('[Login] auth success -> toast shown');
                                        _showLoginSuccess();
                                      } catch (_) {
                                        final auth = ref.read(authProvider);
                                        final message = _friendlyLoginMessage(
                                          auth.error?.toString() ?? 'Login failed. Please try again.',
                                        );
                                        debugPrint('[Login] auth failure -> $message');
                                        if (!mounted) return;
                                        setState(() {
                                          _isLoggingIn = false;
                                          _errorMessage = message;
                                        });
                                        _showLoginError(message);
                                      }
                                    },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _remember
                                  ? 'Session will be kept for faster access.'
                                  : 'Session will not be persisted.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyLoginMessage(String raw) {
    final message = raw.trim();
    if (message.isEmpty) {
      return 'Login failed. Please try again.';
    }

    final lower = message.toLowerCase();
    if (lower.contains('incorrect') ||
        lower.contains('wrong email') ||
        lower.contains('wrong password') ||
        lower.contains('invalid credentials')) {
      return 'Incorrect email/phone number or password.';
    }
    if (lower.contains('contact the admin') ||
        lower.contains('backend error') ||
        lower.contains('server error')) {
      return 'Backend error. Please contact the admin and try again later.';
    }
    if (lower.contains('internet') ||
        lower.contains('connection') ||
        lower.contains('timeout') ||
        lower.contains('network')) {
      return 'Unable to reach the server. Please check your internet connection.';
    }
    return message;
  }

  void _showLoginSuccess() {
    AppToast.show(
      context,
      message: 'Login successful. Welcome back.',
      type: AppToastType.success,
    );
  }

  void _showLoginError(String message) {
    AppToast.show(
      context,
      message: message,
      type: AppToastType.error,
    );
  }
}

class _LoginTabs extends StatelessWidget {
  const _LoginTabs({required this.value, required this.onChanged});

  final _LoginMode value;
  final ValueChanged<_LoginMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1F2937) : AppColors.gray100;
    final selectedBg = isDark ? const Color(0xFF374151) : Colors.white;
    final selectedFg = isDark ? AppColors.blue200 : AppColors.blue600;
    final unselectedFg = isDark ? AppColors.gray400 : AppColors.gray500;

    Widget tab(_LoginMode mode, String label, IconData icon) {
      final active = value == mode;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onChanged == null ? null : () => onChanged!(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: active ? selectedFg : unselectedFg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? selectedFg : unselectedFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          tab(_LoginMode.email, 'Email', Icons.mail_outline),
          const SizedBox(width: 6),
          tab(_LoginMode.phone, 'Mobile Number', Icons.phone_outlined),
        ],
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    super.key,
    required this.controller,
    required this.enabled,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? const Color(0xFF111827) : AppColors.gray100;
    final chipFg = isDark ? AppColors.gray200 : AppColors.gray700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile Number',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_outlined, size: 14, color: chipFg),
                  const SizedBox(width: 6),
                  Text(
                    '+91',
                    style: TextStyle(
                      color: chipFg,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '9876543210'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
