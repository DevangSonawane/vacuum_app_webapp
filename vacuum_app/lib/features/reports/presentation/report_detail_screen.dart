import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/reports_notifier.dart';
import '../domain/report.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  const ReportDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  AsyncValue<Report?> _report = const AsyncLoading();
  bool _downloadingPdf = false;
  bool _updatingStatus = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _report = const AsyncLoading());
    final r = await ref.read(reportsProvider.notifier).fetchDetail(widget.id);
    if (!mounted) return;
    setState(() => _report = AsyncData(r));
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canApprove = role == 'admin';
    final report = _report.valueOrNull;
    final showBottomActions = canApprove && report?.status == 'Pending';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id, style: const TextStyle(fontFamily: 'monospace')),
        leading: BackButton(
          onPressed: () => context.go('/reports'),
        ),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: _downloadingPdf ? null : _downloadPdf,
            icon: _downloadingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
          ),
        ],
      ),
      bottomNavigationBar: showBottomActions
          ? SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.12),
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Approve',
                        variant: AppButtonVariant.primary,
                        expanded: true,
                        loading: _updatingStatus,
                        onPressed: _updatingStatus
                            ? null
                            : () => _updateStatus('Approved'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Reject',
                        variant: AppButtonVariant.danger,
                        expanded: true,
                        loading: _updatingStatus,
                        onPressed: _updatingStatus
                            ? null
                            : () => _updateStatus('Rejected'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: _report.when(
        loading: () => const _ReportDetailSkeleton(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load',
          description: e.toString(),
        ),
        data: (report) {
          if (report == null) {
            return const EmptyState(
              icon: Icons.description_outlined,
              title: 'Not found',
              description: 'Report not available.',
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + (showBottomActions ? 92 : 0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF334155), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.id,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          color: AppColors.blue200,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      StatusBadge(label: report.status),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _InfoGrid(report: report),
                const SizedBox(height: 16),
                Text(
                  'Findings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                AppCard(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF111827)
                          : AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      report.findings.isEmpty ? '—' : report.findings,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Recommendations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                AppCard(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Text(
                      report.recommendations.isEmpty
                          ? '—'
                          : report.recommendations,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                AppCard(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF111827)
                          : AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      (report.comments ?? '').trim().isEmpty
                          ? '—'
                          : report.comments!.trim(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (report.checklistItems.isNotEmpty) ...[
                  Text(
                    'Checklist (${report.checklistItems.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      children: [
                        for (final item in report.checklistItems) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF111827)
                                  : AppColors.gray50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDBEAFE),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${item.sr}',
                                    style: const TextStyle(
                                      color: AppColors.blue600,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.description.isEmpty
                                        ? '—'
                                        : item.description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.status.trim().isEmpty
                                      ? '—'
                                      : item.status.trim(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: item.status.trim().isEmpty
                                        ? Theme.of(context).hintColor
                                        : AppColors.emerald500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (report.issueObservations.isNotEmpty) ...[
                  Text(
                    'Issues (${report.issueObservations.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('SR')),
                          DataColumn(label: Text('Issue')),
                          DataColumn(label: Text('Observation')),
                          DataColumn(label: Text('Impact')),
                          DataColumn(label: Text('Severity')),
                          DataColumn(label: Text('Recommended Spares')),
                        ],
                        rows: [
                          for (final obs in report.issueObservations)
                            DataRow(
                              cells: [
                                DataCell(
                                  Text(obs.sr == 0 ? '—' : '${obs.sr}'),
                                ),
                                DataCell(Text(obs.issue.isEmpty ? '—' : obs.issue)),
                                DataCell(Text(obs.observation.isEmpty ? '—' : obs.observation)),
                                DataCell(Text(obs.impactOnPump.isEmpty ? '—' : obs.impactOnPump)),
                                DataCell(Text(obs.severity.isEmpty ? '—' : obs.severity)),
                                DataCell(Text(obs.recommendedSpares.isEmpty ? '—' : obs.recommendedSpares)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if ((report.remarks ?? '').trim().isNotEmpty) ...[
                  Text(
                    'Remarks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF111827)
                            : AppColors.gray50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text((report.remarks ?? '').trim()),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (report.mandatorySpares.isNotEmpty) ...[
                  Text(
                    'Mandatory Spares (${report.mandatorySpares.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Spare Name')),
                          DataColumn(label: Text('Pump Model')),
                          DataColumn(label: Text('Total To Order')),
                        ],
                        rows: [
                          for (final s in report.mandatorySpares)
                            DataRow(
                              cells: [
                                DataCell(Text(s.spareName.isEmpty ? '—' : s.spareName)),
                                DataCell(Text(s.pumpModel.isEmpty ? '—' : s.pumpModel)),
                                DataCell(Text(s.totalToOrder.isEmpty ? '—' : s.totalToOrder)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if ((report.vdtRepresentativeName ?? '').trim().isNotEmpty ||
                    (report.clientRepresentativeName ?? '').trim().isNotEmpty) ...[
                  Text(
                    'Signatures',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppCard(
                          child: _signatureCard(
                            title: 'VDT Representative',
                            name: (report.vdtRepresentativeName ?? '').trim(),
                            date: report.reportDate,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppCard(
                          child: _signatureCard(
                            title: 'Client Representative',
                            name:
                                (report.clientRepresentativeName ?? '').trim(),
                            date: report.reportDate,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Report Copies (${report.technicalReports.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (report.technicalReports.isEmpty)
                  Text(
                    'No documents',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: report.technicalReports.length,
                      separatorBuilder: (context, i) => Divider(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.12),
                        height: 1,
                      ),
                      itemBuilder: (context, i) {
                        final f = report.technicalReports[i];
                        final size = _fmtBytes(f.fileSizeBytes);
                        return ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(
                            f.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: size == null ? null : Text(size),
                          trailing: const Icon(Icons.open_in_new, size: 18),
                          onTap: () => _openUrl(context, f.fileUrl),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Attached Photos (${report.images.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (report.images.isEmpty)
                  Text(
                    'No photos',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: report.images.length,
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: report.images[i].fileUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const ShimmerBox(height: 80),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (report.status == 'Approved')
                  _Banner(
                    bg: const Color(0xFFD1FAE5),
                    border: const Color(0xFFA7F3D0),
                    icon: Icons.check_circle,
                    iconColor: AppColors.emerald500,
                    text: 'Approved',
                    textColor: const Color(0xFF065F46),
                  )
                else if (report.status == 'Rejected')
                  _Banner(
                    bg: const Color(0xFFFEF2F2),
                    border: const Color(0xFFFEE2E2),
                    icon: Icons.cancel,
                    iconColor: AppColors.red500,
                    text: 'Rejected',
                    textColor: AppColors.red500,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _updatingStatus = true);
    try {
      final r = _report.valueOrNull;
      final id = r?.id ?? widget.id;
      final ok =
          await ref.read(reportsProvider.notifier).updateStatus(id, status);
      if (!mounted) return;
      AppToast.show(
        context,
        message: ok ? (status == 'Approved' ? 'Approved' : 'Rejected') : 'Operation failed',
        type: ok ? AppToastType.success : AppToastType.error,
      );
      await _load();
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _downloadingPdf = true);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Service_Report_${widget.id}.pdf');
      final download = await ref
          .read(reportsProvider.notifier)
          .downloadPdfWithType(widget.id, file.path);
      if (!mounted) return;
      if (download == null) {
        AppToast.show(
          context,
          message: 'Failed to download PDF',
          type: AppToastType.error,
        );
        return;
      }

      final openResult = await OpenFile.open(
        download.path,
        type: download.mimeType,
      );
      if (!mounted) return;

      if (openResult.type != ResultType.done) {
        AppToast.show(
          context,
          message: 'Saved file to ${download.path}',
          type: AppToastType.success,
        );
      } else {
        if (download.mimeType == 'text/html') {
          AppToast.show(
            context,
            message:
                'Server returned HTML fallback. Use Print/Save as PDF to download.',
            type: AppToastType.info,
          );
        } else {
          AppToast.show(
            context,
            message: 'Report download started',
            type: AppToastType.success,
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Failed to download PDF',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  Widget _signatureCard({
    required String title,
    required String name,
    required String? date,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).hintColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name.isEmpty ? '—' : name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Date: ${_shortDate(date)}',
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.report});
  final Report report;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 600 ? 2 : 1;
    final items = <({String label, String value, IconData icon})>[
      (label: 'Job', value: report.jobId, icon: Icons.work_outline),
      (label: 'Job Title', value: report.jobTitle, icon: Icons.title),
      (label: 'Client', value: report.clientName, icon: Icons.groups_outlined),
      (
        label: 'Company',
        value: (report.companyName ?? '').trim().isEmpty
            ? '—'
            : report.companyName!.trim(),
        icon: Icons.business_outlined,
      ),
      (
        label: 'Contact',
        value: (report.contactPerson ?? '').trim().isEmpty
            ? '—'
            : report.contactPerson!.trim(),
        icon: Icons.person_outline,
      ),
      (
        label: 'Client Email',
        value: (report.clientEmail ?? '').trim().isEmpty
            ? '—'
            : report.clientEmail!.trim(),
        icon: Icons.mail_outline,
      ),
      (
        label: 'Technician',
        value: report.technicianName,
        icon: Icons.engineering_outlined,
      ),
      (
        label: 'PO Number',
        value: (report.poNumber ?? '').trim().isEmpty
            ? '—'
            : report.poNumber!.trim(),
        icon: Icons.receipt_long_outlined,
      ),
      (
        label: 'Model / S/N / Year',
        value: (report.modelSerialInstallation ?? '').trim().isEmpty
            ? '—'
            : report.modelSerialInstallation!.trim(),
        icon: Icons.precision_manufacturing_outlined,
      ),
      (
        label: 'Operating Hrs/Day',
        value: (report.operatingHoursPerDay ?? '').trim().isEmpty
            ? '—'
            : report.operatingHoursPerDay!.trim(),
        icon: Icons.schedule_outlined,
      ),
      (
        label: 'Serial No',
        value: (report.serialNo ?? '').trim().isEmpty
            ? '—'
            : report.serialNo!.trim(),
        icon: Icons.qr_code_2_outlined,
      ),
      (
        label: 'Location',
        value: (report.location ?? '').trim().isEmpty
            ? '—'
            : report.location!.trim(),
        icon: Icons.place_outlined,
      ),
      (
        label: 'Date',
        value: _shortDate(report.reportDate),
        icon: Icons.calendar_today_outlined,
      ),
      (
        label: 'Approved At',
        value: _shortDate(report.approvedAt),
        icon: Icons.check_circle_outline,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: cols == 1 ? 5.0 : 4.4,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => Container(
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
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(items[i].icon, size: 18, color: AppColors.blue600),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    items[i].label.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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

String _shortDate(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return '—';
  return v.length >= 10 ? v.substring(0, 10) : v;
}

String? _fmtBytes(int? bytes) {
  if (bytes == null) return null;
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(1)} GB';
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    AppToast.show(
      context,
      message: 'Invalid file URL',
      type: AppToastType.error,
    );
    return;
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    AppToast.show(
      context,
      message: 'Could not open link',
      type: AppToastType.error,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.bg,
    required this.border,
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.textColor,
  });

  final Color bg;
  final Color border;
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDetailSkeleton extends StatelessWidget {
  const _ReportDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AppCard(child: ShimmerBox(height: 120)),
          SizedBox(height: 16),
          AppCard(child: ShimmerBox(height: 140)),
          SizedBox(height: 16),
          AppCard(child: ShimmerBox(height: 120)),
        ],
      ),
    );
  }
}
