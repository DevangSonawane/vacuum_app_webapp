import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/bottom_safe_area.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../../technicians/data/technicians_repository.dart';
import '../application/attendance_notifier.dart';

final _apiDateFmt = DateFormat('yyyy-MM-dd');
String _fmtDate(DateTime d) => _apiDateFmt.format(d);

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canEdit = !['technician', 'labour'].contains(role);

    final state = ref.watch(attendanceProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load',
        description: e.toString(),
      ),
      data: (data) {
        final rows = data.items;
        final present = rows.where((e) => e.status == 'Present').length;
        final late = rows.where((e) => e.status == 'Late').length;
        final absent = rows.where((e) => e.status == 'Absent').length;
        final total = rows.map((e) => e.technicianId).toSet().length;
        final dateKey = _fmtDate(data.date);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Attendance Tracking',
                subtitle: 'Daily check-in / check-out records',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: () =>
                          ref.read(attendanceProvider.notifier).refresh(),
                      icon: const Icon(Icons.refresh),
                    ),
                    if (canEdit)
                      AppButton(
                        label: 'Mark Attendance',
                        variant: AppButtonVariant.outline,
                        onPressed: () => _openMarkSheet(context, dateKey),
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
                childAspectRatio: 1.9,
                children: [
                  StatCard(title: 'Present', value: '$present'),
                  StatCard(title: 'Late', value: '$late'),
                  StatCard(title: 'Absent', value: '$absent'),
                  StatCard(title: 'Total', value: '$total'),
                ],
              ),
              const SizedBox(height: 16),
              _WeeklyOverview(week: data.week),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Date:',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: data.date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          await ref
                              .read(attendanceProvider.notifier)
                              .setDate(picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.16),
                          ),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF0B1220)
                              : AppColors.gray50,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: AppColors.gray400,
                            ),
                            const SizedBox(width: 8),
                            Text(dateKey),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (rows.isEmpty)
                const EmptyState(
                  icon: Icons.calendar_today_outlined,
                  title: 'No attendance',
                  description: 'No records found for the selected date.',
                )
              else
                AppCard(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Technician')),
                        DataColumn(label: Text('Specialization')),
                        DataColumn(label: Text('Check In')),
                        DataColumn(label: Text('Check Out')),
                        DataColumn(label: Text('Hours')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: [
                        for (final r in rows)
                          DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    AppAvatar(
                                      initials: initialsFromName(
                                        r.technicianName,
                                      ),
                                      size: AppAvatarSize.sm,
                                    ),
                                    const SizedBox(width: 10),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 160,
                                      ),
                                      child: Text(
                                        r.technicianName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  r.specialization,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DataCell(
                                Text(
                                  r.checkIn ?? '—',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  r.checkOut ?? '—',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  r.hours.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              DataCell(StatusBadge(label: r.status)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openMarkSheet(BuildContext context, String date) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _MarkAttendanceSheet(date: date),
    );
  }
}

class _WeeklyOverview extends StatelessWidget {
  const _WeeklyOverview({required this.week});

  final List<AttendanceDaySummary> week;

  @override
  Widget build(BuildContext context) {
    if (week.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 7 days', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final d in week)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      width: 132,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF111827)
                            : AppColors.gray50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.date.substring(5),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: AppColors.gray500,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${d.present}/${d.total} present',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${d.late} late • ${d.absent} absent',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
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

class _MarkAttendanceSheet extends ConsumerStatefulWidget {
  const _MarkAttendanceSheet({required this.date});

  final String date; // YYYY-MM-DD

  @override
  ConsumerState<_MarkAttendanceSheet> createState() =>
      _MarkAttendanceSheetState();
}

class _MarkAttendanceSheetState extends ConsumerState<_MarkAttendanceSheet> {
  bool _fetching = true;
  bool _loading = false;

  List<({int id, String name, String spec})> _techs = const [];
  int? _techId;
  String _status = 'Present';

  final _checkIn = TextEditingController();
  final _checkOut = TextEditingController();
  final _hours = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_loadTechs());
  }

  @override
  void dispose() {
    _checkIn.dispose();
    _checkOut.dispose();
    _hours.dispose();
    super.dispose();
  }

  Future<void> _loadTechs() async {
    setState(() => _fetching = true);
    try {
      final repo = TechniciansRepository(dio: ref.read(dioProvider));
      final list = await repo.fetchTechnicians(search: '');
      _techs = [
        for (final t in list) (id: t.id, name: t.name, spec: t.specialization),
      ];
      _techId ??= _techs.isNotEmpty ? _techs.first.id : null;
    } catch (_) {
      _techs = const [];
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;
    ctrl.text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    _recalcHours();
    setState(() {});
  }

  void _recalcHours() {
    if (_status == 'Absent') {
      _hours.text = '0';
      return;
    }

    final inText = _checkIn.text.trim();
    final outText = _checkOut.text.trim();
    if (inText.isEmpty || outText.isEmpty) return;

    final inParts = inText.split(':');
    final outParts = outText.split(':');
    if (inParts.length != 2 || outParts.length != 2) return;

    final inH = int.tryParse(inParts[0]);
    final inM = int.tryParse(inParts[1]);
    final outH = int.tryParse(outParts[0]);
    final outM = int.tryParse(outParts[1]);
    if (inH == null || inM == null || outH == null || outM == null) return;

    final start = Duration(hours: inH, minutes: inM);
    final end = Duration(hours: outH, minutes: outM);
    var diff = end - start;
    if (diff.isNegative) diff += const Duration(days: 1);
    _hours.text = (diff.inMinutes / 60.0).toStringAsFixed(1);
  }

  Future<void> _submit() async {
    if (_loading) return;
    final techId = _techId;
    if (techId == null) {
      AppToast.show(
        context,
        message: 'Select a technician.',
        type: AppToastType.error,
      );
      return;
    }

    if (_status != 'Absent') {
      if (_checkIn.text.trim().isEmpty || _checkOut.text.trim().isEmpty) {
        AppToast.show(
          context,
          message: 'Check in and check out are required.',
          type: AppToastType.error,
        );
        return;
      }
    }

    final hoursNum =
        num.tryParse(_hours.text.trim()) ?? (_status == 'Absent' ? 0 : null);
    if (hoursNum == null) {
      AppToast.show(
        context,
        message: 'Enter valid hours.',
        type: AppToastType.error,
      );
      return;
    }

    setState(() => _loading = true);

    final payload = <String, dynamic>{
      'technician_id': techId,
      'date': widget.date,
      'status': _status,
      if (_status != 'Absent' && _checkIn.text.trim().isNotEmpty)
        'check_in': _checkIn.text.trim(),
      if (_status != 'Absent' && _checkOut.text.trim().isNotEmpty)
        'check_out': _checkOut.text.trim(),
      'hours': _status == 'Absent' ? 0 : hoursNum,
    };

    final ok = await ref
        .read(attendanceProvider.notifier)
        .markAttendance(payload);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pop();
      AppToast.show(
        context,
        message: 'Attendance marked',
        type: AppToastType.success,
      );
    } else {
      AppToast.show(
        context,
        message: 'Operation failed',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize: 0.55,
      maxChildSize: 0.92,
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
              'Mark Attendance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              widget.date,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 16),
            if (_fetching)
              const AppCard(child: ShimmerBox(height: 100))
            else if (_techs.isEmpty)
              const EmptyState(
                icon: Icons.engineering_outlined,
                title: 'No technicians',
                description: 'Add a technician before marking attendance.',
              )
            else ...[
              const Text(
                'Technician',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: _techId,
                isExpanded: true,
                menuMaxHeight: 360,
                borderRadius: BorderRadius.circular(14),
                dropdownColor: Theme.of(context).colorScheme.surface,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                decoration: const InputDecoration(isDense: true),
                items: _techs
                    .map(
                      (t) => DropdownMenuItem<int>(
                        value: t.id,
                        child: Text(t.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: _loading ? null : (v) => setState(() => _techId = v),
              ),
              const SizedBox(height: 12),
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _status,
                isExpanded: true,
                menuMaxHeight: 360,
                borderRadius: BorderRadius.circular(14),
                dropdownColor: Theme.of(context).colorScheme.surface,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: 'Present', child: Text('Present')),
                  DropdownMenuItem(value: 'Late', child: Text('Late')),
                  DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                ],
                onChanged: _loading
                    ? null
                    : (v) {
                        setState(() => _status = v ?? 'Present');
                        if (_status == 'Absent') {
                          _checkIn.clear();
                          _checkOut.clear();
                          _hours.text = '0';
                        }
                      },
              ),
              if (_status != 'Absent') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _timeField(
                        label: 'Check In',
                        controller: _checkIn,
                        hint: '09:00',
                        onTap: _loading ? null : () => _pickTime(_checkIn),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _timeField(
                        label: 'Check Out',
                        controller: _checkOut,
                        hint: '17:00',
                        onTap: _loading ? null : () => _pickTime(_checkOut),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _numberField(
                  label: 'Hours',
                  controller: _hours,
                  hint: '8.0',
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
                        label: 'Submit',
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

  Widget _timeField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: const Icon(Icons.access_time, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
