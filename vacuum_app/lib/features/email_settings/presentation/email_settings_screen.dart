import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_message.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_loader.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/email_settings_notifier.dart';
import '../domain/email_settings.dart';

class EmailSettingsScreen extends ConsumerStatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  ConsumerState<EmailSettingsScreen> createState() =>
      _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends ConsumerState<EmailSettingsScreen> {
  final _smtpHost = TextEditingController();
  final _smtpPort = TextEditingController();
  final _fromEmail = TextEditingController();
  final _fromName = TextEditingController();
  final _password = TextEditingController();

  bool _jobRaised = true;
  bool _jobAssigned = true;
  bool _jobCompleted = true;
  bool _reportApproved = true;
  bool _amcRenewal = true;
  bool _quotationSent = true;

  bool _didInit = false;

  @override
  void dispose() {
    _smtpHost.dispose();
    _smtpPort.dispose();
    _fromEmail.dispose();
    _fromName.dispose();
    _password.dispose();
    super.dispose();
  }

  void _hydrate(EmailSettings s) {
    if (_didInit) return;
    _didInit = true;
    _smtpHost.text = s.smtpHost;
    _smtpPort.text = s.smtpPort;
    _fromEmail.text = s.fromEmail;
    _fromName.text = s.fromName;
    _password.text = s.password;
    _jobRaised = s.notifications.jobRaised;
    _jobAssigned = s.notifications.jobAssigned;
    _jobCompleted = s.notifications.jobCompleted;
    _reportApproved = s.notifications.reportApproved;
    _amcRenewal = s.notifications.amcRenewal;
    _quotationSent = s.notifications.quotationSent;
  }

  EmailSettings _currentSettings() {
    return EmailSettings(
      smtpHost: _smtpHost.text.trim(),
      smtpPort: _smtpPort.text.trim(),
      fromEmail: _fromEmail.text.trim(),
      fromName: _fromName.text.trim(),
      password: _password.text,
      notifications: EmailNotificationTriggers(
        jobRaised: _jobRaised,
        jobAssigned: _jobAssigned,
        jobCompleted: _jobCompleted,
        reportApproved: _reportApproved,
        amcRenewal: _amcRenewal,
        quotationSent: _quotationSent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).valueOrNull;
    final isAdmin = auth?.user?.role == 'admin';
    if (!isAdmin) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Admin only',
        description: 'You do not have access to Email Settings.',
      );
    }

    final settings = ref.watch(emailSettingsProvider);

    return settings.when(
      loading: () => const PageLoader(),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load',
        description: friendlyErrorMessage(e),
      ),
      data: (s) {
        _hydrate(s);

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bottom = MediaQuery.viewPaddingOf(context).bottom;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Email Notification Settings',
                subtitle: 'Configure SMTP and notification triggers',
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0B1220)
                                : const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.mail_outline,
                            color: AppColors.blue600,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'SMTP Configuration',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _grid(
                      context,
                      children: [
                        AppInput(
                          label: 'SMTP Host',
                          controller: _smtpHost,
                          placeholder: 'smtp.gmail.com',
                        ),
                        AppInput(
                          label: 'SMTP Port',
                          controller: _smtpPort,
                          placeholder: '587',
                        ),
                        AppInput(
                          label: 'From Email',
                          controller: _fromEmail,
                          type: AppInputType.email,
                          placeholder: 'noreply@company.com',
                        ),
                        AppInput(
                          label: 'From Name',
                          controller: _fromName,
                          placeholder: 'VDTI Service Hub',
                        ),
                        AppInput(
                          label: 'Email Password / App Password',
                          controller: _password,
                          type: AppInputType.password,
                          placeholder: '••••••••',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Send Test Email',
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.send_outlined),
                      onPressed: () async {
                        final to = (auth?.user?.email ?? '').toString().trim();
                        if (to.isEmpty) {
                          AppToast.show(
                            context,
                            message: 'No email found on your profile.',
                            type: AppToastType.error,
                          );
                          return;
                        }

                        try {
                          await ref
                              .read(emailSettingsProvider.notifier)
                              .sendTestEmail(to);
                          if (!context.mounted) return;
                          AppToast.show(
                            context,
                            message: 'Test email sent to $to',
                            type: AppToastType.success,
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          AppToast.show(
                            context,
                            message: friendlyErrorMessage(e),
                            type: AppToastType.error,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Triggers',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _TriggerTile(
                      title: 'New Job Raised',
                      value: _jobRaised,
                      onChanged: (v) => setState(() => _jobRaised = v),
                    ),
                    const SizedBox(height: 10),
                    _TriggerTile(
                      title: 'Job Assigned to Technician',
                      value: _jobAssigned,
                      onChanged: (v) => setState(() => _jobAssigned = v),
                    ),
                    const SizedBox(height: 10),
                    _TriggerTile(
                      title: 'Job Completed / Closed',
                      value: _jobCompleted,
                      onChanged: (v) => setState(() => _jobCompleted = v),
                    ),
                    const SizedBox(height: 10),
                    _TriggerTile(
                      title: 'Report Approved',
                      value: _reportApproved,
                      onChanged: (v) => setState(() => _reportApproved = v),
                    ),
                    const SizedBox(height: 10),
                    _TriggerTile(
                      title: 'AMC Renewal Reminder',
                      value: _amcRenewal,
                      onChanged: (v) => setState(() => _amcRenewal = v),
                    ),
                    const SizedBox(height: 10),
                    _TriggerTile(
                      title: 'Quotation Created',
                      value: _quotationSent,
                      onChanged: (v) => setState(() => _quotationSent = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Template Preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            color: AppColors.blue600,
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VDTI Service Hub Notification',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Vacuum Drying Technology India LLP',
                                  style: TextStyle(
                                    color: AppColors.blue200,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            color: isDark
                                ? const Color(0xFF0B1220)
                                : Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dear Recipient,',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'A new Work Order (JOB-XXXX) has been raised and assigned to you. Please review the details and proceed accordingly.',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF111827)
                                        : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF1F2937)
                                          : const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Job Details',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.blue600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Job ID: JOB-XXXX',
                                        style: TextStyle(
                                          color: Theme.of(context).hintColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Client: Client Name',
                                        style: TextStyle(
                                          color: Theme.of(context).hintColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Scheduled: DD-MM-YYYY',
                                        style: TextStyle(
                                          color: Theme.of(context).hintColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'This is an automated notification from ${_fromName.text.trim().isEmpty ? 'VDTI Service Hub' : _fromName.text.trim()}.',
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  label: 'Save Settings',
                  leading: const Icon(Icons.save_outlined),
                  onPressed: settings.isLoading
                      ? null
                      : () async {
                          await ref
                              .read(emailSettingsProvider.notifier)
                              .save(_currentSettings());
                          if (!context.mounted) return;
                          AppToast.show(
                            context,
                            message: 'Email settings saved!',
                            type: AppToastType.success,
                          );
                        },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _grid(BuildContext context, {required List<Widget> children}) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 720 ? 2 : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: cols == 1 ? 3.4 : 3.8,
      ),
      itemBuilder: (context, i) => children[i],
    );
  }
}

class _TriggerTile extends StatelessWidget {
  const _TriggerTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1220) : AppColors.gray50;
    final border = isDark ? const Color(0xFF1F2937) : AppColors.gray100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Send email notification when this event occurs',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
