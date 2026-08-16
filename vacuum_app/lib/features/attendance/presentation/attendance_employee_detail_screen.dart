import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance_employee.dart';
import '../domain/attendance_record.dart';

String _formatDate(String? value) {
  if (value == null || value.trim().isEmpty) return '—';
  final input = value.trim();
  final months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  DateTime? parseDate(String raw) {
    try {
      if (raw.contains('T')) return DateTime.parse(raw).toLocal();
      if (raw.contains('/')) {
        final parts = raw.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  try {
    final date = parseDate(input);
    if (date != null) {
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    }
  } catch (_) {}

  return input;
}

String _formatCurrency(num? value) {
  if (value == null) return 'Not set';
  return '₹${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

DateTime _startOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

DateTime _shiftDate(DateTime date, int days) =>
    _startOfDay(date.add(Duration(days: days)));

String _displayDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.year}';

String _displayStatus(String? value) {
  final input = (value ?? 'Unknown').trim();
  if (input.isEmpty) return 'Unknown';
  return input
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return word;
        final lower = word.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

const _softRed = Color(0xFFFEE2E2);
const _softBlue = Color(0xFFEFF6FF);
const _softAmber = Color(0xFFFEF3C7);
const _softEmerald = Color(0xFFD1FAE5);

class AttendanceEmployeeDetailScreen extends ConsumerStatefulWidget {
  const AttendanceEmployeeDetailScreen({
    super.key,
    required this.employeeId,
    this.employee,
  });

  final String employeeId;
  final AttendanceEmployee? employee;

  @override
  ConsumerState<AttendanceEmployeeDetailScreen> createState() =>
      _AttendanceEmployeeDetailScreenState();
}

class _AttendanceEmployeeDetailScreenState
    extends ConsumerState<AttendanceEmployeeDetailScreen> {
  AttendanceEmployee? _employee;
  bool _employeeLoading = true;
  String? _employeeError;

  DateTime _date = _startOfDay(DateTime.now());
  AttendanceRecord? _attendance;
  bool _attendanceLoading = false;
  String? _attendanceError;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _employeeLoading = widget.employee == null;
    if (widget.employee == null) {
      _loadEmployee();
    } else {
      _loadAttendance();
    }
  }

  Future<void> _loadEmployee() async {
    setState(() {
      _employeeLoading = true;
      _employeeError = null;
    });
    try {
      final repo = AttendanceRepository(dio: ref.read(dioProvider));
      final employee = await repo.fetchEmployee(widget.employeeId);
      if (!mounted) return;
      if (employee == null) {
        setState(() {
          _employeeError = null;
          _employee = null;
        });
        return;
      }
      setState(() {
        _employee = employee;
      });
      await _loadAttendance();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _employeeError = 'Could not load employee details right now.';
      });
    } finally {
      if (mounted) setState(() => _employeeLoading = false);
    }
  }

  Future<void> _loadAttendance() async {
    final employee = _employee;
    if (employee == null || employee.email.isEmpty) return;

    setState(() {
      _attendanceLoading = true;
      _attendanceError = null;
      _attendance = null;
    });
    try {
      final repo = AttendanceRepository(dio: ref.read(dioProvider));
      final record = await repo.fetchAttendanceRecord(
        email: employee.email,
        date: _date.toIso8601String().split('T').first,
        employeeType: 'employee',
      );
      if (!mounted) return;
      setState(() => _attendance = record);
    } catch (e) {
      if (!mounted) return;
      setState(() => _attendanceError = 'Could not load attendance right now.');
    } finally {
      if (mounted) setState(() => _attendanceLoading = false);
    }
  }

  Widget _buildAttendanceTab({
    required Key key,
    required AttendanceEmployee employee,
    required Color accent,
    required Color accentSoft,
  }) {
    final statusText = _displayStatus(
      _attendance?.statusDescription ?? 'Unknown',
    );

    return KeyedSubtree(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final datePicker = GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _date = _startOfDay(picked));
                    await _loadAttendance();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0B1220)
                        : AppColors.gray50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _displayDate(_date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _DateNavButton(
                          icon: Icons.chevron_left,
                          onPressed: () {
                            setState(() => _date = _shiftDate(_date, -1));
                            _loadAttendance();
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: datePicker),
                        const SizedBox(width: 8),
                        _DateNavButton(
                          icon: Icons.chevron_right,
                          onPressed: _date.isBefore(_startOfDay(DateTime.now()))
                              ? () {
                                  setState(() => _date = _shiftDate(_date, 1));
                                  _loadAttendance();
                                }
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AppButton(
                          label: 'Today',
                          size: AppButtonSize.sm,
                          variant: _date == _startOfDay(DateTime.now())
                              ? AppButtonVariant.primary
                              : AppButtonVariant.secondary,
                          onPressed: () {
                            setState(() => _date = _startOfDay(DateTime.now()));
                            _loadAttendance();
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Reload attendance',
                          onPressed: _loadAttendance,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _DateNavButton(
                    icon: Icons.chevron_left,
                    onPressed: () {
                      setState(() => _date = _shiftDate(_date, -1));
                      _loadAttendance();
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: datePicker),
                  const SizedBox(width: 8),
                  AppButton(
                    label: 'Today',
                    size: AppButtonSize.sm,
                    variant: _date == _startOfDay(DateTime.now())
                        ? AppButtonVariant.primary
                        : AppButtonVariant.secondary,
                    onPressed: () {
                      setState(() => _date = _startOfDay(DateTime.now()));
                      _loadAttendance();
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Reload attendance',
                    onPressed: _loadAttendance,
                    icon: const Icon(Icons.refresh),
                  ),
                  _DateNavButton(
                    icon: Icons.chevron_right,
                    onPressed: _date.isBefore(_startOfDay(DateTime.now()))
                        ? () {
                            setState(() => _date = _shiftDate(_date, 1));
                            _loadAttendance();
                          }
                        : null,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (_attendanceLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_attendanceError != null)
            EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load attendance',
              description: _attendanceError!,
            )
          else if (_attendance == null)
            const EmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No attendance record',
              description: 'No data found for the selected date.',
            )
          else ...[
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.75)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attendance Status',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                statusText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (_attendance!.statusCode != null)
                                Text(
                                  'Status code: ${_attendance!.statusCode}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Employee ID',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '#${_attendance!.employeeId ?? employee.employeeId}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Type',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              (_attendance!.employeeType ?? 'employee')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusBadge(label: statusText),
                        if ((_attendance!.requestedStatusDescription ?? '')
                            .trim()
                            .isNotEmpty)
                          _HeroChip(
                            label: _displayStatus(
                              _attendance!.requestedStatusDescription,
                            ),
                          ),
                        _HeroChip(
                          label: _attendance!.employeeType == null
                              ? 'employee'
                              : _attendance!.employeeType!,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: accentSoft,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      _formatDate(_attendance!.date),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _InfoCard(
                  icon: Icons.login,
                  label: 'Check In',
                  value: _attendance!.checkIn,
                  tint: AppColors.emerald500,
                ),
                _InfoCard(
                  icon: Icons.logout,
                  label: 'Check Out',
                  value: _attendance!.checkOut,
                  tint: AppColors.red500,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Leave Type',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _attendance!.leaveTypeDescription ?? '—',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_attendance!.leaveTypeCode != null)
                          Text(
                            'Code: ${_attendance!.leaveTypeCode}',
                            style: const TextStyle(
                              color: AppColors.gray500,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Remarks',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _attendance!.remarks?.isNotEmpty == true
                              ? _attendance!.remarks!
                              : 'No remarks',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_attendance!.requestedStatusDescription != null ||
                _attendance!.requestedLeaveTypeDescription != null ||
                _attendance!.requestedCheckIn != null ||
                _attendance!.requestedCheckOut != null) ...[
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Requested Changes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.amber500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.8,
                      children: [
                        _SimpleField(
                          label: 'Requested Status',
                          value: _attendance!.requestedStatusDescription ?? '—',
                        ),
                        _SimpleField(
                          label: 'Requested Leave Type',
                          value:
                              _attendance!.requestedLeaveTypeDescription ?? '—',
                        ),
                        _SimpleField(
                          label: 'Requested Check In',
                          value: _attendance!.requestedCheckIn ?? '—',
                        ),
                        _SimpleField(
                          label: 'Requested Check Out',
                          value: _attendance!.requestedCheckOut ?? '—',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canView = role == 'admin' || role == 'manager';

    if (!canView) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Access restricted',
        description:
            'Employee attendance details are available to admins and managers only.',
      );
    }

    if (_employeeLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_employeeError != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load employee',
        description: _employeeError!,
      );
    }

    final employee = _employee;
    if (employee == null) {
      return const EmptyState(
        icon: Icons.badge_outlined,
        title: 'Employee not found',
        description: 'We could not load this employee record.',
      );
    }

    final rawStatusText = _attendance?.statusDescription ?? 'Unknown';
    final isPresent = rawStatusText.toLowerCase().contains('present');
    final isAbsent = rawStatusText.toLowerCase().contains('absent');
    final isLate = rawStatusText.toLowerCase().contains('late');
    final isLeave = rawStatusText.toLowerCase().contains('leave');

    Color accent;
    Color accentSoft;
    if (isPresent) {
      accent = AppColors.emerald500;
      accentSoft = _softEmerald;
    } else if (isAbsent) {
      accent = AppColors.red500;
      accentSoft = _softRed;
    } else if (isLate) {
      accent = AppColors.amber500;
      accentSoft = _softAmber;
    } else if (isLeave) {
      accent = AppColors.blue500;
      accentSoft = _softBlue;
    } else {
      accent = AppColors.gray500;
      accentSoft = AppColors.gray50;
    }

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Employee Attendance',
            subtitle: 'Live RazorpayX record and attendance history',
            action: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF0B1220)
                    : AppColors.gray50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 720;
                final summary = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            employee.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        StatusBadge(
                          label: employee.isActive ? 'Active' : 'Inactive',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        employee.title,
                        employee.department,
                      ].where((v) => v.isNotEmpty).join(' · '),
                      style: const TextStyle(color: AppColors.gray500),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _MetaChip(label: 'Email', value: employee.email),
                        _MetaChip(label: 'Phone', value: employee.phoneNumber),
                        _MetaChip(
                          label: 'Employee ID',
                          value: employee.employeeId,
                        ),
                        _MetaChip(
                          label: 'Hired',
                          value: _formatDate(employee.dateOfHiring),
                        ),
                      ],
                    ),
                  ],
                );

                final salaryBlock = Column(
                  crossAxisAlignment: stacked
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Annual CTC',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _formatCurrency(employee.annualCtc),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );

                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppAvatar(
                            initials: initialsFromName(employee.name),
                            size: AppAvatarSize.lg,
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: summary),
                        ],
                      ),
                      const SizedBox(height: 16),
                      salaryBlock,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppAvatar(
                      initials: initialsFromName(employee.name),
                      size: AppAvatarSize.lg,
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: summary),
                    const SizedBox(width: 12),
                    salaryBlock,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildAttendanceTab(
            key: const ValueKey('attendance'),
            employee: employee,
            accent: accent,
            accentSoft: accentSoft,
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0B1220)
            : AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gray500,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DateNavButton extends StatelessWidget {
  const _DateNavButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: icon == Icons.chevron_left ? 'Previous day' : 'Next day',
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0B1220)
            : AppColors.gray50,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tint, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value?.isNotEmpty == true ? value! : '—',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

class _SimpleField extends StatelessWidget {
  const _SimpleField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.gray500,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
