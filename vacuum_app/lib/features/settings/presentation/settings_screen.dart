import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/app_settings_notifier.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/section_header.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _success = false;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _mismatch =>
      _newPassword.text.isNotEmpty &&
      _confirm.text.isNotEmpty &&
      _newPassword.text != _confirm.text;

  Future<void> _submit() async {
    if (_loading) return;
    if (_newPassword.text.trim().isEmpty || _confirm.text.trim().isEmpty) {
      return;
    }
    if (_mismatch) return;

    setState(() {
      _loading = true;
      _success = false;
    });

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        'auth/change-password',
        data: {
          'new_password': _newPassword.text.trim(),
          'confirm_password': _confirm.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() => _success = true);
      AppToast.show(
        context,
        message: 'Password updated',
        type: AppToastType.success,
      );
      _newPassword.clear();
      _confirm.clear();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (!mounted) return;
      AppToast.show(
        context,
        message: status == 404
            ? 'Change-password endpoint not available.'
            : (e.message ?? 'Operation failed'),
        type: AppToastType.error,
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Operation failed',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = ref.watch(appSettingsProvider).valueOrNull ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Settings',
            subtitle: 'Manage your preferences and security',
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.settings, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferences and security',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep the app comfortable to use and update your password from one screen.',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.palette_outlined,
                        color: AppColors.blue600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Appearance',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111827) : AppColors.gray50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        dark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        color: AppColors.blue600,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Dark Mode',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Switch(
                        value: dark,
                        onChanged: (_) => ref
                            .read(appSettingsProvider.notifier)
                            .toggleDarkMode(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: AppColors.blue600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Security — Change Password',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_success)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.emerald500),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Password updated successfully.',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_success) const SizedBox(height: 16),
                AppInput(
                  label: 'New Password',
                  controller: _newPassword,
                  type: AppInputType.password,
                  required: true,
                  enabled: !_loading,
                ),
                const SizedBox(height: 12),
                AppInput(
                  label: 'Confirm Password',
                  controller: _confirm,
                  type: AppInputType.password,
                  required: true,
                  enabled: !_loading,
                ),
                if (_mismatch) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Passwords do not match',
                    style: TextStyle(
                      color: AppColors.red500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AppButton(
                  label: 'Update Password',
                  expanded: true,
                  loading: _loading,
                  onPressed:
                      (_loading ||
                          _mismatch ||
                          _newPassword.text.trim().isEmpty ||
                          _confirm.text.trim().isEmpty)
                      ? null
                      : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
