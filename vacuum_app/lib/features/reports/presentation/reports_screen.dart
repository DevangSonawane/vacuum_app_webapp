import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../../technicians/data/technicians_repository.dart';
import '../application/reports_notifier.dart';
import '../domain/report.dart';

const _reportStatuses = ['Pending', 'Approved', 'Rejected'];

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canEdit = !['technician', 'labour'].contains(role);
    final canApprove = role == 'admin';

    final state = ref.watch(reportsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(reportsProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Inspection & Service Reports',
              subtitle: state.whenOrNull(data: (d) => '${d.items.length} reports'),
              action: canEdit
                  ? AppButton(
                      label: 'New Report',
                      onPressed: () => _openNewReportSheet(context, ref),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            state.when(
              loading: () => const _ReportsSkeleton(),
              error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Failed to load', description: e.toString()),
              data: (data) {
                final counts = <String, int>{
                  for (final s in _reportStatuses) s: data.items.where((r) => r.status == s).length,
                };
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterTabs(
                      value: data.statusFilter,
                      counts: counts,
                      onChanged: (s) => ref.read(reportsProvider.notifier).setFilter(s),
                    ),
                    const SizedBox(height: 16),
                    if (data.items.isEmpty)
                      const EmptyState(
                        icon: Icons.description_outlined,
                        title: 'No reports found',
                        description: 'Create a new report or adjust the filter.',
                      )
                    else
                      Builder(
                        builder: (context) {
                          final width = MediaQuery.sizeOf(context).width;
                          final cols = width >= 720 ? 2 : 1;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: cols == 1 ? 1.55 : 1.35,
                            ),
                            itemCount: data.items.length,
                            itemBuilder: (context, i) {
                              final r = data.items[i];
                              return _ReportCard(
                                report: r,
                                canApprove: canApprove && r.status == 'Pending',
                                onTap: () => context.go('/reports/${r.id}'),
                                onApprove: () => _setStatus(context, ref, r.id, 'Approved'),
                                onReject: () => _setStatus(context, ref, r.id, 'Rejected'),
                              );
                            },
                          );
                        },
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

  Future<void> _setStatus(BuildContext context, WidgetRef ref, String id, String status) async {
    final ok = await ref.read(reportsProvider.notifier).updateStatus(id, status);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: ok ? 'Report $status' : 'Operation failed',
      type: ok ? AppToastType.success : AppToastType.error,
    );
  }

  Future<void> _openNewReportSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => _NewReportSheet(
        dio: ref.read(dioProvider),
        onSubmit: (payload, files) async {
          final id = await ref.read(reportsProvider.notifier).create(payload);
          if (!context.mounted) return;
          if (id == null || id.isEmpty) {
            AppToast.show(context, message: 'Failed to create report', type: AppToastType.error);
            return;
          }
          if (files.isNotEmpty) {
            await ref.read(reportsProvider.notifier).uploadAndLinkImages(id, files);
          }
          if (!context.mounted) return;
          Navigator.of(ctx).pop();
          AppToast.show(context, message: 'Report submitted!', type: AppToastType.success);
        },
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.value, required this.counts, required this.onChanged});

  final String value;
  final Map<String, int> counts;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = ['All', ..._reportStatuses];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final t in tabs)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onChanged(t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: value == t ? (isDark ? AppColors.gray800 : const Color(0xFFDBEAFE)) : Colors.transparent,
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.16)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        t,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: value == t ? (isDark ? Colors.white : AppColors.blue600) : Theme.of(context).hintColor,
                        ),
                      ),
                      if (t != 'All') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('${counts[t] ?? 0}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.canApprove,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  final Report report;
  final bool canApprove;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final findingsPreview = report.findings.replaceAll('\n', ' ').trim();
    return AppCard(
      hover: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                report.id,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  color: AppColors.blue600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              StatusBadge(label: report.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(report.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '${report.clientName} • ${report.jobTitle}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.12)),
            ),
            child: Text(
              findingsPreview.isEmpty ? 'No findings' : findingsPreview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (report.imageCount > 0 || report.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.image_outlined, size: 16, color: AppColors.gray400),
                const SizedBox(width: 6),
                Text('${report.imageCount > 0 ? report.imageCount : report.images.length} photos', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${report.technicianName} • ${_shortDate(report.reportDate) ?? '—'}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                ),
              ),
              if (canApprove) ...[
                IconButton(
                  tooltip: 'Approve',
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_outline, color: AppColors.emerald500),
                ),
                IconButton(
                  tooltip: 'Reject',
                  onPressed: onReject,
                  icon: const Icon(Icons.cancel_outlined, color: AppColors.red500),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

String? _shortDate(String? iso) {
  if (iso == null) return null;
  final v = iso.trim();
  if (v.isEmpty) return null;
  return v.length >= 10 ? v.substring(0, 10) : v;
}

class _NewReportSheet extends StatefulWidget {
  const _NewReportSheet({required this.dio, required this.onSubmit});

  final Dio dio;
  final Future<void> Function(Map<String, dynamic> payload, List<({String path, String name})> files) onSubmit;

  @override
  State<_NewReportSheet> createState() => _NewReportSheetState();
}

class _NewReportSheetState extends State<_NewReportSheet> {
  final _picker = ImagePicker();

  final _title = TextEditingController();
  final _findings = TextEditingController();
  final _recommendations = TextEditingController();

  bool _loading = false;
  bool _fetching = true;

  String? _jobId;
  int? _techId;

  List<({String id, String title})> _jobs = const [];
  List<({int id, String name})> _techs = const [];
  final List<XFile> _files = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdowns();
  }

  @override
  void dispose() {
    _title.dispose();
    _findings.dispose();
    _recommendations.dispose();
    super.dispose();
  }

  Future<void> _fetchDropdowns() async {
    setState(() => _fetching = true);
    try {
      final jobsRes = await widget.dio.get('/jobs', queryParameters: {'limit': 100});
      final jobsRoot = _asMap(jobsRes.data);
      final jobList = _asList(jobsRoot['data']);
      _jobs = jobList
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map((e) => (id: (e['id'] ?? '').toString(), title: (e['title'] ?? '').toString()))
          .where((e) => e.id.isNotEmpty)
          .toList();

      final techRepo = TechniciansRepository(dio: widget.dio);
      final techs = await techRepo.fetchTechnicians(search: '');
      _techs = [for (final t in techs) (id: t.id, name: t.name)];

      _jobId ??= _jobs.isNotEmpty ? _jobs.first.id : null;
      _techId ??= _techs.isNotEmpty ? _techs.first.id : null;
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _pick() async {
    final imgs = await _picker.pickMultiImage();
    if (imgs.isEmpty) return;
    setState(() => _files.addAll(imgs));
  }

  Future<void> _camera() async {
    final img = await _picker.pickImage(source: ImageSource.camera);
    if (img == null) return;
    setState(() => _files.add(img));
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (_jobId == null || _jobId!.isEmpty || _techId == null || _title.text.trim().isEmpty) {
      AppToast.show(context, message: 'Job, technician and title are required.', type: AppToastType.error);
      return;
    }

    setState(() => _loading = true);
    final payload = <String, dynamic>{
      'job_id': _jobId,
      'title': _title.text.trim(),
      'technician_id': _techId,
      'findings': _findings.text.trim(),
      'recommendations': _recommendations.text.trim(),
    };
    await widget.onSubmit(payload, [for (final f in _files) (path: f.path, name: f.name)]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Report', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (_fetching)
              const AppCard(child: ShimmerBox(height: 140))
            else ...[
              _dropdownJob(),
              const SizedBox(height: 12),
              _dropdownTech(),
              const SizedBox(height: 12),
              _field('Report Title *', _title, hint: 'Inspection report'),
              const SizedBox(height: 12),
              _field('Findings', _findings, hint: 'Findings…', lines: 3),
              const SizedBox(height: 12),
              _field('Recommendations', _recommendations, hint: 'Recommendations…', lines: 2),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Attach Photos',
                      variant: AppButtonVariant.secondary,
                      leading: const Icon(Icons.photo_library_outlined),
                      onPressed: _loading ? null : _pick,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: '',
                    variant: AppButtonVariant.secondary,
                    leading: const Icon(Icons.camera_alt_outlined),
                    onPressed: _loading ? null : _camera,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_files.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _files.length,
                  itemBuilder: (context, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_files[i].path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: InkWell(
                          onTap: _loading ? null : () => setState(() => _files.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      expanded: true,
                      onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Submit Report',
                      expanded: true,
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, int lines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          enabled: !_loading,
          maxLines: lines,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _dropdownJob() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Linked Job *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _jobId,
          decoration: const InputDecoration(isDense: true),
          items: _jobs
              .map((j) => DropdownMenuItem<String>(
                    value: j.id,
                    child: Text('${j.id} — ${j.title}', overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: _loading ? null : (v) => setState(() => _jobId = v),
        ),
      ],
    );
  }

  Widget _dropdownTech() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Technician *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: _techId,
          decoration: const InputDecoration(isDense: true),
          items: _techs.map((t) => DropdownMenuItem<int>(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: _loading ? null : (v) => setState(() => _techId = v),
        ),
      ],
    );
  }
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic v) => v is List ? v : const [];

class _ReportsSkeleton extends StatelessWidget {
  const _ReportsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: ShimmerBox(height: 36, borderRadius: 999)),
            SizedBox(width: 8),
            Expanded(child: ShimmerBox(height: 36, borderRadius: 999)),
          ],
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < 6; i++) ...[
          const AppCard(child: ShimmerBox(height: 160)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
