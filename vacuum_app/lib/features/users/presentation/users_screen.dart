import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/bottom_safe_area.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/users_notifier.dart';
import '../domain/app_user.dart';

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
                onPressed: () => _openUserSheet(context, ref, null),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search users…',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                          ),
                          onChanged: (query) =>
                              ref.read(usersProvider.notifier).search(query),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          u.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          u.email,
                                          style: TextStyle(
                                            color: Theme.of(context).hintColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shield_outlined,
                                      size: 18,
                                      color: AppColors.blue600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_titleCase(u.role)),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  u.phoneNumber?.isNotEmpty == true
                                      ? u.phoneNumber!
                                      : '—',
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color:
                                        (u.isActive
                                                ? AppColors.emerald500
                                                : AppColors.red500)
                                            .withValues(alpha: 0.15),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        u.isActive
                                            ? Icons.check_circle_outline
                                            : Icons.cancel_outlined,
                                        size: 16,
                                        color: u.isActive
                                            ? AppColors.emerald500
                                            : AppColors.red500,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        u.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          color: u.isActive
                                              ? AppColors.emerald500
                                              : AppColors.red500,
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
                                      onPressed: () =>
                                          _openUserSheet(context, ref, u),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: AppColors.blue600,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Deactivate',
                                      onPressed: u.isActive
                                          ? () => _confirmDeactivate(
                                              context,
                                              ref,
                                              u,
                                            )
                                          : null,
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.red500,
                                      ),
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final showing =
                          'Showing ${data.users.length} of ${data.total} users';
                      final pageText =
                          'Page ${data.page} of ${data.totalPages}';
                      final effectiveWidth = constraints.maxWidth.isFinite
                          ? constraints.maxWidth
                          : MediaQuery.sizeOf(context).width;
                      final compact = effectiveWidth < 420;

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(showing),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'Prev',
                                    size: AppButtonSize.sm,
                                    variant: AppButtonVariant.secondary,
                                    onPressed: data.page <= 1
                                        ? null
                                        : () => ref
                                              .read(usersProvider.notifier)
                                              .prevPage(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: AppButton(
                                    label: 'Next',
                                    size: AppButtonSize.sm,
                                    variant: AppButtonVariant.secondary,
                                    onPressed: data.page >= data.totalPages
                                        ? null
                                        : () => ref
                                              .read(usersProvider.notifier)
                                              .nextPage(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              pageText,
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              showing,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppButton(
                            label: 'Previous',
                            size: AppButtonSize.sm,
                            variant: AppButtonVariant.secondary,
                            onPressed: data.page <= 1
                                ? null
                                : () => ref
                                      .read(usersProvider.notifier)
                                      .prevPage(),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              pageText,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          AppButton(
                            label: 'Next',
                            size: AppButtonSize.sm,
                            variant: AppButtonVariant.secondary,
                            onPressed: data.page >= data.totalPages
                                ? null
                                : () => ref
                                      .read(usersProvider.notifier)
                                      .nextPage(),
                          ),
                        ],
                      );
                    },
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

  Future<void> _confirmDeactivate(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Deactivate user',
      body: 'Deactivate ${user.fullName}? They will not be able to sign in.',
      confirmLabel: 'Deactivate',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await ref.read(usersProvider.notifier).deactivate(user.id);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: ok ? 'User deactivated' : 'Operation failed',
      type: ok ? AppToastType.success : AppToastType.error,
    );
  }

  Future<void> _openUserSheet(
    BuildContext context,
    WidgetRef ref,
    AppUser? existing,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => _UserFormSheet(
        existing: existing,
        fetchById: existing == null
            ? null
            : () => ref.read(usersProvider.notifier).fetchById(existing.id),
        onSubmit: (payload, isEdit, id) async {
          final ok = isEdit && id != null
              ? await ref
                    .read(usersProvider.notifier)
                    .updateUserDetails(id, payload)
              : await ref.read(usersProvider.notifier).createUser(payload);
          if (!context.mounted) return;
          Navigator.of(ctx).pop();
          AppToast.show(
            context,
            message: ok
                ? (isEdit ? 'User updated!' : 'User created!')
                : 'Operation failed',
            type: ok ? AppToastType.success : AppToastType.error,
          );
        },
      ),
    );
  }
}

const _roles = ['admin', 'manager', 'engineer', 'technician', 'labour'];

class _UserFormSheet extends StatefulWidget {
  const _UserFormSheet({
    required this.existing,
    required this.fetchById,
    required this.onSubmit,
  });

  final AppUser? existing;
  final Future<AppUser?> Function()? fetchById;
  final Future<void> Function(
    Map<String, dynamic> payload,
    bool isEdit,
    int? id,
  )
  onSubmit;

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  String _role = _roles.first;
  bool _active = true;

  bool _loading = false;
  bool _fetching = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final u = widget.existing;
    if (u != null) {
      _first.text = u.firstName;
      _last.text = u.lastName;
      _email.text = u.email;
      _phone.text = u.phoneNumber ?? '';
      _role = _roles.contains(u.role) ? u.role : _roles.first;
      _active = u.isActive;
      _loadLatest();
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadLatest() async {
    final fetch = widget.fetchById;
    if (fetch == null) return;
    setState(() => _fetching = true);
    final latest = await fetch();
    if (!mounted) return;
    setState(() => _fetching = false);
    if (latest == null) return;
    _first.text = latest.firstName;
    _last.text = latest.lastName;
    _email.text = latest.email;
    _phone.text = latest.phoneNumber ?? '';
    _role = _roles.contains(latest.role) ? latest.role : _roles.first;
    _active = latest.isActive;
    setState(() {});
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (_first.text.trim().isEmpty || _last.text.trim().isEmpty) {
      AppToast.show(
        context,
        message: 'First and last name are required.',
        type: AppToastType.error,
      );
      return;
    }
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    if (email.isEmpty && phone.isEmpty) {
      AppToast.show(
        context,
        message: 'Email or phone is required.',
        type: AppToastType.error,
      );
      return;
    }
    if (!_isEdit && _password.text.trim().isEmpty) {
      AppToast.show(
        context,
        message: 'Password is required for new users.',
        type: AppToastType.error,
      );
      return;
    }

    setState(() => _loading = true);

    final payload = <String, dynamic>{
      'first_name': _first.text.trim(),
      'last_name': _last.text.trim(),
      'role': _role,
      'is_active': _active,
      if (email.isNotEmpty) 'email': email,
      if (phone.isNotEmpty)
        'phone_number': phone.startsWith('+') ? phone : '+91$phone',
      if (!_isEdit) 'password': _password.text.trim(),
    };

    await widget.onSubmit(payload, _isEdit, widget.existing?.id);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? 'Edit User' : 'Add New User',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_fetching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: AppInput(
                      label: 'First Name *',
                      controller: _first,
                      enabled: !_loading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppInput(
                      label: 'Last Name *',
                      controller: _last,
                      enabled: !_loading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppInput(
                      label: 'Email',
                      controller: _email,
                      type: AppInputType.email,
                      enabled: !_loading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppInput(
                      label: 'Phone',
                      controller: _phone,
                      type: AppInputType.phone,
                      enabled: !_loading,
                      placeholder: '9876543210',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Role *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _role,
                          isExpanded: true,
                          menuMaxHeight: 360,
                          borderRadius: BorderRadius.circular(14),
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          decoration: const InputDecoration(isDense: true),
                          items: _roles
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    r,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _loading
                              ? null
                              : (v) =>
                                    setState(() => _role = v ?? _roles.first),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Is Active',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Switch(
                                value: _active,
                                onChanged: _loading
                                    ? null
                                    : (v) => setState(() => _active = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 12),
                AppInput(
                  label: 'Password *',
                  controller: _password,
                  type: AppInputType.password,
                  enabled: !_loading,
                ),
              ],
              const SizedBox(height: 20),
              BottomSafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        variant: AppButtonVariant.secondary,
                        expanded: true,
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: _isEdit ? 'Update User' : 'Create User',
                        expanded: true,
                        loading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.15),
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
