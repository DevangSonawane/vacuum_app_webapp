import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/users_notifier.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).valueOrNull;
    final isAdmin = auth?.user?.role == 'admin';
    if (!isAdmin) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Admin only',
        description: 'You do not have access to User Management.',
      );
    }

    final users = ref.watch(usersProvider);

    return users.when(
      loading: () => const _UsersSkeleton(),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load users',
        description: error.toString(),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'User Management',
              subtitle: 'Manage system access and user roles',
              action: AppButton(
                label: '+ Add New User',
                variant: AppButtonVariant.outline,
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Users', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      SizedBox(
                        width: 240,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search…',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                          ),
                          onChanged: (_) {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('User')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Contact')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: [
                        for (final u in data.users)
                          DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    AppAvatar(
                                      initials: initialsFromName(u.fullName),
                                      size: AppAvatarSize.md,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text(
                                          u.email,
                                          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Row(children: [
                                const Icon(Icons.shield_outlined, size: 18, color: AppColors.blue600),
                                const SizedBox(width: 8),
                                Text(_titleCase(u.role)),
                              ])),
                              DataCell(Text(u.phoneNumber?.isNotEmpty == true ? u.phoneNumber! : '—')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: (u.isActive ? AppColors.emerald500 : AppColors.red500)
                                        .withValues(alpha: 0.15),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        u.isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                                        size: 16,
                                        color: u.isActive ? AppColors.emerald500 : AppColors.red500,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        u.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          color: u.isActive ? AppColors.emerald500 : AppColors.red500,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      onPressed: () {},
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.blue600),
                                    ),
                                    IconButton(
                                      tooltip: 'Deactivate',
                                      onPressed: u.isActive ? () {} : null,
                                      icon: const Icon(Icons.delete_outline, color: AppColors.red500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text('Showing ${data.users.length} of ${data.total} users'),
                      const Spacer(),
                      AppButton(
                        label: 'Previous',
                        variant: AppButtonVariant.secondary,
                        onPressed: data.page <= 1 ? null : () => ref.read(usersProvider.notifier).prevPage(),
                      ),
                      const SizedBox(width: 10),
                      Text('Page ${data.page} of ${data.totalPages}'),
                      const SizedBox(width: 10),
                      AppButton(
                        label: 'Next',
                        variant: AppButtonVariant.secondary,
                        onPressed: data.page >= data.totalPages ? null : () => ref.read(usersProvider.notifier).nextPage(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _UsersSkeleton extends StatelessWidget {
  const _UsersSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 280,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                for (int i = 0; i < 6; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
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
    );
  }
}
