import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/ui_providers.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dropdown_field.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/bottom_safe_area.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/users_notifier.dart';
import '../application/users_state.dart';
import '../domain/app_user.dart';

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    ref.watch(searchQueryProvider);

    ref.listen<String>(searchQueryProvider, (_, next) {
      if (_searchController.text != next) {
        _searchController.text = next;
      }
    });

    return users.when(
      loading: () => const _UsersSkeleton(),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load users',
        description: friendlyErrorMessage(error),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'User Management',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            AppButton(
                              label: '+ Add New',
                              size: AppButtonSize.sm,
                              onPressed: () =>
                                  _openUserSheet(context, ref, null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create users, edit roles, and deactivate access with the same dense admin table as the web app.',
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatPill(
                  label: 'Total',
                  value: data.total,
                  color: AppColors.blue600,
                ),
                _StatPill(
                  label: 'Active',
                  value: data.users.where((u) => u.isActive).length,
                  color: AppColors.emerald500,
                ),
                _StatPill(
                  label: 'Inactive',
                  value: data.users.where((u) => !u.isActive).length,
                  color: AppColors.red500,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: EdgeInsets.zero,
              child: _UsersPremiumTable(
                data: data,
                controller: _searchController,
                onSearch: (query) {
                  ref.read(searchQueryProvider.notifier).state = query;
                  ref.read(usersProvider.notifier).search(query.trim());
                },
                onPrev: data.page <= 1
                    ? null
                    : () => ref.read(usersProvider.notifier).prevPage(),
                onNext: data.page >= data.totalPages
                    ? null
                    : () => ref.read(usersProvider.notifier).nextPage(),
                onEdit: (u) => _openUserSheet(context, ref, u),
                onChangePassword: (u) => _openPasswordSheet(context, ref, u),
                onDeactivate: (u) => _confirmDeactivate(context, ref, u),
                onReactivate: (u) => _confirmReactivate(context, ref, u),
                onPermanentDelete: (u) =>
                    _confirmPermanentDelete(context, ref, u),
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _confirmReactivate(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reactivate user',
      body: 'Reactivate ${user.fullName}? They will regain access.',
      confirmLabel: 'Reactivate',
      confirmVariant: AppButtonVariant.primary,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await ref.read(usersProvider.notifier).reactivate(user.id);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: ok ? 'User reactivated' : 'Operation failed',
      type: ok ? AppToastType.success : AppToastType.error,
    );
  }

  Future<void> _confirmPermanentDelete(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete user permanently',
      body:
          'Permanently delete ${user.fullName}? This removes them from the database and cannot be undone.',
      confirmLabel: 'Delete',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await ref
        .read(usersProvider.notifier)
        .permanentlyDelete(user.id);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: ok ? 'User permanently deleted' : 'Operation failed',
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

  Future<void> _openPasswordSheet(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => _ChangePasswordSheet(
        user: user,
        onSubmit: (password) async {
          final ok = await ref
              .read(usersProvider.notifier)
              .changePassword(user.id, password);
          if (!context.mounted) return;
          Navigator.of(ctx).pop();
          AppToast.show(
            context,
            message: ok ? 'Password updated!' : 'Operation failed',
            type: ok ? AppToastType.success : AppToastType.error,
          );
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

const _roles = ['admin', 'manager', 'engineer', 'technician', 'labour'];

class _UsersPremiumTable extends StatelessWidget {
  const _UsersPremiumTable({
    required this.data,
    required this.controller,
    required this.onSearch,
    required this.onPrev,
    required this.onNext,
    required this.onEdit,
    required this.onChangePassword,
    required this.onDeactivate,
    required this.onReactivate,
    required this.onPermanentDelete,
  });

  final UsersState data;
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<AppUser> onEdit;
  final ValueChanged<AppUser> onChangePassword;
  final ValueChanged<AppUser> onDeactivate;
  final ValueChanged<AppUser> onReactivate;
  final ValueChanged<AppUser> onPermanentDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final headerBg = isDark ? const Color(0xFF0B1220) : AppColors.gray50;
    final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    final rowHover = (isDark ? Colors.white : Colors.black).withValues(
      alpha: 0.04,
    );
    final rowAlt = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);

    final showing = 'Showing ${data.users.length} of ${data.total} users';
    final pageText = 'Page ${data.page} of ${data.totalPages}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Search users…',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0B1220)
                        : AppColors.gray50,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.blue600),
                    ),
                  ),
                  onChanged: onSearch,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            showing,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor),
                left: BorderSide(color: borderColor),
                right: BorderSide(color: borderColor),
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                headingRowHeight: 44,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 68,
                dividerThickness: 0.8,
                horizontalMargin: 16,
                columnSpacing: 22,
                headingRowColor: WidgetStatePropertyAll(headerBg),
                dataRowColor: WidgetStateProperty.resolveWith(
                  (states) =>
                      states.contains(WidgetState.hovered) ? rowHover : null,
                ),
                headingTextStyle: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                columns: const [
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Contact')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (var i = 0; i < data.users.length; i++)
                    _userRow(
                      context,
                      user: data.users[i],
                      index: i,
                      altColor: rowAlt,
                      onEdit: onEdit,
                      onChangePassword: onChangePassword,
                      onDeactivate: onDeactivate,
                      onReactivate: onReactivate,
                      onPermanentDelete: onPermanentDelete,
                    ),
                ],
              ),
            ),
          ),
        ),
        BottomSafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final effectiveWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width;
                final compact = effectiveWidth < 460;

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pageText,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Prev',
                              size: AppButtonSize.sm,
                              variant: AppButtonVariant.secondary,
                              onPressed: onPrev,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppButton(
                              label: 'Next',
                              size: AppButtonSize.sm,
                              variant: AppButtonVariant.secondary,
                              onPressed: onNext,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: Text(pageText, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 10),
                    AppButton(
                      label: 'Previous',
                      size: AppButtonSize.sm,
                      variant: AppButtonVariant.secondary,
                      onPressed: onPrev,
                    ),
                    const SizedBox(width: 10),
                    AppButton(
                      label: 'Next',
                      size: AppButtonSize.sm,
                      variant: AppButtonVariant.secondary,
                      onPressed: onNext,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  DataRow _userRow(
    BuildContext context, {
    required AppUser user,
    required int index,
    required Color altColor,
    required ValueChanged<AppUser> onEdit,
    required ValueChanged<AppUser> onChangePassword,
    required ValueChanged<AppUser> onDeactivate,
    required ValueChanged<AppUser> onReactivate,
    required ValueChanged<AppUser> onPermanentDelete,
  }) {
    final roleColors = _roleColors(user.role);
    final statusColors = user.isActive
        ? (AppColors.emerald500.withValues(alpha: 0.14), AppColors.emerald500)
        : (AppColors.red500.withValues(alpha: 0.14), AppColors.red500);

    return DataRow(
      color: WidgetStateProperty.resolveWith(
        (states) => index.isEven ? altColor.withValues(alpha: 0.35) : null,
      ),
      cells: [
        DataCell(
          Row(
            children: [
              AppAvatar(
                initials: initialsFromName(user.fullName),
                size: AppAvatarSize.md,
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: roleColors.$1,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 16, color: roleColors.$2),
                const SizedBox(width: 6),
                Text(
                  _titleCase(user.role),
                  style: TextStyle(
                    color: roleColors.$2,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Text(user.phoneNumber?.isNotEmpty == true ? user.phoneNumber! : '—'),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: statusColors.$1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 16,
                  color: statusColors.$2,
                ),
                const SizedBox(width: 6),
                Text(
                  user.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: statusColors.$2,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<_UserAction>(
              tooltip: 'Actions',
              icon: const Icon(Icons.more_horiz),
              onSelected: (action) {
                switch (action) {
                  case _UserAction.edit:
                    onEdit(user);
                    break;
                  case _UserAction.changePassword:
                    onChangePassword(user);
                    break;
                  case _UserAction.deactivate:
                    onDeactivate(user);
                    break;
                  case _UserAction.reactivate:
                    onReactivate(user);
                    break;
                  case _UserAction.permanentDelete:
                    onPermanentDelete(user);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _UserAction.edit,
                  child: Row(
                    children: const [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Edit user'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _UserAction.changePassword,
                  child: Row(
                    children: const [
                      Icon(Icons.key_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Change password'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _UserAction.deactivate,
                  enabled: user.isActive,
                  child: Row(
                    children: const [
                      Icon(Icons.block_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Deactivate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _UserAction.reactivate,
                  enabled: !user.isActive,
                  child: Row(
                    children: const [
                      Icon(Icons.restart_alt_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Reactivate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _UserAction.permanentDelete,
                  child: Row(
                    children: const [
                      Icon(Icons.delete_forever_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Permanently Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static (Color, Color) _roleColors(String role) {
    return switch (role) {
      'admin' => (const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
      'manager' => (const Color(0xFFE0E7FF), const Color(0xFF4F46E5)),
      'engineer' => (const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
      'technician' => (const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
      'labour' => (const Color(0xFFFFEDD5), const Color(0xFFEA580C)),
      _ => (AppColors.gray100, AppColors.gray700),
    };
  }
}

enum _UserAction {
  edit,
  changePassword,
  deactivate,
  reactivate,
  permanentDelete,
}

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
                    child: AppDropdownField<String>(
                      label: 'Role *',
                      value: _role,
                      items: [
                        for (final r in _roles)
                          AppDropdownItem(value: r, label: r),
                      ],
                      enabled: !_loading,
                      onChanged: (v) =>
                          setState(() => _role = v ?? _roles.first),
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
                              ).dividerColor.withValues(alpha: 0.12),
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

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.user, required this.onSubmit});

  final AppUser user;
  final Future<void> Function(String password) onSubmit;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _password = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final password = _password.text.trim();
    if (password.length < 6) {
      AppToast.show(
        context,
        message: 'Password must be at least 6 characters.',
        type: AppToastType.error,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSubmit(password);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.7,
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
              'Change Password',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              widget.user.fullName,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            AppInput(
              label: 'New Password *',
              controller: _password,
              type: AppInputType.password,
              enabled: !_saving,
            ),
            const SizedBox(height: 20),
            BottomSafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      expanded: true,
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Update Password',
                      expanded: true,
                      loading: _saving,
                      onPressed: _saving ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
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
              color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
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
                            ).dividerColor.withValues(alpha: 0.12),
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
                              ).dividerColor.withValues(alpha: 0.12),
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
