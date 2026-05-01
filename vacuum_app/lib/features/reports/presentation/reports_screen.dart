import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dropdown_field.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/bottom_safe_area.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../../clients/data/clients_repository.dart';
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
              subtitle: state.whenOrNull(
                data: (d) => '${d.items.length} reports',
              ),
              action: canEdit
                  ? AppButton(
                      label: 'New Report',
                      onPressed: () => context.push('/reports/new'),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            state.when(
              loading: () => const _ReportsSkeleton(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load',
                description: e.toString(),
              ),
              data: (data) {
                final counts = <String, int>{
                  for (final s in _reportStatuses)
                    s: data.items.where((r) => r.status == s).length,
                };
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterTabs(
                      value: data.statusFilter,
                      counts: counts,
                      onChanged: (s) =>
                          ref.read(reportsProvider.notifier).setFilter(s),
                    ),
                    const SizedBox(height: 16),
                    if (data.items.isEmpty)
                      const EmptyState(
                        icon: Icons.description_outlined,
                        title: 'No reports found',
                        description:
                            'Create a new report or adjust the filter.',
                      )
                    else
                      Builder(
                        builder: (context) {
                          final width = MediaQuery.sizeOf(context).width;
                          final cols = width >= 720 ? 2 : 1;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
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
                                onApprove: () =>
                                    _setStatus(context, ref, r.id, 'Approved'),
                                onReject: () =>
                                    _setStatus(context, ref, r.id, 'Rejected'),
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

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    String id,
    String status,
  ) async {
    final ok = await ref
        .read(reportsProvider.notifier)
        .updateStatus(id, status);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: ok ? 'Report $status' : 'Operation failed',
      type: ok ? AppToastType.success : AppToastType.error,
    );
  }
}

class ReportCreateScreen extends ConsumerWidget {
  const ReportCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void close() {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        context.go('/reports');
      }
    }

    return _NewReportSheet(
      asSheet: false,
      dio: ref.read(dioProvider),
      onSubmit: (payload, photos, technicalReports) async {
        final id = await ref
            .read(reportsProvider.notifier)
            .createWithUploads(
              payload: payload,
              photos: photos,
              technicalReports: technicalReports,
            );
        if (!context.mounted) return;
        if (id == null || id.isEmpty) {
          AppToast.show(
            context,
            message: 'Failed to create report',
            type: AppToastType.error,
          );
          return;
        }
        if (!context.mounted) return;
        close();
        AppToast.show(
          context,
          message: 'Report submitted!',
          type: AppToastType.success,
        );
      },
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.value,
    required this.counts,
    required this.onChanged,
  });

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: value == t
                        ? (isDark ? AppColors.gray800 : const Color(0xFFDBEAFE))
                        : Colors.transparent,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        t,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: value == t
                              ? (isDark ? Colors.white : AppColors.blue600)
                              : Theme.of(context).hintColor,
                        ),
                      ),
                      if (t != 'All') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${counts[t] ?? 0}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
    final docCount = report.technicalReportCount > 0
        ? report.technicalReportCount
        : report.technicalReports.length;
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
          Text(
            report.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${report.clientName} • ${report.jobTitle}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
          ),
          if ((report.clientEmail ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              report.clientEmail!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
            ),
          ],
          if ((report.poNumber ?? '').trim().isNotEmpty ||
              (report.location ?? '').trim().isNotEmpty ||
              (report.serialNo ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if ((report.poNumber ?? '').trim().isNotEmpty)
                  _Pill(
                    label: 'PO ${report.poNumber!.trim()}',
                    bg: const Color(0xFFF3E8FF),
                    fg: AppColors.purple500,
                  ),
                if ((report.location ?? '').trim().isNotEmpty)
                  _Pill(
                    label: report.location!.trim(),
                    bg: const Color(0xFFD1FAE5),
                    fg: AppColors.emerald500,
                  ),
                if ((report.serialNo ?? '').trim().isNotEmpty)
                  _Pill(
                    label: 'SN ${report.serialNo!.trim()}',
                    bg: const Color(0xFFF3F4F6),
                    fg: AppColors.gray500,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF111827)
                  : AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
              ),
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
                const Icon(
                  Icons.image_outlined,
                  size: 16,
                  color: AppColors.gray400,
                ),
                const SizedBox(width: 6),
                Text(
                  '${report.imageCount > 0 ? report.imageCount : report.images.length} photos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ],
          if (docCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: AppColors.gray400,
                ),
                const SizedBox(width: 6),
                Text(
                  '$docCount docs',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${report.technicianName} • ${_shortDate(report.reportDate) ?? '—'}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
              ),
              if (canApprove) ...[
                IconButton(
                  tooltip: 'Approve',
                  onPressed: onApprove,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.emerald500,
                  ),
                ),
                IconButton(
                  tooltip: 'Reject',
                  onPressed: onReject,
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.red500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
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
  const _NewReportSheet({
    required this.dio,
    required this.onSubmit,
    this.asSheet = true,
  });

  final Dio dio;
  final Future<void> Function(
    Map<String, dynamic> payload,
    List<({String path, String name})> photos,
    List<({String path, String name})> technicalReports,
  )
  onSubmit;
  final bool asSheet;

  @override
  State<_NewReportSheet> createState() => _NewReportSheetState();
}

class _NewReportSheetState extends State<_NewReportSheet> {
  final _picker = ImagePicker();

  final _title = TextEditingController();
  final _poNumber = TextEditingController();
  final _serialNo = TextEditingController();
  final _location = TextEditingController();
  final _clientEmail = TextEditingController();
  final _findings = TextEditingController();
  final _recommendations = TextEditingController();
  final _comments = TextEditingController();

  bool _loading = false;
  bool _fetching = true;

  String? _jobId;
  int? _techId;
  int? _clientId;
  String _clientName = '';

  List<
    ({
      String id,
      String title,
      int? clientId,
      String clientName,
      String clientEmail,
    })
  >
  _jobs = const [];
  List<({int id, String name})> _techs = const [];
  List<({int id, String name, String email})> _clients = const [];

  final List<XFile> _photos = [];
  final List<({String path, String name})> _technicalReports = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdowns();
  }

  @override
  void dispose() {
    _title.dispose();
    _poNumber.dispose();
    _serialNo.dispose();
    _location.dispose();
    _clientEmail.dispose();
    _findings.dispose();
    _recommendations.dispose();
    _comments.dispose();
    super.dispose();
  }

  Future<void> _fetchDropdowns() async {
    setState(() => _fetching = true);
    try {
      final jobsRes = await widget.dio.get(
        'jobs',
        queryParameters: {'limit': 200},
      );
      final jobsRoot = _asMap(jobsRes.data);
      final jobList = _asList(jobsRoot['data']);
      _jobs = jobList
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map((e) {
            final clientId =
                (e['client_id'] as num?)?.toInt() ??
                int.tryParse('${e['client_id'] ?? ''}');
            return (
              id: (e['id'] ?? '').toString(),
              title: (e['title'] ?? '').toString(),
              clientId: clientId,
              clientName: (e['client_name'] ?? '').toString(),
              clientEmail: (e['client_email'] ?? '').toString(),
            );
          })
          .where((e) => e.id.isNotEmpty)
          .toList();

      final techRepo = TechniciansRepository(dio: widget.dio);
      final techs = await techRepo.fetchTechnicians(limit: 100, search: '');
      _techs = [for (final t in techs) (id: t.id, name: t.name)];

      final clientsRepo = ClientsRepository(dio: widget.dio);
      final clients = await clientsRepo.fetchClients(limit: 100);
      _clients = [
        for (final c in clients) (id: c.id, name: c.name, email: c.email),
      ];

      _jobId ??= _jobs.isNotEmpty ? _jobs.first.id : null;
      _techId ??= _techs.isNotEmpty ? _techs.first.id : null;
      if (_jobId != null) _applyJob(_jobId!);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  void _applyJob(String id) {
    final job = _findJob(id);
    if (job == null) return;

    if (job.clientId != null) {
      _clientId = job.clientId;
    }

    if (job.clientName.trim().isNotEmpty) {
      _clientName = job.clientName.trim();
    } else if (_clientId != null) {
      final c = _findClient(_clientId);
      if (c != null) _clientName = c.name;
    }

    final email = job.clientEmail.trim();
    if (email.isNotEmpty) {
      _clientEmail.text = email;
    } else if (_clientId != null) {
      final c = _findClient(_clientId);
      if (c != null && c.email.trim().isNotEmpty) {
        _clientEmail.text = c.email.trim();
      }
    }
  }

  ({
    String id,
    String title,
    int? clientId,
    String clientName,
    String clientEmail,
  })?
  _findJob(String id) {
    for (final j in _jobs) {
      if (j.id == id) return j;
    }
    return null;
  }

  ({int id, String name, String email})? _findClient(int? id) {
    if (id == null) return null;
    for (final c in _clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _pickPhotos() async {
    final imgs = await _picker.pickMultiImage();
    if (imgs.isEmpty) return;
    setState(() => _photos.addAll(imgs));
  }

  Future<void> _camera() async {
    final img = await _picker.pickImage(source: ImageSource.camera);
    if (img == null) return;
    setState(() => _photos.add(img));
  }

  Future<void> _pickTechnicalReports() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
    );
    if (result == null) return;

    final added = <({String path, String name})>[];
    for (final f in result.files) {
      final path = f.path;
      if (path == null || path.isEmpty) continue;
      added.add((path: path, name: f.name));
    }

    if (added.isEmpty) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'File picking is not supported on this platform yet.',
        type: AppToastType.info,
      );
      return;
    }

    setState(() => _technicalReports.addAll(added));
  }

  Future<void> _submit() async {
    if (_loading) return;
    if ((_jobId ?? '').trim().isEmpty ||
        _techId == null ||
        _title.text.trim().isEmpty) {
      AppToast.show(
        context,
        message: 'Job, technician and report title are required.',
        type: AppToastType.error,
      );
      return;
    }

    setState(() => _loading = true);
    final payload = <String, dynamic>{
      'job_id': _jobId,
      'title': _title.text.trim(),
      'technician_id': _techId,
      if (_findings.text.trim().isNotEmpty) 'findings': _findings.text.trim(),
      if (_recommendations.text.trim().isNotEmpty)
        'recommendations': _recommendations.text.trim(),
      if (_comments.text.trim().isNotEmpty) 'comments': _comments.text.trim(),
      if (_poNumber.text.trim().isNotEmpty) 'po_number': _poNumber.text.trim(),
      if (_location.text.trim().isNotEmpty) 'location': _location.text.trim(),
      if (_serialNo.text.trim().isNotEmpty) 'serial_no': _serialNo.text.trim(),
      if (_clientId != null) 'client_id': _clientId,
      if (_clientName.trim().isNotEmpty) 'client_name': _clientName.trim(),
      if (_clientEmail.text.trim().isNotEmpty)
        'client_email': _clientEmail.text.trim(),
    };

    await widget.onSubmit(payload, [
      for (final f in _photos) (path: f.path, name: f.name),
    ], _technicalReports);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    void close() {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        context.go('/reports');
      }
    }

    Widget content(ScrollController? scroll) => SingleChildScrollView(
      controller: scroll,
      padding: EdgeInsets.fromLTRB(
        16,
        widget.asSheet ? 0 : 16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        top: !widget.asSheet,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.asSheet) ...[
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: _loading ? null : close,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    'New Report',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else ...[
              Text(
                'New Report',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
            ],
            if (_fetching)
              const AppCard(child: ShimmerBox(height: 180))
            else ...[
              _dropdownJob(),
              const SizedBox(height: 12),
              _dropdownTech(),
              const SizedBox(height: 12),
              _field('Report Title *', _title, hint: 'Inspection report'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field('PO Number', _poNumber, hint: 'PO-1234'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field('Serial No', _serialNo, hint: 'SR-001'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field('Location', _location, hint: 'Site / building'),
              const SizedBox(height: 16),
              Text(
                'Client Info',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _dropdownClient(),
              const SizedBox(height: 12),
              _field('Client Email', _clientEmail, hint: 'client@example.com'),
              if (_clientEmail.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoBanner(
                  icon: Icons.mail_outline,
                  text:
                      'If a client email is set, a report email will be sent.',
                ),
              ],
              const SizedBox(height: 16),
              _field('Findings', _findings, hint: 'Findings…', lines: 3),
              const SizedBox(height: 12),
              _field(
                'Recommendations',
                _recommendations,
                hint: 'Recommendations…',
                lines: 2,
              ),
              const SizedBox(height: 12),
              _field('Comments', _comments, hint: 'Comments…', lines: 2),
              const SizedBox(height: 16),
              Text('Uploads', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Technical Reports',
                      variant: AppButtonVariant.secondary,
                      leading: const Icon(Icons.upload_file_outlined),
                      onPressed: _loading ? null : _pickTechnicalReports,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Photos',
                      variant: AppButtonVariant.secondary,
                      leading: const Icon(Icons.photo_library_outlined),
                      onPressed: _loading ? null : _pickPhotos,
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
              if (_technicalReports.isNotEmpty) ...[
                AppCard(
                  child: Column(
                    children: [
                      for (int i = 0; i < _technicalReports.length; i++)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.description_outlined,
                            size: 18,
                          ),
                          title: Text(
                            _technicalReports[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: 'Remove',
                            onPressed: _loading
                                ? null
                                : () => setState(
                                    () => _technicalReports.removeAt(i),
                                  ),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_photos.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_photos[i].path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: InkWell(
                          onTap: _loading
                              ? null
                              : () => setState(() => _photos.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                        onPressed: _loading ? null : close,
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
              ),
            ],
          ],
        ),
      ),
    );

    if (!widget.asSheet) return content(null);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => content(scroll),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int lines = 1,
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
          controller: ctrl,
          enabled: !_loading,
          maxLines: lines,
          decoration: InputDecoration(hintText: hint),
          onChanged: label == 'Client Email' ? (_) => setState(() {}) : null,
        ),
      ],
    );
  }

  Widget _dropdownJob() {
    return AppDropdownField<String>(
      label: 'Linked Job *',
      value: _jobId,
      items: [
        for (final j in _jobs)
          AppDropdownItem(value: j.id, label: '${j.id} — ${j.title}'),
      ],
      enabled: !_loading,
      onChanged: (v) => setState(() {
        _jobId = v;
        if (v != null) _applyJob(v);
      }),
    );
  }

  Widget _dropdownTech() {
    return AppDropdownField<int>(
      label: 'Technician *',
      value: _techId,
      items: [
        for (final t in _techs) AppDropdownItem(value: t.id, label: t.name),
      ],
      enabled: !_loading,
      onChanged: (v) => setState(() => _techId = v),
    );
  }

  Widget _dropdownClient() {
    return AppDropdownField<int>(
      label: 'Client',
      value: _clientId,
      allowNull: true,
      nullLabel: '— Please select —',
      items: [
        for (final c in _clients) AppDropdownItem(value: c.id, label: c.name),
      ],
      enabled: !_loading,
      onChanged: (v) {
        final selected = _findClient(v);
        setState(() {
          _clientId = v;
          _clientName = selected?.name ?? _clientName;
          if (selected != null && selected.email.trim().isNotEmpty) {
            _clientEmail.text = selected.email.trim();
          }
        });
      },
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue600, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.blue600,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
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
