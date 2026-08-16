import 'dart:async';
import 'dart:typed_data';
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
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../auth/application/auth_notifier.dart';
import '../../clients/data/clients_repository.dart';
import '../domain/report.dart';
import '../../technicians/data/technicians_repository.dart';
import '../application/reports_notifier.dart';

class ReportCreateScreen extends ConsumerWidget {
  const ReportCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull?.user;

    void close() {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        context.go('/reports');
      }
    }

    return _ServiceReportWizard(
      dio: ref.read(dioProvider),
      initialReport: null,
      isEditing: false,
      currentUserId: user?.id,
      currentUserName: user?.fullName ?? user?.firstName ?? 'You',
      currentRole: user?.role ?? '',
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

class ReportEditScreen extends ConsumerStatefulWidget {
  const ReportEditScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ReportEditScreen> createState() => _ReportEditScreenState();
}

class _ReportEditScreenState extends ConsumerState<ReportEditScreen> {
  Report? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final report = await ref
        .read(reportsProvider.notifier)
        .fetchDetail(widget.id);
    if (!mounted) return;
    setState(() {
      _report = report;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull?.user;
    if (_loading) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: AppCard(child: ShimmerBox(height: 420)),
          ),
        ),
      );
    }

    final report = _report;
    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Report')),
        body: const Center(child: Text('Report not found')),
      );
    }

    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canEdit = _canEdit(role, report);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Report')),
        body: const Center(child: Text('You cannot edit this report.')),
      );
    }

    return _ServiceReportWizard(
      dio: ref.read(dioProvider),
      initialReport: report,
      isEditing: true,
      currentUserId: user?.id,
      currentUserName: user?.fullName ?? user?.firstName ?? 'You',
      currentRole: user?.role ?? '',
      onSubmit: (payload, photos, technicalReports) async {
        final ok = await ref
            .read(reportsProvider.notifier)
            .updateWithUploads(
              id: report.id,
              payload: payload,
              existingTechnicalReports: report.technicalReports,
              photos: photos,
              technicalReports: technicalReports,
            );
        if (!context.mounted) return;
        if (ok) {
          AppToast.show(
            context,
            message: 'Report updated',
            type: AppToastType.success,
          );
          context.go('/reports/${report.id}');
        } else {
          AppToast.show(
            context,
            message: 'Failed to update report',
            type: AppToastType.error,
          );
        }
      },
    );
  }

  bool _canEdit(String role, Report report) {
    final lower = role.toLowerCase();
    return report.status != 'Approved' &&
        (const ['admin', 'manager'].contains(lower) || lower == 'technician');
  }
}

class _ServiceReportWizard extends StatefulWidget {
  const _ServiceReportWizard({
    required this.dio,
    required this.onSubmit,
    this.initialReport,
    this.isEditing = false,
    this.currentUserId,
    this.currentUserName = 'You',
    this.currentRole = '',
  });

  final Dio dio;
  final Report? initialReport;
  final bool isEditing;
  final int? currentUserId;
  final String currentUserName;
  final String currentRole;
  final Future<void> Function(
    Map<String, dynamic> payload,
    List<({String path, String name})> photos,
    List<({String path, String name})> technicalReports,
  )
  onSubmit;

  @override
  State<_ServiceReportWizard> createState() => _ServiceReportWizardState();
}

class _ServiceReportWizardState extends State<_ServiceReportWizard> {
  final _picker = ImagePicker();

  static const _steps = [
    (id: 1, label: 'Client Info', icon: Icons.assignment_outlined),
    (id: 2, label: 'Checklist', icon: Icons.checklist_outlined),
    (id: 3, label: 'Issues', icon: Icons.report_problem_outlined),
    (id: 4, label: 'Spares', icon: Icons.inventory_2_outlined),
    (id: 5, label: 'Remarks', icon: Icons.edit_note_outlined),
  ];

  static const _defaultChecklist = [
    _ChecklistItem(
      sr: 1,
      description: 'Check the oil level in the oil reserves.',
    ),
    _ChecklistItem(
      sr: 2,
      description:
          'Check the oil level on the Root Compressors (If available).',
    ),
    _ChecklistItem(sr: 3, description: 'Check the lubrication circuit.'),
    _ChecklistItem(sr: 4, description: 'Check the discharge valves.'),
    _ChecklistItem(sr: 5, description: 'Check & adjust the Gland packing.'),
    _ChecklistItem(sr: 6, description: 'Oil filter cleaning.'),
    _ChecklistItem(sr: 7, description: 'Greasing of the pump.'),
    _ChecklistItem(sr: 8, description: 'Check the oil seal Ring.'),
    _ChecklistItem(
      sr: 9,
      description: 'Check & adjustment of the driving belts.',
    ),
  ];

  static const _checklistStatusOptions = <int, List<String>>{
    1: ['', 'OK', 'Topped Up'],
    2: ['', 'OK', 'Topped Up', 'NA'],
    3: ['', 'Normal', 'Leakage', 'Blockage'],
    4: ['', 'OK', 'Cleaned / Replaced', 'Spare Required'],
    5: ['', 'OK', 'Adjusted / Replaced', 'Spare Required'],
    6: ['', 'OK', 'Cleaned / Replaced', 'Spare Required'],
    7: ['', 'OK', 'Done'],
    8: ['', 'OK', 'Replaced', 'Spare Required'],
    9: ['', 'OK', 'Replaced', 'Spare Required'],
  };

  static const _defaultSpares = [
    _SpareRow(spareName: 'Complete set of Gaskets'),
    _SpareRow(spareName: 'Complete set of Valve Gasket'),
    _SpareRow(spareName: 'Complete set of Valve Spring'),
    _SpareRow(spareName: 'Complete set of Valve Screw'),
    _SpareRow(spareName: 'Complete set of Oil Connectors'),
    _SpareRow(spareName: 'Ferrule / Insert / Reducer set'),
    _SpareRow(spareName: 'Nylon Tubing Set'),
  ];

  static const _issueData = <String, List<_IssueDataRow>>{
    'Low Vaccum': [
      _IssueDataRow(
        observation: 'Valve damage (chock up)',
        impactOnPump: 'Overheat',
        severity: 'Med',
        recommendedSpares: 'Valve set',
      ),
      _IssueDataRow(
        observation: 'Slide valve Damaged',
        impactOnPump: 'Abnormal Noise',
        severity: 'High',
        recommendedSpares: 'Slide valve or spring',
      ),
      _IssueDataRow(
        observation: 'Piston ring Damaged',
        impactOnPump: 'Piston or cylinder damage',
        severity: 'High',
        recommendedSpares: 'Piston ring',
      ),
      _IssueDataRow(
        observation: 'Oil seal Damaged',
        impactOnPump: 'Oil consumption Vacuum',
        severity: 'Med',
        recommendedSpares: 'Sealing set',
      ),
    ],
    'Abnormal Sound': [
      _IssueDataRow(
        observation: 'Slide valve / Slide Valve spring Damaged',
        impactOnPump: 'Overheat, Low Vacuum',
        severity: 'High',
        recommendedSpares: 'Slide valve / Slide Valve spring',
      ),
      _IssueDataRow(
        observation: 'Shell Bearing Damaged',
        impactOnPump: 'Mechanical Damaged',
        severity: 'High',
        recommendedSpares: 'Shell Bearing',
      ),
      _IssueDataRow(
        observation: 'Piston Pin / Bush Damaged',
        impactOnPump: 'Mechanical Damaged',
        severity: 'High',
        recommendedSpares: 'Piston Pin / Bush',
      ),
      _IssueDataRow(
        observation: 'Flywheel / Distrubustion Rod Bearing Damaged',
        impactOnPump: 'High Vibration',
        severity: 'High',
        recommendedSpares: 'Flywheel / Distrubustion Rod Bearing',
      ),
      _IssueDataRow(
        observation: 'Distribution Control Pin Damaged',
        impactOnPump: 'Lubrication Pump Damage',
        severity: 'High',
        recommendedSpares: 'Distribution Control Pin',
      ),
      _IssueDataRow(
        observation: 'Pin For Outer Lever Damaged',
        impactOnPump: 'Tie Rod Head Damage',
        severity: 'High',
        recommendedSpares: 'Pin For Outer Lever',
      ),
      _IssueDataRow(
        observation: 'Connecting Rod Damaged',
        impactOnPump: 'Mechanical Damage',
        severity: 'High',
        recommendedSpares: 'Connecting Rod',
      ),
      _IssueDataRow(
        observation: 'Crankshaft Damaged',
        impactOnPump: 'Mechanical Damage',
        severity: 'High',
        recommendedSpares: 'Crank Shaft',
      ),
      _IssueDataRow(
        observation: 'Inner Lever Damaged',
        impactOnPump: 'Slide Valve Damage',
        severity: 'High',
        recommendedSpares: 'Inner Lever',
      ),
      _IssueDataRow(
        observation: 'Cross Head Damaged',
        impactOnPump: 'Mechanical Damage',
        severity: 'High',
        recommendedSpares: 'Cross Head',
      ),
    ],
    'Excessive Oil': [
      _IssueDataRow(
        observation: 'Gland Packing Damaged',
        impactOnPump: 'Oil Leakage and Smoke',
        severity: 'Med',
        recommendedSpares: 'Gland Packing',
      ),
      _IssueDataRow(
        observation: 'Oil seal Damaged',
        impactOnPump: 'Oil Leakage',
        severity: 'High',
        recommendedSpares: 'Oil seal',
      ),
      _IssueDataRow(
        observation: 'Nylon Tubing Damaged',
        impactOnPump: 'Oil Leakage',
        severity: 'High',
        recommendedSpares: 'Nylon Tubing',
      ),
      _IssueDataRow(
        observation: 'Oil connector / Oiler Damaged',
        impactOnPump: 'Oil Leakage',
        severity: 'High',
        recommendedSpares: 'Oil connector / Oiler',
      ),
      _IssueDataRow(
        observation: 'Piston Rod Damaged',
        impactOnPump: 'Oil Consumption and Smoke',
        severity: 'Med',
        recommendedSpares: 'Piston Rod',
      ),
    ],
    'No Lubrication': [
      _IssueDataRow(
        observation: 'Oil Filter Chocked / Damaged',
        impactOnPump: 'Overheat, Wear and Tare on Cylinder and Piston',
        severity: 'High',
        recommendedSpares: 'Oil Filter Choked',
      ),
      _IssueDataRow(
        observation: 'Lubrication Pump/ Lever Damaged',
        impactOnPump: 'Overheat, Wear and Tare on Cylinder and Piston',
        severity: 'High',
        recommendedSpares: 'Lubrication Pump / Lever',
      ),
    ],
  };

  int _step = 1;
  bool _fetching = false;
  bool _loading = false;

  // dropdown data
  List<
    ({
      String id,
      String title,
      int? clientId,
      String clientName,
      String clientEmail,
      String contactPerson,
      String location,
      String? amcId,
      List<({int id, String name})> technicians,
    })
  >
  _jobs = const [];
  List<({int id, String name})> _techs = const [];
  List<
    ({int id, String name, String email, String contactPerson, String address})
  >
  _clients = const [];
  List<String> _poNumbers = const [];
  final Map<String, String> _amcPoById = {};

  // form fields
  String? _jobId;
  int? _techId;
  int? _clientId;
  String _clientName = '';

  final _title = TextEditingController();
  final _serialNo = TextEditingController();
  final _clientEmail = TextEditingController();
  final _companyName = TextEditingController();
  final _contactPerson = TextEditingController();
  final _location = TextEditingController();
  final _modelSerialInstallation = TextEditingController();
  final _operatingHoursPerDay = TextEditingController();
  final _applicationProcessDescription = TextEditingController();
  final _findings = TextEditingController();
  final _recommendations = TextEditingController();
  final _comments = TextEditingController();
  final _remarks = TextEditingController();
  final _vdtRepresentativeName = TextEditingController();
  final _clientRepresentativeName = TextEditingController();

  String? _poNumber;

  // PDF section state
  final List<_ChecklistItem> _checklist = _defaultChecklist
      .map((e) => e.copy())
      .toList();
  final List<_IssueRow> _issues = [_IssueRow.empty(sr: 1)];
  final List<_SpareRow> _spares = _defaultSpares.map((e) => e.copy()).toList();

  final List<_PhotoAttachment> _photos = [];
  final List<({String path, String name})> _technicalReports = [];
  final List<TechnicalReportFile> _existingTechnicalReports = [];
  final List<ReportImage> _existingImages = [];

  @override
  void initState() {
    super.initState();
    unawaited(_fetchDropdowns());
  }

  @override
  void didUpdateWidget(covariant _ServiceReportWizard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialReport?.id != widget.initialReport?.id &&
        widget.initialReport != null &&
        !_fetching) {
      _applyInitialReport(widget.initialReport!);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _serialNo.dispose();
    _clientEmail.dispose();
    _companyName.dispose();
    _contactPerson.dispose();
    _location.dispose();
    _modelSerialInstallation.dispose();
    _operatingHoursPerDay.dispose();
    _applicationProcessDescription.dispose();
    _findings.dispose();
    _recommendations.dispose();
    _comments.dispose();
    _remarks.dispose();
    _vdtRepresentativeName.dispose();
    _clientRepresentativeName.dispose();
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
            final technicians = <({int id, String name})>[];
            for (final rawTech in (e['technicians'] as List? ?? const [])) {
              if (rawTech is! Map) continue;
              final tech = rawTech.map((k, v) => MapEntry(k.toString(), v));
              final techId =
                  (tech['id'] as num?)?.toInt() ??
                  int.tryParse('${tech['id'] ?? ''}') ??
                  0;
              final techName = (tech['name'] ?? '').toString();
              if (techId != 0) {
                technicians.add((id: techId, name: techName));
              }
            }
            return (
              id: (e['id'] ?? '').toString(),
              title: (e['title'] ?? '').toString(),
              clientId: clientId,
              clientName: (e['client_name'] ?? '').toString(),
              clientEmail: (e['client_email'] ?? '').toString(),
              contactPerson: (e['contact_person'] ?? '').toString(),
              location: (e['location'] ?? '').toString(),
              amcId: (e['amc_id'] ?? '').toString().trim().isEmpty
                  ? null
                  : (e['amc_id'] ?? '').toString(),
              technicians: technicians,
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
        for (final c in clients)
          (
            id: c.id,
            name: c.name,
            email: c.email,
            contactPerson: c.contactPerson,
            address: c.address,
          ),
      ];

      try {
        final amcRes = await widget.dio.get(
          'amc',
          queryParameters: {'limit': 200},
        );
        final amcRoot = _asMap(amcRes.data);
        final amcList = _asList(amcRoot['data']);
        final set = <String>{};
        for (final raw in amcList.whereType<Map>()) {
          final amcId = (raw['id'] ?? '').toString().trim();
          final v = (raw['po_number'] ?? '').toString().trim();
          if (v.isNotEmpty) set.add(v);
          if (amcId.isNotEmpty && v.isNotEmpty) {
            _amcPoById[amcId] = v;
          }
        }
        _poNumbers = set.toList()..sort();
      } catch (_) {
        _poNumbers = const [];
      }
    } catch (_) {
      // ignore
    } finally {
      if (widget.initialReport != null) {
        _applyInitialReport(widget.initialReport!);
      } else {
        _syncJobSelection();
      }
      if (mounted) setState(() => _fetching = false);
    }
  }

  void _applyInitialReport(Report report) {
    _jobId = report.jobId.trim().isEmpty ? null : report.jobId.trim();
    _techId = int.tryParse((report.technicianId ?? '').trim());
    _clientId = int.tryParse((report.clientId ?? '').trim());
    _clientName = report.clientName.trim();
    _poNumber = (report.poNumber ?? '').trim().isEmpty
        ? null
        : report.poNumber!.trim();

    _title.text = report.title;
    _serialNo.text = (report.serialNo ?? '').trim();
    _clientEmail.text = (report.clientEmail ?? '').trim();
    _companyName.text = (report.companyName ?? report.clientName).trim();
    _contactPerson.text = (report.contactPerson ?? '').trim();
    _location.text = (report.location ?? '').trim();
    _modelSerialInstallation.text = (report.modelSerialInstallation ?? '')
        .trim();
    _operatingHoursPerDay.text = (report.operatingHoursPerDay ?? '').trim();
    _applicationProcessDescription.text =
        (report.applicationProcessDescription ?? '').trim();
    _findings.text = report.findings;
    _recommendations.text = report.recommendations;
    _comments.text = (report.comments ?? '').trim();
    _remarks.text = (report.remarks ?? '').trim();
    _vdtRepresentativeName.text = (report.vdtRepresentativeName ?? '').trim();
    _clientRepresentativeName.text = (report.clientRepresentativeName ?? '')
        .trim();

    for (int i = 0; i < _checklist.length; i++) {
      final existing = report.checklistItems.where((item) => item.sr == i + 1);
      if (existing.isNotEmpty) {
        _checklist[i] = _checklist[i].copyWith(status: existing.first.status);
      }
    }

    _issues
      ..clear()
      ..addAll(
        report.issueObservations.isEmpty
            ? [_IssueRow.empty(sr: 1)]
            : [
                for (final item in report.issueObservations)
                  _IssueRow(
                    sr: item.sr == 0 ? 1 : item.sr,
                    issue: item.issue,
                    observation: item.observation,
                    impactOnPump: item.impactOnPump,
                    severity: item.severity,
                    recommendedSpares: item.recommendedSpares,
                  ),
              ],
      );

    _spares
      ..clear()
      ..addAll(
        report.mandatorySpares.isEmpty
            ? _defaultSpares.map((e) => e.copy()).toList()
            : [
                for (final item in report.mandatorySpares)
                  _SpareRow(
                    spareName: item.spareName,
                    pumpModel: item.pumpModel,
                    totalToOrder: item.totalToOrder,
                  ),
              ],
      );

    _existingTechnicalReports
      ..clear()
      ..addAll(report.technicalReports);
    _existingImages
      ..clear()
      ..addAll(report.images);

    _syncJobSelection();
  }

  void _applyJob(String id) {
    final job = _findJob(id);
    if (job == null) return;

    if (job.clientId != null) _clientId = job.clientId;

    final selected = _findClient(_clientId);
    final name = job.clientName.trim().isNotEmpty
        ? job.clientName.trim()
        : (selected?.name ?? '').trim();
    _clientName = name;
    if (name.isNotEmpty) {
      _companyName.text = _companyName.text.trim().isNotEmpty
          ? _companyName.text
          : name;
    }

    final email = job.clientEmail.trim().isNotEmpty
        ? job.clientEmail.trim()
        : (selected?.email ?? '').trim();
    if (email.isNotEmpty) _clientEmail.text = email;

    final cp = job.contactPerson.trim().isNotEmpty
        ? job.contactPerson.trim()
        : (selected?.contactPerson ?? '').trim();
    if (_contactPerson.text.trim().isEmpty && cp.isNotEmpty) {
      _contactPerson.text = cp;
    }

    final location = job.location.trim().isNotEmpty
        ? job.location.trim()
        : (selected?.address ?? '').trim();
    if (location.isNotEmpty) {
      _location.text = location;
    }

    if (_isTechnician && widget.currentUserId != null) {
      _techId = widget.currentUserId;
    } else if (job.technicians.isNotEmpty) {
      _techId = job.technicians.first.id;
    }

    final amcPo = job.amcId == null ? null : _amcPoById[job.amcId!];
    if ((amcPo ?? '').trim().isNotEmpty) {
      _poNumber = amcPo;
    }
  }

  ({
    String id,
    String title,
    int? clientId,
    String clientName,
    String clientEmail,
    String contactPerson,
    String location,
    String? amcId,
    List<({int id, String name})> technicians,
  })?
  _findJob(String id) {
    for (final j in _jobs) {
      if (j.id == id) return j;
    }
    return null;
  }

  void _syncJobSelection() {
    final jobId = _jobId?.trim();
    if (_isTechnician && widget.currentUserId != null) {
      if ((jobId ?? '').isEmpty) {
        final visibleJobs = _jobs
            .where((job) {
              return job.technicians.any(
                (tech) => tech.id == widget.currentUserId,
              );
            })
            .toList(growable: false);
        if (visibleJobs.length == 1) {
          _jobId = visibleJobs.first.id;
        }
      }

      if ((_jobId ?? '').trim().isNotEmpty) {
        _applyJob(_jobId!);
      } else {
        _techId = widget.currentUserId;
      }
      return;
    }

    if ((jobId ?? '').isNotEmpty) {
      _applyJob(jobId!);
    }
  }

  ({int id, String name, String email, String contactPerson, String address})?
  _findClient(int? id) {
    if (id == null) return null;
    for (final c in _clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  bool _validateStep() {
    if (_step != 1) return true;
    if ((_jobId ?? '').trim().isEmpty ||
        _techId == null ||
        _title.text.trim().isEmpty ||
        _companyName.text.trim().isEmpty) {
      AppToast.show(
        context,
        message: 'Job, technician, title and company name are required.',
        type: AppToastType.error,
      );
      return false;
    }
    return true;
  }

  void _next() {
    if (!_validateStep()) return;
    setState(() => _step = (_step + 1).clamp(1, 5));
  }

  void _prev() => setState(() => _step = (_step - 1).clamp(1, 5));

  bool get _isTechnician => widget.currentRole.toLowerCase() == 'technician';

  Future<void> _pickTechnicalReports() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
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

  void _addIssue() =>
      setState(() => _issues.add(_IssueRow.empty(sr: _issues.length + 1)));

  void _removeIssue(int idx) => setState(() {
    _issues.removeAt(idx);
    for (int i = 0; i < _issues.length; i++) {
      _issues[i] = _issues[i].copyWith(sr: i + 1);
    }
  });

  void _setIssueType(int idx, String issueType) => setState(() {
    _issues[idx] = _issues[idx].copyWith(
      issue: issueType,
      observation: '',
      impactOnPump: '',
      severity: '',
      recommendedSpares: '',
    );
  });

  void _setIssueObservation(int idx, String observation) => setState(() {
    final issueType = _issues[idx].issue;
    final rows = _issueData[issueType] ?? const <_IssueDataRow>[];
    final matched = rows.where((r) => r.observation == observation).toList();
    final row = matched.isEmpty ? null : matched.first;
    _issues[idx] = _issues[idx].copyWith(
      observation: observation,
      impactOnPump: row?.impactOnPump ?? '',
      severity: row?.severity ?? '',
      recommendedSpares: row?.recommendedSpares ?? '',
    );
  });

  Future<void> _addPhotos(List<XFile> files) async {
    if (files.isEmpty) return;

    final added = <_PhotoAttachment>[];
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        added.add(_PhotoAttachment(file: file, name: file.name, bytes: bytes));
      } catch (_) {
        // Skip files that cannot be read on the current platform.
      }
    }

    if (added.isEmpty) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Unable to load the selected photos.',
        type: AppToastType.error,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _photos.addAll(added));
  }

  Future<void> _pickPhotos() async {
    final result = await _picker.pickMultiImage(imageQuality: 85);
    await _addPhotos(result);
  }

  Future<void> _capturePhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo == null) return;
    await _addPhotos([photo]);
  }

  void _removePhoto(int index) => setState(() => _photos.removeAt(index));

  Future<void> _submit() async {
    if (_loading) return;
    if (!_validateStep()) return;

    setState(() => _loading = true);
    try {
      final payload = <String, dynamic>{
        'job_id': _jobId,
        'title': _title.text.trim(),
        'technician_id': _techId,
        if ((_poNumber ?? '').trim().isNotEmpty) 'po_number': _poNumber!.trim(),
        if (_serialNo.text.trim().isNotEmpty)
          'serial_no': _serialNo.text.trim(),
        if (_clientId != null) 'client_id': _clientId,
        if (_clientName.trim().isNotEmpty) 'client_name': _clientName.trim(),
        if (_clientEmail.text.trim().isNotEmpty)
          'client_email': _clientEmail.text.trim(),
        'company_name': _companyName.text.trim(),
        if (_contactPerson.text.trim().isNotEmpty)
          'contact_person': _contactPerson.text.trim(),
        if (_location.text.trim().isNotEmpty) 'location': _location.text.trim(),
        if (_modelSerialInstallation.text.trim().isNotEmpty)
          'model_serial_installation': _modelSerialInstallation.text.trim(),
        if (_operatingHoursPerDay.text.trim().isNotEmpty)
          'operating_hours_per_day': _operatingHoursPerDay.text.trim(),
        if (_applicationProcessDescription.text.trim().isNotEmpty)
          'application_process_description': _applicationProcessDescription.text
              .trim(),
        if (_findings.text.trim().isNotEmpty) 'findings': _findings.text.trim(),
        if (_recommendations.text.trim().isNotEmpty)
          'recommendations': _recommendations.text.trim(),
        if (_comments.text.trim().isNotEmpty) 'comments': _comments.text.trim(),
        if (_remarks.text.trim().isNotEmpty) 'remarks': _remarks.text.trim(),
        if (_vdtRepresentativeName.text.trim().isNotEmpty)
          'vdt_representative_name': _vdtRepresentativeName.text.trim(),
        if (_clientRepresentativeName.text.trim().isNotEmpty)
          'client_representative_name': _clientRepresentativeName.text.trim(),
        'checklist_items': [
          for (final c in _checklist)
            if (c.status.trim().isNotEmpty) c.toJson(),
        ],
        'issue_observations': [
          for (final i in _issues)
            if (i.issue.trim().isNotEmpty || i.observation.trim().isNotEmpty)
              i.toJson(),
        ],
        'mandatory_spares': [
          for (final s in _spares)
            if (s.spareName.trim().isNotEmpty) s.toJson(),
        ],
      };

      await widget.onSubmit(payload, [
        for (final photo in _photos) (path: photo.file.path, name: photo.name),
      ], _technicalReports);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _step;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: widget.isEditing
                    ? 'Edit Service Report'
                    : 'Create Service Report',
                subtitle:
                    'A 5-step wizard for client details, checklist, issues, spares and remarks.',
                action: IconButton(
                  tooltip: 'Back',
                  onPressed: _loading ? null : () => context.go('/reports'),
                  icon: const Icon(Icons.close),
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                            Icons.fact_check_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Step $_step of 5',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _steps[_step - 1].label,
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: _step / _steps.length,
                        backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.blue600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _stepPills(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_fetching)
                const AppCard(child: ShimmerBox(height: 220))
              else ...[
                if (step == 1) _stepClientInfo(),
                if (step == 2) _stepChecklist(),
                if (step == 3) _stepIssues(),
                if (step == 4) _stepSpares(),
                if (step == 5) _stepRemarks(),
                const SizedBox(height: 16),
                BottomSafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: step == 1 ? 'Cancel' : 'Back',
                          variant: AppButtonVariant.secondary,
                          expanded: true,
                          onPressed: _loading
                              ? null
                              : step == 1
                              ? () => context.go('/reports')
                              : _prev,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: step == 5
                              ? (widget.isEditing
                                    ? 'Update Report'
                                    : 'Submit Report')
                              : 'Next',
                          expanded: true,
                          loading: _loading,
                          onPressed: _loading
                              ? null
                              : step == 5
                              ? _submit
                              : _next,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepPills() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? AppColors.gray800 : const Color(0xFFDBEAFE);
    final activeFg = isDark ? Colors.white : AppColors.blue600;
    final doneBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
    final doneFg = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
    final idleBg = isDark
        ? const Color(0xFF111827)
        : Theme.of(context).canvasColor;
    final idleFg = Theme.of(context).hintColor;

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < _steps.length; i++) ...[
              _StepChip(
                label: _steps[i].label,
                icon: _steps[i].icon,
                state: _step == _steps[i].id
                    ? _StepChipState.active
                    : (_step > _steps[i].id
                          ? _StepChipState.done
                          : _StepChipState.idle),
                activeBg: activeBg,
                activeFg: activeFg,
                doneBg: doneBg,
                doneFg: doneFg,
                idleBg: idleBg,
                idleFg: idleFg,
                onTap: _steps[i].id < _step && !_loading
                    ? () => setState(() => _step = _steps[i].id)
                    : null,
              ),
              if (i != _steps.length - 1)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: 22,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: _step > _steps[i].id
                        ? (isDark ? const Color(0xFF34D399) : doneFg)
                        : Theme.of(context).dividerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int lines = 1,
    bool required = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label **' : label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          enabled: !_loading,
          maxLines: lines,
          decoration: InputDecoration(hintText: hint),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _dropdownJob() {
    final visibleJobs = _isTechnician && widget.currentUserId != null
        ? _jobs
              .where(
                (job) => job.technicians.any(
                  (tech) => tech.id == widget.currentUserId,
                ),
              )
              .toList(growable: false)
        : _jobs;

    return _SearchableDropdownString(
      label: 'Linked Job **',
      value: _jobId,
      allowNull: true,
      nullLabel: 'Select job...',
      enabled: !_loading,
      items: [
        for (final j in visibleJobs)
          (value: j.id, label: '${j.id} — ${j.title}'),
      ],
      onChanged: (v) => setState(() {
        _jobId = v;
        if (v != null) {
          _applyJob(v);
        }
      }),
    );
  }

  Widget _dropdownTech() {
    if (_isTechnician) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Technician **',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0B1220)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              widget.currentUserName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    }

    return _SearchableDropdownInt(
      label: 'Technician **',
      value: _techId,
      allowNull: true,
      nullLabel: 'Select technician...',
      enabled: !_loading,
      items: [for (final t in _techs) (value: t.id, label: t.name)],
      onChanged: (v) => setState(() => _techId = v),
    );
  }

  Widget _dropdownClient() {
    return _SearchableDropdownInt(
      label: 'Client',
      value: _clientId,
      allowNull: true,
      nullLabel: 'Select client...',
      enabled: !_loading,
      items: [for (final c in _clients) (value: c.id, label: c.name)],
      onChanged: (v) {
        final selected = _findClient(v);
        setState(() {
          _clientId = v;
          _clientName = selected?.name ?? _clientName;
          if (selected != null) {
            if (selected.email.trim().isNotEmpty) {
              _clientEmail.text = selected.email.trim();
            }
            if (_companyName.text.trim().isEmpty &&
                selected.name.trim().isNotEmpty) {
              _companyName.text = selected.name.trim();
            }
            if (_contactPerson.text.trim().isEmpty &&
                selected.contactPerson.trim().isNotEmpty) {
              _contactPerson.text = selected.contactPerson.trim();
            }
            if (selected.address.trim().isNotEmpty) {
              _location.text = selected.address.trim();
            }
          }
        });
      },
    );
  }

  Widget _dropdownPoNumber() {
    return _SearchableDropdownString(
      label: 'PO Number',
      value: _poNumber,
      allowNull: true,
      nullLabel: 'Select PO...',
      enabled: !_loading,
      items: [for (final p in _poNumbers) (value: p, label: p)],
      onChanged: (v) => setState(() => _poNumber = v),
      onTextChanged: (text) => setState(() => _poNumber = text.trim()),
    );
  }

  Widget _stepClientInfo() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1 — Client & Report Info',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _dropdownJob(),
          const SizedBox(height: 12),
          _dropdownTech(),
          const SizedBox(height: 12),
          _field(
            'Report Title',
            _title,
            required: true,
            hint: 'Quarterly AMC Service — Italvacuum Pump',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _dropdownPoNumber()),
              const SizedBox(width: 12),
              Expanded(
                child: _field('Serial No.', _serialNo, hint: 'VCP-2023-7842'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Client Info (PDF Page 1)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _dropdownClient(),
          const SizedBox(height: 12),
          _field(
            'Client Email',
            _clientEmail,
            hint: 'client@company.com',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  'Company Name',
                  _companyName,
                  required: true,
                  hint: 'Acme Industries Pvt Ltd',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  'Contact Person',
                  _contactPerson,
                  hint: 'Rajesh Mehta',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field(
            'Location / Address',
            _location,
            hint: 'Plot No. 123, GIDC Sachin, Surat',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  'Model / Serial No. / Installation Year',
                  _modelSerialInstallation,
                  hint: 'ITPUMP-V2 / SN-20034 / 2021',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  'Operating Hours / Day',
                  _operatingHoursPerDay,
                  hint: '18 hrs',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field(
            'Application / Process Description',
            _applicationProcessDescription,
            hint: 'Vacuum drying of pharmaceutical granules',
            lines: 2,
          ),
        ],
      ),
    );
  }

  Widget _stepChecklist() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Routine Preventive Maintenance Checklist',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Select the status for each checklist item.',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
          ),
          const SizedBox(height: 12),
          for (int idx = 0; idx < _checklist.length; idx++) ...[
            _ChecklistRow(
              item: _checklist[idx],
              options:
                  _checklistStatusOptions[_checklist[idx].sr] ??
                  const ['', 'OK', 'Done'],
              enabled: !_loading,
              onChanged: (v) => setState(
                () => _checklist[idx] = _checklist[idx].copyWith(status: v),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          _InfoBanner(
            icon: Icons.info_outline,
            text:
                'Maintain a clean, dry and workable installation area; ensure ventilation and prevent dust/chemicals near the pump.',
          ),
        ],
      ),
    );
  }

  Widget _stepIssues() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Detailed Issue Observation Matrix',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              AppButton(
                label: 'Add Issue',
                variant: AppButtonVariant.secondary,
                leading: const Icon(Icons.add, size: 18),
                onPressed: _loading ? null : _addIssue,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Selecting an observation auto-fills impact, severity and recommended spares.',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
          ),
          const SizedBox(height: 12),
          for (int idx = 0; idx < _issues.length; idx++) ...[
            _IssueCard(
              issue: _issues[idx],
              enabled: !_loading,
              issueTypes: _issueData.keys.toList(),
              observationOptions: _issues[idx].issue.trim().isEmpty
                  ? const []
                  : [
                      for (final r
                          in _issueData[_issues[idx].issue] ?? const [])
                        r.observation,
                    ],
              impactOptions: _issues[idx].issue.trim().isEmpty
                  ? const []
                  : _unique([
                      for (final r
                          in _issueData[_issues[idx].issue] ?? const [])
                        r.impactOnPump,
                    ]),
              sparesOptions: _issues[idx].issue.trim().isEmpty
                  ? const []
                  : _unique([
                      for (final r
                          in _issueData[_issues[idx].issue] ?? const [])
                        r.recommendedSpares,
                    ]),
              onRemove: _issues.length <= 1 ? null : () => _removeIssue(idx),
              onTypeChanged: (v) => _setIssueType(idx, v),
              onObservationChanged: (v) => _setIssueObservation(idx, v),
              onImpactChanged: (v) => setState(
                () => _issues[idx] = _issues[idx].copyWith(impactOnPump: v),
              ),
              onSeverityChanged: (v) => setState(
                () => _issues[idx] = _issues[idx].copyWith(severity: v),
              ),
              onSparesChanged: (v) => setState(
                () =>
                    _issues[idx] = _issues[idx].copyWith(recommendedSpares: v),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _stepSpares() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mandatory Spares — AMC Compliance Matrix',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              AppButton(
                label: 'Add Spare',
                variant: AppButtonVariant.secondary,
                leading: const Icon(Icons.add, size: 18),
                onPressed: _loading
                    ? null
                    : () => setState(() => _spares.add(_SpareRow.empty())),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < _spares.length; i++) ...[
            _SpareCard(
              spare: _spares[i],
              enabled: !_loading,
              onChanged: (next) => setState(() => _spares[i] = next),
              onRemove: _spares.length <= 1
                  ? null
                  : () => setState(() => _spares.removeAt(i)),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          _InfoBanner(
            icon: Icons.info_outline,
            text:
                'The above-listed spares are mandatory/recommended and must be procured before the next scheduled maintenance visit.',
          ),
        ],
      ),
    );
  }

  Widget _stepRemarks() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Findings', _findings, hint: 'Findings…', lines: 3),
          const SizedBox(height: 12),
          _field(
            'Recommendations',
            _recommendations,
            hint: 'Recommendations…',
            lines: 2,
          ),
          const SizedBox(height: 12),
          _field(
            'Remarks (PDF Page 3)',
            _remarks,
            hint: 'Additional remarks or observations from the visit…',
            lines: 3,
          ),
          const SizedBox(height: 16),
          _field('Comments', _comments, hint: 'Comments…', lines: 2),
          const SizedBox(height: 12),
          const Divider(height: 24),
          Text(
            'Signatures (PDF Page 4)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  'VDT Representative Name',
                  _vdtRepresentativeName,
                  hint: 'Suresh Patil',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  'Client Representative Name',
                  _clientRepresentativeName,
                  hint: 'Rajesh Mehta',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Attachments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Documents, reports, or photos',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
          ),
          const SizedBox(height: 12),
          _AttachmentPicker(
            enabled: !_loading,
            onDocumentTap: _pickTechnicalReports,
            onGalleryTap: _pickPhotos,
            onCameraTap: _capturePhoto,
          ),
          if (_existingTechnicalReports.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Existing Report Copies',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final file in _existingTechnicalReports)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined, size: 18),
                      title: Text(
                        file.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: file.fileSizeBytes == null
                          ? null
                          : Text(_fmtBytes(file.fileSizeBytes) ?? '—'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                    ),
                ],
              ),
            ),
          ],
          if (_existingImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Existing Photos',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _existingImages.length,
                    itemBuilder: (context, i) {
                      final img = _existingImages[i];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          img.fileUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  size: 30,
                                ),
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_photos.isNotEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attached Photos',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _photos.length,
                    itemBuilder: (context, i) {
                      final photo = _photos[i];
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              photo.bytes,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      size: 30,
                                    ),
                                  ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: InkWell(
                              onTap: _loading ? null : () => _removePhoto(i),
                              borderRadius: BorderRadius.circular(999),
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
                      );
                    },
                  ),
                ],
              ),
            )
          else
            Text(
              'No photos selected yet.',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          if (_technicalReports.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Uploaded Report Copies',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < _technicalReports.length; i++)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined, size: 18),
                      title: Text(
                        _technicalReports[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        onPressed: _loading
                            ? null
                            : () =>
                                  setState(() => _technicalReports.removeAt(i)),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoAttachment {
  const _PhotoAttachment({
    required this.file,
    required this.name,
    required this.bytes,
  });

  final XFile file;
  final String name;
  final Uint8List bytes;
}

class _SearchableDropdownInt extends StatefulWidget {
  const _SearchableDropdownInt({
    required this.label,
    required this.value,
    required this.items,
    required this.enabled,
    required this.onChanged,
    this.allowNull = false,
    this.nullLabel = '— Please select —',
  });

  final String label;
  final int? value;
  final List<({int value, String label})> items;
  final bool enabled;
  final bool allowNull;
  final String nullLabel;
  final ValueChanged<int?> onChanged;

  @override
  State<_SearchableDropdownInt> createState() => _SearchableDropdownIntState();
}

class _SearchableDropdownIntState extends State<_SearchableDropdownInt> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _selectedLabel(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _SearchableDropdownInt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final label = _selectedLabel(widget.value);
      if (_controller.text != label) {
        _controller.text = label;
        _controller.selection = TextSelection.collapsed(offset: label.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _selectedLabel(int? value) {
    if (value == null) return '';
    for (final item in widget.items) {
      if (item.value == value) return item.label;
    }
    return '';
  }

  void _syncFromText(String text) {
    final query = text.trim().toLowerCase();
    if (query.isEmpty) {
      widget.onChanged(null);
      return;
    }

    final matches = widget.items
        .where((item) => item.label.trim().toLowerCase() == query)
        .toList(growable: false);
    if (matches.length == 1) {
      widget.onChanged(matches.single.value);
    } else {
      widget.onChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final divider = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: divider),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 6),
        RawAutocomplete<({int value, String label})>(
          textEditingController: _controller,
          focusNode: _focusNode,
          displayStringForOption: (option) => option.label,
          optionsBuilder: (TextEditingValue value) {
            final query = value.text.trim().toLowerCase();
            if (query.isEmpty) return widget.items;
            return widget.items.where(
              (item) => item.label.toLowerCase().contains(query),
            );
          },
          onSelected: (option) {
            _controller.text = option.label;
            _controller.selection = TextSelection.collapsed(
              offset: option.label.length,
            );
            widget.onChanged(option.value);
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textController,
                  focusNode: focusNode,
                  enabled: widget.enabled,
                  onChanged: _syncFromText,
                  onSubmitted: (_) {
                    onFieldSubmitted();
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: InputDecoration(
                    hintText: widget.allowNull
                        ? 'Type to search or leave blank'
                        : 'Type to search',
                    isDense: false,
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0B1220)
                        : const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: baseBorder,
                    enabledBorder: baseBorder,
                    focusedBorder: focusedBorder,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (textController.text.trim().isNotEmpty &&
                            widget.enabled)
                          IconButton(
                            tooltip: 'Clear',
                            onPressed: () {
                              textController.clear();
                              widget.onChanged(null);
                              _focusNode.requestFocus();
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: surface,
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SizedBox(
                  width: 360,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    itemCount: options.length + (widget.allowNull ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      if (widget.allowNull) {
                        if (index == 0) {
                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(widget.nullLabel),
                            onTap: () {
                              _controller.clear();
                              widget.onChanged(null);
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                          );
                        }
                        index -= 1;
                      }
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          option.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchableDropdownString extends StatefulWidget {
  const _SearchableDropdownString({
    required this.label,
    required this.value,
    required this.items,
    required this.enabled,
    required this.onChanged,
    this.onTextChanged,
    this.allowNull = false,
    this.nullLabel = '— Please select —',
  });

  final String label;
  final String? value;
  final List<({String value, String label})> items;
  final bool enabled;
  final bool allowNull;
  final String nullLabel;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String>? onTextChanged;

  @override
  State<_SearchableDropdownString> createState() =>
      _SearchableDropdownStringState();
}

class _SearchableDropdownStringState extends State<_SearchableDropdownString> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _selectedLabel(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _SearchableDropdownString oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final label = _selectedLabel(widget.value);
      if (_controller.text != label) {
        _controller.text = label;
        _controller.selection = TextSelection.collapsed(offset: label.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _selectedLabel(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return '';
    for (final item in widget.items) {
      if (item.value == v) return item.label;
    }
    return '';
  }

  void _syncFromText(String text) {
    widget.onTextChanged?.call(text);
    if (widget.onTextChanged != null) return;

    final query = text.trim().toLowerCase();
    if (query.isEmpty) {
      widget.onChanged(null);
      return;
    }

    final matches = widget.items
        .where((item) => item.label.trim().toLowerCase() == query)
        .toList(growable: false);
    if (matches.length == 1) {
      widget.onChanged(matches.single.value);
    } else {
      widget.onChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final divider = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: divider),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 6),
        RawAutocomplete<({String value, String label})>(
          textEditingController: _controller,
          focusNode: _focusNode,
          displayStringForOption: (option) => option.label,
          optionsBuilder: (TextEditingValue value) {
            final query = value.text.trim().toLowerCase();
            if (query.isEmpty) return widget.items;
            return widget.items.where(
              (item) => item.label.toLowerCase().contains(query),
            );
          },
          onSelected: (option) {
            _controller.text = option.label;
            _controller.selection = TextSelection.collapsed(
              offset: option.label.length,
            );
            widget.onChanged(option.value);
            widget.onTextChanged?.call(option.value);
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textController,
                  focusNode: focusNode,
                  enabled: widget.enabled,
                  onChanged: _syncFromText,
                  onSubmitted: (_) {
                    onFieldSubmitted();
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: InputDecoration(
                    hintText: widget.allowNull
                        ? 'Type to search or leave blank'
                        : 'Type to search',
                    isDense: false,
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0B1220)
                        : const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: baseBorder,
                    enabledBorder: baseBorder,
                    focusedBorder: focusedBorder,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (textController.text.trim().isNotEmpty &&
                            widget.enabled)
                          IconButton(
                            tooltip: 'Clear',
                            onPressed: () {
                              textController.clear();
                              widget.onChanged(null);
                              widget.onTextChanged?.call('');
                              _focusNode.requestFocus();
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: surface,
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SizedBox(
                  width: 360,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    itemCount: options.length + (widget.allowNull ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      if (widget.allowNull) {
                        if (index == 0) {
                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(widget.nullLabel),
                            onTap: () {
                              _controller.clear();
                              widget.onChanged(null);
                              widget.onTextChanged?.call('');
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                          );
                        }
                        index -= 1;
                      }
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          option.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _AttachmentAction { document, gallery, camera }

class _AttachmentPicker extends StatelessWidget {
  const _AttachmentPicker({
    required this.enabled,
    required this.onDocumentTap,
    required this.onGalleryTap,
    required this.onCameraTap,
  });

  final bool enabled;
  final VoidCallback onDocumentTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AttachmentAction>(
      enabled: enabled,
      tooltip: 'Add attachment',
      offset: const Offset(0, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case _AttachmentAction.document:
            onDocumentTap();
            break;
          case _AttachmentAction.gallery:
            onGalleryTap();
            break;
          case _AttachmentAction.camera:
            onCameraTap();
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<_AttachmentAction>(
          value: _AttachmentAction.document,
          child: _AttachmentMenuTile(
            icon: Icons.description_outlined,
            title: 'Upload Document',
            subtitle: 'PDF, DOCX, XLSX…',
            color: AppColors.blue600,
          ),
        ),
        PopupMenuItem<_AttachmentAction>(
          value: _AttachmentAction.gallery,
          child: _AttachmentMenuTile(
            icon: Icons.photo_library_outlined,
            title: 'Upload Photo',
            subtitle: 'From gallery',
            color: Color(0xFF8B5CF6),
          ),
        ),
        PopupMenuItem<_AttachmentAction>(
          value: _AttachmentAction.camera,
          child: _AttachmentMenuTile(
            icon: Icons.camera_alt_outlined,
            title: 'Take Photo',
            subtitle: 'Opens camera',
            color: Color(0xFFF59E0B),
          ),
        ),
      ],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF111827)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: AppColors.blue600),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add Attachment',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'Documents, photos, or camera capture',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentMenuTile extends StatelessWidget {
  const _AttachmentMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
    );
  }
}

String? _fmtBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return null;
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  return '$bytes B';
}

class _ChecklistItem {
  const _ChecklistItem({
    required this.sr,
    required this.description,
    this.status = '',
  });

  final int sr;
  final String description;
  final String status;

  _ChecklistItem copyWith({String? status}) => _ChecklistItem(
    sr: sr,
    description: description,
    status: status ?? this.status,
  );

  _ChecklistItem copy() => copyWith();

  Map<String, dynamic> toJson() => {
    'sr': sr,
    'description': description,
    'status': status,
  };
}

class _IssueRow {
  const _IssueRow({
    required this.sr,
    this.issue = '',
    this.observation = '',
    this.impactOnPump = '',
    this.severity = '',
    this.recommendedSpares = '',
  });

  factory _IssueRow.empty({required int sr}) => _IssueRow(sr: sr);

  final int sr;
  final String issue;
  final String observation;
  final String impactOnPump;
  final String severity;
  final String recommendedSpares;

  _IssueRow copyWith({
    int? sr,
    String? issue,
    String? observation,
    String? impactOnPump,
    String? severity,
    String? recommendedSpares,
  }) => _IssueRow(
    sr: sr ?? this.sr,
    issue: issue ?? this.issue,
    observation: observation ?? this.observation,
    impactOnPump: impactOnPump ?? this.impactOnPump,
    severity: severity ?? this.severity,
    recommendedSpares: recommendedSpares ?? this.recommendedSpares,
  );

  Map<String, dynamic> toJson() => {
    'sr': sr,
    'issue': issue,
    'observation': observation,
    'impact_on_pump': impactOnPump,
    'severity': severity,
    'recommended_spares': recommendedSpares,
  };
}

class _SpareRow {
  const _SpareRow({
    required this.spareName,
    this.pumpModel = '',
    this.totalToOrder = '',
  });

  factory _SpareRow.empty() => const _SpareRow(spareName: '');

  final String spareName;
  final String pumpModel;
  final String totalToOrder;

  _SpareRow copyWith({
    String? spareName,
    String? pumpModel,
    String? totalToOrder,
  }) => _SpareRow(
    spareName: spareName ?? this.spareName,
    pumpModel: pumpModel ?? this.pumpModel,
    totalToOrder: totalToOrder ?? this.totalToOrder,
  );

  _SpareRow copy() => copyWith();

  Map<String, dynamic> toJson() => {
    'spare_name': spareName,
    'pump_model': pumpModel,
    'total_to_order': totalToOrder,
  };
}

class _IssueDataRow {
  const _IssueDataRow({
    required this.observation,
    required this.impactOnPump,
    required this.severity,
    required this.recommendedSpares,
  });

  final String observation;
  final String impactOnPump;
  final String severity;
  final String recommendedSpares;
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.item,
    required this.options,
    required this.enabled,
    required this.onChanged,
  });

  final _ChecklistItem item;
  final List<String> options;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : AppColors.gray50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in options)
                      ChoiceChip(
                        label: Text(o.isEmpty ? 'None' : o),
                        selected: item.status == o,
                        onSelected: !enabled ? null : (_) => onChanged(o),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                        selectedColor: AppColors.blue600,
                        backgroundColor: isDark
                            ? const Color(0xFF0B1220)
                            : Colors.white,
                        side: BorderSide(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                        ),
                        checkmarkColor: Colors.white,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.issue,
    required this.enabled,
    required this.issueTypes,
    required this.observationOptions,
    required this.impactOptions,
    required this.sparesOptions,
    required this.onTypeChanged,
    required this.onObservationChanged,
    required this.onImpactChanged,
    required this.onSeverityChanged,
    required this.onSparesChanged,
    this.onRemove,
  });

  final _IssueRow issue;
  final bool enabled;
  final List<String> issueTypes;
  final List<String> observationOptions;
  final List<String> impactOptions;
  final List<String> sparesOptions;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onObservationChanged;
  final ValueChanged<String> onImpactChanged;
  final ValueChanged<String> onSeverityChanged;
  final ValueChanged<String> onSparesChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    Color badgeBg() {
      switch (issue.severity) {
        case 'High':
          return const Color(0xFFFEE2E2);
        case 'Med':
          return const Color(0xFFFEF3C7);
        case 'Low':
          return const Color(0xFFD1FAE5);
      }
      return const Color(0xFFDBEAFE);
    }

    Color badgeFg() {
      switch (issue.severity) {
        case 'High':
          return AppColors.red500;
        case 'Med':
          return const Color(0xFFB45309);
        case 'Low':
          return AppColors.emerald500;
      }
      return AppColors.blue600;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBg(),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${issue.sr}',
                  style: TextStyle(
                    color: badgeFg(),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  issue.issue.trim().isEmpty
                      ? 'Issue ${issue.sr}'
                      : issue.issue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Remove',
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AppDropdownField<String>(
            label: 'Issue Type',
            value: issue.issue.isEmpty ? null : issue.issue,
            allowNull: true,
            nullLabel: '— Select issue —',
            enabled: enabled,
            items: [
              for (final t in issueTypes) AppDropdownItem(value: t, label: t),
            ],
            onChanged: (v) => onTypeChanged(v ?? ''),
          ),
          const SizedBox(height: 10),
          AppDropdownField<String>(
            label: 'Observation',
            value: issue.observation.isEmpty ? null : issue.observation,
            allowNull: true,
            nullLabel: issue.issue.trim().isEmpty
                ? '— Select issue type first —'
                : '— Select observation —',
            enabled: enabled && issue.issue.trim().isNotEmpty,
            items: [
              for (final t in observationOptions)
                AppDropdownItem(value: t, label: t),
            ],
            onChanged: (v) => onObservationChanged(v ?? ''),
          ),
          const SizedBox(height: 10),
          AppDropdownField<String>(
            label: 'Impact on Pump',
            value: issue.impactOnPump.isEmpty ? null : issue.impactOnPump,
            allowNull: true,
            nullLabel: issue.issue.trim().isEmpty
                ? '— Select issue first —'
                : '— Select impact —',
            enabled: enabled && issue.issue.trim().isNotEmpty,
            items: [
              for (final t in impactOptions)
                AppDropdownItem(value: t, label: t),
            ],
            onChanged: (v) => onImpactChanged(v ?? ''),
          ),
          const SizedBox(height: 10),
          Text(
            'Severity',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sev in const ['Low', 'Med', 'High'])
                ChoiceChip(
                  label: Text(sev),
                  selected: issue.severity == sev,
                  onSelected: !enabled || issue.issue.trim().isEmpty
                      ? null
                      : (_) => onSeverityChanged(sev),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AppDropdownField<String>(
            label: 'Recommended Spares',
            value: issue.recommendedSpares.isEmpty
                ? null
                : issue.recommendedSpares,
            allowNull: true,
            nullLabel: issue.issue.trim().isEmpty
                ? '— Select issue first —'
                : '— Select recommended spares —',
            enabled: enabled && issue.issue.trim().isNotEmpty,
            items: [
              for (final t in sparesOptions)
                AppDropdownItem(value: t, label: t),
            ],
            onChanged: (v) => onSparesChanged(v ?? ''),
          ),
        ],
      ),
    );
  }
}

class _SpareCard extends StatefulWidget {
  const _SpareCard({
    required this.spare,
    required this.enabled,
    required this.onChanged,
    this.onRemove,
  });

  final _SpareRow spare;
  final bool enabled;
  final ValueChanged<_SpareRow> onChanged;
  final VoidCallback? onRemove;

  @override
  State<_SpareCard> createState() => _SpareCardState();
}

class _SpareCardState extends State<_SpareCard> {
  late final TextEditingController _spareNameCtrl;
  late final TextEditingController _pumpModelCtrl;
  late final TextEditingController _totalCtrl;

  @override
  void initState() {
    super.initState();
    _spareNameCtrl = TextEditingController(text: widget.spare.spareName);
    _pumpModelCtrl = TextEditingController(text: widget.spare.pumpModel);
    _totalCtrl = TextEditingController(text: widget.spare.totalToOrder);
  }

  @override
  void didUpdateWidget(covariant _SpareCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spare.spareName != widget.spare.spareName) {
      _spareNameCtrl.text = widget.spare.spareName;
    }
    if (oldWidget.spare.pumpModel != widget.spare.pumpModel) {
      _pumpModelCtrl.text = widget.spare.pumpModel;
    }
    if (oldWidget.spare.totalToOrder != widget.spare.totalToOrder) {
      _totalCtrl.text = widget.spare.totalToOrder;
    }
  }

  @override
  void dispose() {
    _spareNameCtrl.dispose();
    _pumpModelCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.spare.spareName.trim().isEmpty
                      ? 'Spare'
                      : widget.spare.spareName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (widget.onRemove != null)
                IconButton(
                  tooltip: 'Remove',
                  onPressed: widget.enabled ? widget.onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _spareNameCtrl,
            enabled: widget.enabled,
            decoration: const InputDecoration(labelText: 'Spare Name'),
            onChanged: (v) =>
                widget.onChanged(widget.spare.copyWith(spareName: v)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pumpModelCtrl,
            enabled: widget.enabled,
            decoration: const InputDecoration(labelText: 'Pump Model'),
            onChanged: (v) =>
                widget.onChanged(widget.spare.copyWith(pumpModel: v)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _totalCtrl,
            enabled: widget.enabled,
            decoration: const InputDecoration(labelText: 'Total To Order'),
            onChanged: (v) =>
                widget.onChanged(widget.spare.copyWith(totalToOrder: v)),
          ),
        ],
      ),
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

List<String> _unique(List<String> items) {
  final set = <String>{};
  for (final i in items) {
    final t = i.trim();
    if (t.isEmpty) continue;
    set.add(t);
  }
  return set.toList()..sort();
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic v) => v is List ? v : const [];

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.icon,
    required this.state,
    required this.activeBg,
    required this.activeFg,
    required this.doneBg,
    required this.doneFg,
    required this.idleBg,
    required this.idleFg,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final _StepChipState state;
  final Color activeBg;
  final Color activeFg;
  final Color doneBg;
  final Color doneFg;
  final Color idleBg;
  final Color idleFg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (state) {
      _StepChipState.active => (activeBg, activeFg, Colors.transparent),
      _StepChipState.done => (doneBg, doneFg, Colors.transparent),
      _StepChipState.idle => (
        idleBg,
        idleFg,
        Theme.of(context).dividerColor.withValues(alpha: 0.12),
      ),
    };

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: child,
    );
  }
}

enum _StepChipState { active, done, idle }
