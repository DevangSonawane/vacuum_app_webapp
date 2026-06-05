import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/bottom_safe_area.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/attendance_employees_notifier.dart';
import '../domain/attendance_employee.dart';

String _formatDate(String? value) {
  if (value == null || value.trim().isEmpty) return '—';
  final input = value.trim();
  try {
    if (input.contains('T')) {
      return DateTime.parse(input).toLocal().toString().split(' ').first;
    }
    if (input.contains('/')) {
      final parts = input.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        ).toIso8601String().split('T').first;
      }
    }
    return DateTime.parse(input).toIso8601String().split('T').first;
  } catch (_) {
    return input;
  }
}

String _currency(num? value) {
  if (value == null) return 'Not set';
  return '₹${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

const _softRed = Color(0xFFFEE2E2);
const _softBlue = Color(0xFFEFF6FF);

class AttendanceEmployeesScreen extends ConsumerStatefulWidget {
  const AttendanceEmployeesScreen({super.key});

  @override
  ConsumerState<AttendanceEmployeesScreen> createState() =>
      _AttendanceEmployeesScreenState();
}

class _AttendanceEmployeesScreenState
    extends ConsumerState<AttendanceEmployeesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canView = role == 'admin' || role == 'manager';
    final canManage = role == 'admin';

    if (!canView) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Access restricted',
        description: 'Employee records are available to admins and managers only.',
      );
    }

    final state = ref.watch(attendanceEmployeesProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(attendanceEmployeesProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Employees',
              subtitle: 'Manage RazorpayX employee records',
              action: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (canManage)
                    AppButton(
                      label: 'Add Employee',
                      variant: AppButtonVariant.outline,
                      onPressed: () => _openAddSheet(context),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            state.when(
              loading: () => const _EmployeesSkeleton(),
              error: (error, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load employees',
                description: 'Could not load employee records right now.',
              ),
              data: (employees) {
                final filtered = employees.where((emp) {
                  if (_query.isEmpty) return true;
                  return [
                    emp.name,
                    emp.email,
                    emp.department,
                    emp.title,
                    emp.employeeId,
                    emp.phoneNumber,
                  ].any((value) => value.toLowerCase().contains(_query));
                }).toList();

                final active = employees.where((e) => e.isActive).length;
                final inactive = employees.length - active;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.9,
                      children: [
                        StatCard(title: 'Total Employees', value: '${employees.length}'),
                        StatCard(title: 'Active', value: '$active'),
                        StatCard(title: 'Inactive', value: '$inactive'),
                        StatCard(title: 'Managed', value: '${employees.where((e) => e.annualCtc != null).length}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search by name, email, department, title…',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      const EmptyState(
                        icon: Icons.badge_outlined,
                        title: 'No employees found',
                        description: 'Try a different search or add a new employee.',
                      )
                    else
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dataTableTheme: DataTableThemeData(
                                headingRowColor: WidgetStateProperty.all(
                                  Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF111827)
                                      : AppColors.gray50,
                                ),
                                dataRowColor: WidgetStateProperty.resolveWith(
                                  (states) {
                                    if (states.contains(WidgetState.selected) ||
                                        states.contains(WidgetState.hovered)) {
                                      return (Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black)
                                          .withValues(alpha: 0.04);
                                    }
                                    return Colors.transparent;
                                  },
                                ),
                                headingTextStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.gray500,
                                ),
                                dataTextStyle: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray700,
                                ),
                              ),
                            ),
                            child: DataTable(
                              showCheckboxColumn: false,
                              headingRowHeight: 44,
                              dataRowMinHeight: 54,
                              dataRowMaxHeight: 64,
                              horizontalMargin: 16,
                              columnSpacing: 20,
                              dividerThickness: 0.6,
                              columns: const [
                                DataColumn(label: Text('Employee')),
                                DataColumn(label: Text('Department / Title')),
                                DataColumn(label: Text('Contact')),
                                DataColumn(label: Text('Annual CTC')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: [
                                for (final emp in filtered)
                                  DataRow(
                                    selected: false,
                                    onSelectChanged: canView
                                        ? (_) => context.push(
                                              '/attendance/${emp.employeeId}',
                                              extra: emp,
                                            )
                                        : null,
                                    cells: [
                                      DataCell(
                                        InkWell(
                                          onTap: canView
                                              ? () => context.push(
                                                    '/attendance/${emp.employeeId}',
                                                    extra: emp,
                                                  )
                                              : null,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Color(0xFF3B82F6),
                                                      Color(0xFF4F46E5),
                                                    ],
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  initialsFromName(emp.name),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints(
                                                  maxWidth: 180,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      emp.name,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.gray800,
                                                      ),
                                                    ),
                                                    Text(
                                                      'ID: ${emp.employeeId}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.gray500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              emp.department.isEmpty
                                                  ? '—'
                                                  : emp.department,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.gray700,
                                              ),
                                            ),
                                            Text(
                                              emp.title.isEmpty ? '—' : emp.title,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.gray500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              emp.email.isEmpty ? '—' : emp.email,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.gray700,
                                              ),
                                            ),
                                            Text(
                                              emp.phoneNumber.isEmpty
                                                  ? '—'
                                                  : emp.phoneNumber,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.gray500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _currency(emp.annualCtc),
                                          style: TextStyle(
                                            fontWeight: emp.annualCtc == null
                                                ? FontWeight.w400
                                                : FontWeight.w700,
                                            color: emp.annualCtc == null
                                                ? AppColors.gray500
                                                : AppColors.gray800,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        StatusBadge(
                                          label: emp.isActive ? 'Active' : 'Inactive',
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              tooltip: 'View attendance',
                                              onPressed: canView
                                                  ? () => context.push(
                                                        '/attendance/${emp.employeeId}',
                                                        extra: emp,
                                                      )
                                                  : null,
                                              icon: const Icon(Icons.visibility_outlined),
                                            ),
                                            if (canManage)
                                              IconButton(
                                                tooltip: 'Edit employee',
                                                onPressed: () =>
                                                    _openEditSheet(context, emp),
                                                icon:
                                                    const Icon(Icons.edit_outlined),
                                              ),
                                            if (canManage)
                                              IconButton(
                                                tooltip: 'Set salary',
                                                onPressed: () =>
                                                    _openSalarySheet(context, emp),
                                                icon: const Icon(
                                                  Icons.payments_outlined,
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
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _AddEmployeeSheet(),
    );
  }

  Future<void> _openEditSheet(BuildContext context, AttendanceEmployee employee) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _EditEmployeeSheet(employee: employee),
    );
  }

  Future<void> _openSalarySheet(BuildContext context, AttendanceEmployee employee) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _SalarySheet(employee: employee),
    );
  }
}

class _EmployeesSkeleton extends StatelessWidget {
  const _EmployeesSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < 5; i++) ...[
              const ShimmerBox(height: 48),
              if (i != 4) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmployeeDetailRow extends StatelessWidget {
  const _EmployeeDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gray500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEmployeeSheet extends ConsumerStatefulWidget {
  const _AddEmployeeSheet();

  @override
  ConsumerState<_AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends ConsumerState<_AddEmployeeSheet> {
  final _employeeId = TextEditingController();
  bool _fetching = false;
  bool _saving = false;
  String? _error;
  AttendanceEmployee? _preview;

  @override
  void dispose() {
    _employeeId.dispose();
    super.dispose();
  }

  Future<void> _fetchPreview() async {
    final id = _employeeId.text.trim();
    if (id.isEmpty) return;
    setState(() {
      _fetching = true;
      _error = null;
      _preview = null;
    });

    try {
      final preview =
          await ref.read(attendanceEmployeesProvider.notifier).previewEmployee(id);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        if (preview == null) {
          _error = 'Could not fetch the employee preview.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not fetch the employee preview.';
      });
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _save() async {
    final preview = _preview;
    if (preview == null) return;

    setState(() => _saving = true);
    final ok = await ref.read(attendanceEmployeesProvider.notifier).storeEmployee(
      employeeId: _employeeId.text.trim(),
      employee: preview,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
      AppToast.show(
        context,
        message: 'Employee stored successfully',
        type: AppToastType.success,
      );
    } else {
      AppToast.show(
        context,
        message: 'Failed to store employee',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.65,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => ListView(
        controller: scroll,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        children: [
          Text('Fetch Employee from RazorpayX', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Enter the numeric employee ID to preview the record before saving it locally.',
            style: TextStyle(color: AppColors.gray500),
          ),
          const SizedBox(height: 16),
          AppInput(
            label: 'RazorpayX Employee ID',
            controller: _employeeId,
            type: AppInputType.number,
            placeholder: 'e.g. 1',
            required: true,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _softRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.red500),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_preview != null) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppAvatar(
                        initials: initialsFromName(_preview!.name),
                        size: AppAvatarSize.md,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _preview!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              [
                                _preview!.title,
                                _preview!.department,
                              ].where((v) => v.isNotEmpty).join(' · '),
                              style: const TextStyle(color: AppColors.gray500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth >= 560 ? 2 : 1;
                      final entries = [
                        ('Employee ID', _employeeId.text.trim()),
                        ('Email', _preview!.email),
                        ('Phone', _preview!.phoneNumber),
                        ('Date of Birth', _formatDate(_preview!.dateOfBirth)),
                        ('Date of Hiring', _formatDate(_preview!.dateOfHiring)),
                        ('Department', _preview!.department),
                        ('Manager Email', _preview!.managerEmail ?? '—'),
                        ('PAN', _preview!.pan ?? '—'),
                        ('Bank IFSC', _preview!.bankIfsc ?? '—'),
                        ('Bank Account', _preview!.bankAccountNumber ?? '—'),
                      ];

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: cols,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 10,
                        childAspectRatio: cols == 2 ? 3.1 : 4.2,
                        children: [
                          for (final entry in entries)
                            _EmployeeDetailRow(
                              label: entry.$1,
                              value: entry.$2,
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
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
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: _preview == null ? 'Fetch Preview' : 'Save to Database',
                    expanded: true,
                    loading: _fetching || _saving,
                    onPressed: _fetching || _saving
                        ? null
                        : (_preview == null ? _fetchPreview : _save),
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

class _EditEmployeeSheet extends ConsumerStatefulWidget {
  const _EditEmployeeSheet({required this.employee});

  final AttendanceEmployee employee;

  @override
  ConsumerState<_EditEmployeeSheet> createState() => _EditEmployeeSheetState();
}

class _EditEmployeeSheetState extends ConsumerState<_EditEmployeeSheet> {
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _title;
  late final TextEditingController _department;
  late final TextEditingController _managerId;
  late final TextEditingController _managerType;
  late final TextEditingController _hiringDate;
  late final TextEditingController _state;
  late final TextEditingController _pan;
  late final TextEditingController _bankIfsc;
  late final TextEditingController _bankAccount;
  late final TextEditingController _pastSalary;
  late final TextEditingController _pastExemption;
  late final TextEditingController _pastTds;
  late final TextEditingController _prevSalary;
  late final TextEditingController _prevTds;
  bool _ptEnabled = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.employee.email);
    _phone = TextEditingController(text: widget.employee.phoneNumber);
    _title = TextEditingController(text: widget.employee.title);
    _department = TextEditingController(text: widget.employee.department);
    _managerId = TextEditingController(text: widget.employee.managerEmployeeId ?? '');
    _managerType = TextEditingController(text: 'employee');
    _hiringDate = TextEditingController(text: widget.employee.dateOfHiring ?? '');
    _state = TextEditingController();
    _pan = TextEditingController(text: widget.employee.pan ?? '');
    _bankIfsc = TextEditingController(text: widget.employee.bankIfsc ?? '');
    _bankAccount = TextEditingController(text: widget.employee.bankAccountNumber ?? '');
    _pastSalary = TextEditingController(text: '0');
    _pastExemption = TextEditingController(text: '0');
    _pastTds = TextEditingController(text: '0');
    _prevSalary = TextEditingController(text: '0');
    _prevTds = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _title.dispose();
    _department.dispose();
    _managerId.dispose();
    _managerType.dispose();
    _hiringDate.dispose();
    _state.dispose();
    _pan.dispose();
    _bankIfsc.dispose();
    _bankAccount.dispose();
    _pastSalary.dispose();
    _pastExemption.dispose();
    _pastTds.dispose();
    _prevSalary.dispose();
    _prevTds.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'email': _email.text.trim(),
      'title': _title.text.trim(),
      'department': _department.text.trim(),
      'manager-employee-id': _managerId.text.trim().isEmpty ? null : num.tryParse(_managerId.text.trim()) ?? _managerId.text.trim(),
      'manager-employee-type': _managerType.text.trim().isEmpty ? 'employee' : _managerType.text.trim(),
      'bank-ifsc': _bankIfsc.text.trim(),
      'bank-account-number': _bankAccount.text.trim(),
      'pan': _pan.text.trim(),
      'phone-number': _phone.text.trim(),
      'hiring-date': _hiringDate.text.trim(),
      'state': _state.text.trim(),
      'pt-enabled': _ptEnabled,
      'pastSalary': num.tryParse(_pastSalary.text.trim()) ?? 0,
      'pastExemption': num.tryParse(_pastExemption.text.trim()) ?? 0,
      'pastTds': num.tryParse(_pastTds.text.trim()) ?? 0,
      'previousEmployerSalary': num.tryParse(_prevSalary.text.trim()) ?? 0,
      'previousEmployerTds': num.tryParse(_prevTds.text.trim()) ?? 0,
    }..removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    final ok = await ref.read(attendanceEmployeesProvider.notifier).updateEmployee(
      employeeId: widget.employee.employeeId,
      payload: payload,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
      AppToast.show(
        context,
        message: 'Employee updated successfully',
        type: AppToastType.success,
      );
    } else {
      AppToast.show(
        context,
        message: 'Failed to update employee',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.72,
      maxChildSize: 0.96,
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
            Text('Edit Employee', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              widget.employee.name,
              style: const TextStyle(color: AppColors.gray500),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.6,
              children: [
                AppInput(label: 'Email', controller: _email, type: AppInputType.email, placeholder: 'email@example.com'),
                AppInput(label: 'Phone Number', controller: _phone, type: AppInputType.phone, placeholder: '9810012345'),
                AppInput(label: 'Title', controller: _title, placeholder: 'Job title'),
                AppInput(label: 'Department', controller: _department, placeholder: 'Department'),
                AppInput(label: 'Manager Employee ID', controller: _managerId, type: AppInputType.number, placeholder: '127'),
                AppInput(label: 'Manager Type', controller: _managerType, placeholder: 'employee / contractor'),
                AppInput(label: 'Hiring Date', controller: _hiringDate, placeholder: 'YYYY-MM-DD'),
                AppInput(label: 'State (PT)', controller: _state, placeholder: 'e.g. karnataka'),
                AppInput(label: 'PAN', controller: _pan, placeholder: 'AGCPJ0387P'),
                AppInput(label: 'Bank IFSC', controller: _bankIfsc, placeholder: 'CORP0002106'),
                AppInput(label: 'Bank Account Number', controller: _bankAccount, placeholder: '1234567890'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Previous Employer Details',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.6,
              children: [
                AppInput(label: 'Past Salary (₹)', controller: _pastSalary, type: AppInputType.number),
                AppInput(label: 'Past Exemption (₹)', controller: _pastExemption, type: AppInputType.number),
                AppInput(label: 'Past TDS (₹)', controller: _pastTds, type: AppInputType.number),
                AppInput(label: 'Prev Employer Salary (₹)', controller: _prevSalary, type: AppInputType.number),
                AppInput(label: 'Prev Employer TDS (₹)', controller: _prevTds, type: AppInputType.number),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Professional Tax (PT)'),
              value: _ptEnabled,
              onChanged: _saving ? null : (value) => setState(() => _ptEnabled = value),
            ),
            const SizedBox(height: 16),
            BottomSafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      expanded: true,
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Save Changes',
                      expanded: true,
                      loading: _saving,
                      onPressed: _saving ? null : _save,
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

class _SalarySheet extends ConsumerStatefulWidget {
  const _SalarySheet({required this.employee});

  final AttendanceEmployee employee;

  @override
  ConsumerState<_SalarySheet> createState() => _SalarySheetState();
}

class _SalarySheetState extends ConsumerState<_SalarySheet> {
  late final TextEditingController _annualCtc;
  bool _customSalaryStructure = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _annualCtc = TextEditingController(
      text: widget.employee.annualCtc?.toString() ?? '',
    );
    _customSalaryStructure = widget.employee.customSalaryStructure;
  }

  @override
  void dispose() {
    _annualCtc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final annualCtc = num.tryParse(_annualCtc.text.trim());
    if (annualCtc == null) {
      AppToast.show(
        context,
        message: 'Enter a valid annual CTC.',
        type: AppToastType.error,
      );
      return;
    }

    setState(() => _saving = true);
    final ok = await ref.read(attendanceEmployeesProvider.notifier).setSalary(
      employeeId: widget.employee.employeeId,
      annualCtc: annualCtc,
      customSalaryStructure: _customSalaryStructure,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
      AppToast.show(
        context,
        message: 'Salary updated successfully',
        type: AppToastType.success,
      );
    } else {
      AppToast.show(
        context,
        message: 'Failed to set salary',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.45,
      maxChildSize: 0.8,
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
            Text('Set Salary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF0B1220)
                    : _softBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Annual CTC',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currency(widget.employee.annualCtc),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppInput(
              label: 'Annual CTC (₹)',
              controller: _annualCtc,
              type: AppInputType.number,
              placeholder: '600000',
              required: true,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use Custom Salary Structure'),
              value: _customSalaryStructure,
              onChanged: _saving ? null : (value) => setState(() => _customSalaryStructure = value),
            ),
            const SizedBox(height: 16),
            BottomSafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      expanded: true,
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Set Salary',
                      expanded: true,
                      loading: _saving,
                      onPressed: _saving ? null : _save,
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
