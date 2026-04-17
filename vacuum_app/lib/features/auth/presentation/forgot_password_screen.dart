import 'dart:async';

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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  int _step = 1;

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
        error: (error, _) =>
            AppToast.show(context, message: error.toString(), type: AppToastType.error),
        data: (state) {
          if (_step == 1 && (state.resetToken?.isNotEmpty ?? false)) {
            _token.text = state.resetToken!;
          }
        },
      );
    });

    final width = MediaQuery.sizeOf(context).width;
    final showBranding = width >= 900;
    final auth = ref.watch(authProvider);
    final isLoading = auth.isLoading;

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
                  (Icons.lock_outline, 'Secure reset', 'Reset tokens are time-bound and user-specific.'),
                  (Icons.shield_outlined, 'Privacy first', 'Passwords are never returned by the API.'),
                  (Icons.support_agent, 'Support', 'Contact admin if you cannot access your email.'),
                ],
              ),
            ),
          Expanded(
            flex: 55,
            child: Container(
              color: AppColors.gray50,
              padding: const EdgeInsets.all(18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AppCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Back',
                              onPressed: isLoading ? null : () => context.go('/login'),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Forgot Password',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _step == 1
                              ? 'Enter your email to receive a reset token.'
                              : 'Enter the token and choose a new password.',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                        const SizedBox(height: 18),
                        if (_step == 1) ...[
                          AppInput(
                            label: 'Email',
                            controller: _email,
                            type: AppInputType.email,
                            placeholder: 'name@company.com',
                            prefix: const Icon(Icons.mail_outline),
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 14),
                          AppButton(
                            label: 'Send Reset Token',
                            expanded: true,
                            loading: isLoading,
                            onPressed: isLoading
                                ? null
                                : () async {
                                    await ref.read(authProvider.notifier).forgotPassword(email: _email.text);
                                    if (!context.mounted) return;
                                    setState(() => _step = 2);
                                    AppToast.show(
                                      context,
                                      message: 'Reset token sent (check email).',
                                      type: AppToastType.success,
                                    );
                                  },
                          ),
                        ] else ...[
                          AppInput(
                            label: 'Reset Token',
                            controller: _token,
                            placeholder: 'TOKEN',
                            prefix: const Icon(Icons.key_outlined),
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 14),
                          AppInput(
                            label: 'New Password',
                            controller: _newPassword,
                            type: AppInputType.password,
                            placeholder: '••••••••',
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 14),
                          AppInput(
                            label: 'Confirm Password',
                            controller: _confirmPassword,
                            type: AppInputType.password,
                            placeholder: '••••••••',
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 14),
                          AppButton(
                            label: 'Reset Password',
                            expanded: true,
                            loading: isLoading,
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final router = GoRouter.of(context);
                                    await ref.read(authProvider.notifier).resetPassword(
                                          token: _token.text,
                                          newPassword: _newPassword.text,
                                          confirmPassword: _confirmPassword.text,
                                        );
                                    if (!context.mounted) return;
                                    AppToast.show(
                                      context,
                                      message: 'Password updated. Redirecting to login…',
                                      type: AppToastType.success,
                                    );
                                    unawaited(
                                      Future<void>.delayed(const Duration(seconds: 3)).then((_) {
                                        router.go('/login');
                                      }),
                                    );
                                  },
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: isLoading ? null : () => setState(() => _step = 1),
                            child: const Text('Back to email step'),
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
