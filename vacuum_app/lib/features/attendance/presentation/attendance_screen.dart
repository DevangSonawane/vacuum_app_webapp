import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/bottom_safe_area.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../../technicians/data/technicians_repository.dart';

class AttendanceEntry {
  const AttendanceEntry({
    required this.id,
    required this.technicianId,
    required this.technicianName,
    required this.specialization,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.hours,
  });

  final int id;
  final int technicianId;
  final String technicianName;
  final String specialization;
  final String date; // YYYY-MM-DD
  final String? checkIn;
  final String? checkOut;
  final String status; // Present | Late | Absent
  final num hours;
}

class AttendanceState {
  const AttendanceState({required this.items, required this.date});

  final List<AttendanceEntry> items;
  final DateTime date;

  AttendanceState copyWith({List<AttendanceEntry>? items, DateTime? date}) =>
      AttendanceState(items: items ?? this.items, date: date ?? this.date);
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>(
      (ref) => AttendanceNotifier(ref),
    );

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier(this.ref)
    : super(AttendanceState(date: DateTime.now(), items: _seed));

  final Ref ref;
  bool _apiUnavailable = false;

  static final List<AttendanceEntry> _seed = [
    const AttendanceEntry(
      id: 1,
      technicianId: 1,
      technicianName: 'Ravi Kumar',
      specialization: 'HVAC',
      date: '2024-01-15',
      checkIn: '08:55',
      checkOut: '17:30',
      status: 'Present',
      hours: 8.6,
    ),
    const AttendanceEntry(
      id: 2,
      technicianId: 2,
      technicianName: 'Suresh Patel',
      specialization: 'Electrical',
      date: '2024-01-15',
      checkIn: '09:10',
      checkOut: '17:45',
      status: 'Present',
      hours: 8.6,
    ),
    const AttendanceEntry(
      id: 3,
      technicianId: 3,
      technicianName: 'Deepak Singh',
      specialization: 'Plumbing',
      date: '2024-01-15',
      checkIn: null,
      checkOut: null,
      status: 'Absent',
      hours: 0,
    ),
    const AttendanceEntry(
      id: 4,
      technicianId: 4,
      technicianName: 'Anil Verma',
      specialization: 'Carpentry',
      date: '2024-01-15',
      checkIn: '08:30',
      checkOut: '17:00',
      status: 'Present',
      hours: 8.5,
    ),
    const AttendanceEntry(
      id: 6,
      technicianId: 2,
      technicianName: 'Suresh Patel',
      specialization: 'Electrical',
      date: '2024-01-14',
      checkIn: '09:30',
      checkOut: '17:30',
      status: 'Late',
      hours: 8.0,
    ),
  ];

  Future<void> setDate(DateTime date) async {
    state = state.copyWith(date: date);
    await refresh();
  }

  Future<void> refresh() async {
    if (_apiUnavailable) return;
    final dio = ref.read(dioProvider);
    final date = _fmtDate(state.date);
    try {
      final res = await dio.get('attendance', queryParameters: {'date': date});
      final root = _asMap(res.data);
      final list = _asList(root['data']);
      final items = list
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map(
            (e) => AttendanceEntry(
              id: (e['id'] as num?)?.toInt() ?? 0,
              technicianId: (e['technician_id'] as num?)?.toInt() ?? 0,
              technicianName: (e['technician_name'] ?? '').toString(),
              specialization: (e['specialization'] ?? '').toString(),
              date: (e['date'] ?? date).toString(),
              checkIn: (e['check_in'] as Object?)?.toString(),
              checkOut: (e['check_out'] as Object?)?.toString(),
              status: (e['status'] ?? '').toString(),
              hours: (e['hours'] as num?) ?? 0,
            ),
          )
          .toList();
      state = state.copyWith(items: items);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) _apiUnavailable = true;
    } catch (_) {
      // ignore
    }
  }

  void addLocal(AttendanceEntry entry) {
    state = state.copyWith(items: [entry, ...state.items]);
  }

  static String _fmtDate(DateTime d) => d.toIso8601String().substring(0, 10);

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canEdit = !['technician', 'labour'].contains(role);

    final state = ref.watch(attendanceProvider);
    final dateKey = state.date.toIso8601String().substring(0, 10);
    final rows = state.items.where((e) => e.date == dateKey).toList();

    final present = rows.where((e) => e.status == 'Present').length;
    final late = rows.where((e) => e.status == 'Late').length;
    final absent = rows.where((e) => e.status == 'Absent').length;
    final total = rows.map((e) => e.technicianId).toSet().length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Attendance Tracking',
            subtitle: 'Daily check-in / check-out records',
            action: canEdit
                ? AppButton(
                    label: 'Mark Attendance',
                    variant: AppButtonVariant.outline,
                    onPressed: () => _openMarkSheet(context, ref),
                  )
                : null,
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
                      initialDate: state.date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                                initials: initialsFromName(r.technicianName),
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
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        DataCell(
                          Text(
                            r.checkOut ?? '—',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        DataCell(
                          Text(
                            r.hours.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
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
  }

  Future<void> _openMarkSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => _MarkAttendanceSheet(
        dio: ref.read(dioProvider),
        onSubmit: (entry) {
          ref.read(attendanceProvider.notifier).addLocal(entry);
          Navigator.of(ctx).pop();
          AppToast.show(
            context,
            message: 'Attendance marked',
            type: AppToastType.success,
          );
        },
      ),
    );
  }
}

class _MarkAttendanceSheet extends StatefulWidget {
  const _MarkAttendanceSheet({required this.dio, required this.onSubmit});

  final Dio dio;
  final void Function(AttendanceEntry entry) onSubmit;

  @override
  State<_MarkAttendanceSheet> createState() => _MarkAttendanceSheetState();
}

class _MarkAttendanceSheetState extends State<_MarkAttendanceSheet> {
  bool _fetching = true;
  bool _loading = false;

  List<({int id, String name, String spec})> _techs = const [];
  int? _techId;
  String _status = 'Present';

  final _checkIn = TextEditingController();
  final _checkOut = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_loadTechs());
  }

  @override
  void dispose() {
    _checkIn.dispose();
    _checkOut.dispose();
    super.dispose();
  }

  Future<void> _loadTechs() async {
    setState(() => _fetching = true);
    try {
      final repo = TechniciansRepository(dio: widget.dio);
      final techs = await repo.fetchTechnicians(search: '');
      _techs = [
        for (final t in techs) (id: t.id, name: t.name, spec: t.specialization),
      ];
      if (_techs.isNotEmpty) _techId = _techs.first.id;
    } catch (_) {
      _techs = const [];
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  num _hours(String? inTime, String? outTime) {
    if (inTime == null || outTime == null) return 0;
    try {
      final inParts = inTime.split(':').map(int.parse).toList();
      final outParts = outTime.split(':').map(int.parse).toList();
      final start = Duration(hours: inParts[0], minutes: inParts[1]);
      final end = Duration(hours: outParts[0], minutes: outParts[1]);
      final diff = end - start;
      return diff.inMinutes / 60.0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (_techId == null) {
      AppToast.show(
        context,
        message: 'Select a technician',
        type: AppToastType.error,
      );
      return;
    }
    setState(() => _loading = true);
    final tech = _techs.firstWhere((t) => t.id == _techId);
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final hours = _hours(
      _checkIn.text.trim().isEmpty ? null : _checkIn.text.trim(),
      _checkOut.text.trim().isEmpty ? null : _checkOut.text.trim(),
    );
    widget.onSubmit(
      AttendanceEntry(
        id: DateTime.now().millisecondsSinceEpoch,
        technicianId: tech.id,
        technicianName: tech.name,
        specialization: tech.spec,
        date: date,
        checkIn: _checkIn.text.trim().isEmpty ? null : _checkIn.text.trim(),
        checkOut: _checkOut.text.trim().isEmpty ? null : _checkOut.text.trim(),
        status: _status,
        hours: hours,
      ),
    );
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.55,
      maxChildSize: 0.9,
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
            const SizedBox(height: 16),
            if (_fetching)
              const AppCard(child: ShimmerBox(height: 100))
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
                    : (v) => setState(() => _status = v ?? 'Present'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field('Check In', _checkIn, hint: '09:00')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field('Check Out', _checkOut, hint: '18:00'),
                  ),
                ],
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

  Widget _field(String label, TextEditingController ctrl, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          enabled: !_loading,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
