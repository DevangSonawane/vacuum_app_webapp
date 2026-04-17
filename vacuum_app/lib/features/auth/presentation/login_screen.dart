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

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) =>
            AppToast.show(context, message: error.toString(), type: AppToastType.error),
        data: (state) {
          if (state.isAuthenticated) {
            context.go('/');
          }
        },
      );
    });

    final width = MediaQuery.sizeOf(context).width;
    final showBranding = width >= 900;
    final auth = ref.watch(authProvider);
    final isLoading = auth.isLoading;

    final identifierValue = _identifier.text.trim();
    final isEmail = identifierValue.contains('@');
    final isPhone = identifierValue.isNotEmpty && !isEmail;

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
                  (Icons.dashboard_outlined, 'Unified dashboard', 'Track jobs, reports, quotations, AMC, and attendance.'),
                  (Icons.security, 'Role-based access', 'Admin-only controls for users and email settings.'),
                  (Icons.offline_bolt, 'Fast workflows', 'Designed for field-service operations and quick triage.'),
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
                        const SizedBox(height: 8),
                        const Text(
                          'Welcome Back',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to access your dashboard',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                        const SizedBox(height: 22),
                        AppInput(
                          label: 'Email or Phone',
                          controller: _identifier,
                          placeholder: 'name@company.com or 9876543210',
                          prefix: Icon(isEmail ? Icons.mail_outline : Icons.phone_outlined),
                          helperText: isPhone ? 'Will be sent as +91XXXXXXXXXX' : null,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 14),
                        AppInput(
                          label: 'Password',
                          controller: _password,
                          type: AppInputType.password,
                          placeholder: '••••••••',
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              value: _remember,
                              onChanged: isLoading ? null : (v) => setState(() => _remember = v ?? true),
                            ),
                            const Text('Remember me'),
                            const Spacer(),
                            TextButton(
                              onPressed: isLoading ? null : () => context.go('/forgot-password'),
                              child: const Text('Forgot password?'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AppButton(
                          label: 'Sign In',
                          expanded: true,
                          loading: isLoading,
                          onPressed: isLoading
                              ? null
                              : () => ref.read(authProvider.notifier).login(
                                    identifier: _identifier.text,
                                    password: _password.text,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _remember ? 'Session will be kept for faster access.' : 'Session will not be persisted.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                        ),
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

