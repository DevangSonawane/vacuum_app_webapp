import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_input.dart';
import '../application/auth_notifier.dart';
import 'branding_panel.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  int _step = 1; // 1=request, 2=reset, 3=success
  String? _errorMessage;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) => setState(() => _errorMessage = error.toString()),
      );
      next.whenOrNull(
        data: (state) {
          final t = state.resetToken;
          if (_step == 1 && (t?.isNotEmpty ?? false)) _token.text = t!;
        },
      );
    });

    final width = MediaQuery.sizeOf(context).width;
    final showBranding = width >= 900;
    final auth = ref.watch(authProvider);
    final isLoading = auth.isLoading;
    final resetToken = auth.valueOrNull?.resetToken;
    final isMismatch =
        _newPassword.text.isNotEmpty &&
        _confirmPassword.text.isNotEmpty &&
        _newPassword.text != _confirmPassword.text;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          if (showBranding)
            const Expanded(
              flex: 45,
              child: BrandingPanel(
                title: 'Secure Access',
                subtitle: 'Account recovery',
                bullets: [
                  (
                    Icons.lock_outline,
                    'Secure reset',
                    'Reset tokens are time-bound and user-specific.',
                  ),
                  (
                    Icons.shield_outlined,
                    'Privacy first',
                    'Passwords are never returned by the API.',
                  ),
                  (
                    Icons.support_agent,
                    'Support',
                    'Contact admin if you cannot access your email.',
                  ),
                ],
              ),
            ),
          Expanded(
            flex: 55,
            child: Container(
              color: isDark ? AppColors.darkBg : AppColors.gray50,
              padding: const EdgeInsets.all(18),
              child: Center(
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
                        TextButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => context.go('/login'),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Back to Sign In'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _step == 1
                              ? 'Enter your email to receive a reset token.'
                              : _step == 2
                              ? 'Enter the token and choose a new password.'
                              : 'Your password has been reset successfully.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.gray400
                                    : AppColors.gray500,
                              ),
                        ),
                        const SizedBox(height: 18),
                        AnimatedOpacity(
                          opacity: (_errorMessage?.isNotEmpty ?? false) ? 1 : 0,
                          duration: const Duration(milliseconds: 160),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 160),
                            child: (_errorMessage?.isNotEmpty ?? false)
                                ? Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(12),
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
                        if (_step != 3) const SizedBox(height: 14),
                        if (_step == 1) ...[
                          AppInput(
                            label: 'Email Address',
                            controller: _email,
                            type: AppInputType.email,
                            placeholder: 'name@company.com',
                            prefix: const Icon(Icons.mail_outline),
                            enabled: !isLoading,
                            required: true,
                          ),
                          const SizedBox(height: 14),
                          AppButton(
                            label: 'Send Reset Token',
                            expanded: true,
                            loading: isLoading,
                            onPressed: isLoading
                                ? null
                                : () async {
                                    setState(() => _errorMessage = null);
                                    await ref
                                        .read(authProvider.notifier)
                                        .forgotPassword(email: _email.text);
                                    if (!context.mounted) return;
                                    if (ref.read(authProvider).hasError) return;
                                    setState(() => _step = 2);
                                  },
                          ),
                        ] else if (_step == 2) ...[
                          AppInput(
                            label: 'Reset Token',
                            controller: _token,
                            placeholder: 'Paste your token',
                            prefix: const Icon(Icons.key_outlined),
                            enabled: !isLoading,
                            required: true,
                          ),
                          if (resetToken?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFDBEAFE),
                                ),
                              ),
                              child: Text(
                                resetToken!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  color: AppColors.blue600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          AppInput(
                            label: 'New Password',
                            controller: _newPassword,
                            type: AppInputType.password,
                            placeholder: '••••••••',
                            enabled: !isLoading,
                            required: true,
                          ),
                          const SizedBox(height: 14),
                          AppInput(
                            label: 'Confirm Password',
                            controller: _confirmPassword,
                            type: AppInputType.password,
                            placeholder: '••••••••',
                            enabled: !isLoading,
                            required: true,
                          ),
                          if (isMismatch) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Passwords do not match',
                              style: TextStyle(
                                color: AppColors.red500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          AppButton(
                            label: 'Reset Password',
                            expanded: true,
                            loading: isLoading,
                            onPressed: (isLoading || isMismatch)
                                ? null
                                : () async {
                                    setState(() => _errorMessage = null);
                                    await ref
                                        .read(authProvider.notifier)
                                        .resetPassword(
                                          token: _token.text,
                                          newPassword: _newPassword.text,
                                          confirmPassword:
                                              _confirmPassword.text,
                                        );
                                    if (!context.mounted) return;
                                    if (ref.read(authProvider).hasError) return;
                                    setState(() => _step = 3);
                                    unawaited(
                                      Future<void>.delayed(
                                        const Duration(seconds: 3),
                                      ).then((_) {
                                        if (context.mounted) {
                                          context.go('/login');
                                        }
                                      }),
                                    );
                                  },
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => setState(() {
                                    _step = 1;
                                    _errorMessage = null;
                                  }),
                            child: const Text('Back to email step'),
                          ),
                        ] else ...[
                          Center(
                            child: Column(
                              children: const [
                                SizedBox(height: 6),
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.emerald500,
                                  size: 42,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Password updated',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Redirecting to login…',
                                  style: TextStyle(color: AppColors.gray500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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
}
