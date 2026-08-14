import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/technicians_notifier.dart';
import '../domain/technician.dart';

class TechnicianDetailScreen extends ConsumerStatefulWidget {
  const TechnicianDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TechnicianDetailScreen> createState() =>
      _TechnicianDetailScreenState();
}

class _TechnicianDetailScreenState
    extends ConsumerState<TechnicianDetailScreen> {
  AsyncValue<Technician?> _technician = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _technician = const AsyncLoading());
    final parsed = int.tryParse(widget.id);
    if (parsed == null) {
      if (!mounted) return;
      setState(() {
        _technician = const AsyncData(null);
      });
      return;
    }

    final tech = await ref.read(techniciansProvider.notifier).fetchById(parsed);
    if (!mounted) return;
    setState(() => _technician = AsyncData(tech));
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final lowerRole = role.toLowerCase();
    final canEdit = !['technician', 'labour'].contains(lowerRole);
    final canDelete = ['admin', 'manager'].contains(lowerRole);
    final parsedId = int.tryParse(widget.id);

    return Scaffold(
      body: _technician.when(
        loading: () => const _TechnicianDetailSkeleton(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load',
          description: friendlyErrorMessage(e),
        ),
        data: (tech) {
          if (tech == null) {
            return const EmptyState(
              icon: Icons.engineering_outlined,
              title: 'Technician not found',
              description: 'The technician may have been deleted.',
            );
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppButton(
                        label: 'Back',
                        variant: AppButtonVariant.secondary,
                        size: AppButtonSize.sm,
                        leading: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/technicians'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tech.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (canEdit && parsedId != null) ...[
                        const SizedBox(width: 12),
                        AppButton(
                          label: 'Edit',
                          variant: AppButtonVariant.outline,
                          size: AppButtonSize.sm,
                          leading: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              context.push('/technicians/${widget.id}/edit'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _HeaderCard(tech: tech),
                  const SizedBox(height: 16),
                  _InfoGrid(tech: tech),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'Recent Jobs',
                    subtitle: '${tech.recentJobs.length} items',
                  ),
                  const SizedBox(height: 8),
                  if (tech.recentJobs.isEmpty)
                    Text(
                      'No recent jobs available.',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    )
                  else
                    Column(
                      children: [
                        for (final job in tech.recentJobs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          job.id,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.blue600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          job.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (job.closedDate != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Closed: ${job.closedDate}',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).hintColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  StatusBadge(label: job.status),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'Documents',
                    subtitle: '${tech.documents.length} items',
                  ),
                  const SizedBox(height: 8),
                  if (tech.documents.isEmpty)
                    Text(
                      'No documents uploaded.',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    )
                  else
                    Column(
                      children: [
                        for (final doc in tech.documents)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          doc.documentName.isNotEmpty
                                              ? doc.documentName
                                              : doc.fileName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (doc.expiryStatus.isNotEmpty)
                                        StatusBadge(label: doc.expiryStatus),
                                    ],
                                  ),
                                  if (doc.documentType.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      doc.documentType,
                                      style: TextStyle(
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _MetaChip(
                                        icon: Icons.insert_drive_file_outlined,
                                        label: doc.fileName,
                                      ),
                                      if (doc.expiryDate != null &&
                                          doc.expiryDate!.isNotEmpty)
                                        _MetaChip(
                                          icon: Icons.event_outlined,
                                          label: doc.expiryDate!,
                                        ),
                                      if (doc.mimeType.isNotEmpty)
                                        _MetaChip(
                                          icon: Icons.description_outlined,
                                          label: doc.mimeType,
                                        ),
                                    ],
                                  ),
                                  if (doc.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      doc.notes,
                                      style: TextStyle(
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: AppButton(
                                      label: 'Open File',
                                      variant: AppButtonVariant.secondary,
                                      size: AppButtonSize.sm,
                                      leading: const Icon(
                                        Icons.open_in_new_outlined,
                                      ),
                                      onPressed: () async {
                                        final uri = Uri.tryParse(doc.fileUrl);
                                        if (uri == null) return;
                                        final ok = await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (!ok && context.mounted) {
                                          AppToast.show(
                                            context,
                                            message: 'Unable to open file.',
                                            type: AppToastType.error,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Back',
                          variant: AppButtonVariant.secondary,
                          expanded: true,
                          onPressed: () => context.go('/technicians'),
                        ),
                      ),
                      if (canEdit) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Edit',
                            expanded: true,
                            onPressed: () =>
                                context.push('/technicians/${widget.id}/edit'),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (canDelete) ...[
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Delete Technician',
                      variant: AppButtonVariant.danger,
                      expanded: true,
                      onPressed: () async {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Delete Technician',
                          body:
                              'This will permanently remove ${tech.name}. This cannot be undone.',
                          confirmLabel: 'Delete',
                          confirmVariant: AppButtonVariant.danger,
                        );
                        if (!confirmed || !context.mounted) return;
                        try {
                          await ref
                              .read(techniciansProvider.notifier)
                              .delete(tech.id);
                          if (!context.mounted) return;
                          context.go('/technicians');
                          AppToast.show(
                            context,
                            message: 'Technician removed',
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.tech});

  final Technician tech;

  @override
  Widget build(BuildContext context) {
    final initials = tech.avatar.isNotEmpty
        ? (tech.avatar.length <= 2 ? tech.avatar : tech.avatar.substring(0, 2))
        : initialsFromName(tech.name);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAvatar(initials: initials, size: AppAvatarSize.lg),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tech.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tech.specialization.isEmpty
                            ? 'Technician'
                            : tech.specialization,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusBadge(label: tech.status),
                          if (tech.email.isNotEmpty)
                            _MetaChip(
                              icon: Icons.mail_outline,
                              label: tech.email,
                              dark: true,
                            ),
                          if (tech.phone.isNotEmpty)
                            _MetaChip(
                              icon: Icons.phone_outlined,
                              label: tech.phone,
                              dark: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SummaryChip(
                  icon: Icons.star_outline,
                  label: 'Rating',
                  value: tech.rating.toStringAsFixed(1),
                ),
                _SummaryChip(
                  icon: Icons.work_outline,
                  label: 'Jobs',
                  value: tech.jobsCompleted.toString(),
                ),
                _SummaryChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Joined',
                  value: tech.joinDate ?? '—',
                ),
                if (tech.userId != 0)
                  _SummaryChip(
                    icon: Icons.badge_outlined,
                    label: 'User',
                    value: tech.userId.toString(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.tech});

  final Technician tech;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 720 ? 3 : 2;
    final items = [
      ('Jobs Completed', tech.jobsCompleted.toString()),
      ('Rating', tech.rating.toStringAsFixed(1)),
      ('Join Date', tech.joinDate ?? '—'),
      ('User ID', tech.userId == 0 ? '—' : tech.userId.toString()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.$1,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.$2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.dark = false});

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.08)
            : Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF111827)
            : AppColors.gray50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.12)
              : Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: dark ? Colors.white70 : AppColors.gray400,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: dark ? Colors.white : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (subtitle != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              subtitle!,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _TechnicianDetailSkeleton extends StatelessWidget {
  const _TechnicianDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCard(
            child: Row(
              children: [
                ShimmerBox(width: 56, height: 56, borderRadius: 999),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 160, height: 16, borderRadius: 8),
                      SizedBox(height: 8),
                      ShimmerBox(width: 120, height: 12, borderRadius: 8),
                      SizedBox(height: 8),
                      ShimmerBox(width: 220, height: 12, borderRadius: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: 4,
            itemBuilder: (context, index) =>
                const AppCard(child: ShimmerBox(height: 50, borderRadius: 12)),
          ),
          const SizedBox(height: 16),
          const ShimmerBox(height: 18, width: 140, borderRadius: 8),
          const SizedBox(height: 8),
          const AppCard(
            child: Column(
              children: [
                ShimmerBox(height: 56, borderRadius: 14),
                SizedBox(height: 12),
                ShimmerBox(height: 56, borderRadius: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
