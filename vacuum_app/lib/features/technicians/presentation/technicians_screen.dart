import 'dart:io';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
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
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../core/ui/ui_providers.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/technicians_notifier.dart';
import '../domain/technician.dart';

const _specializations = ['ITR'];
const _statuses = ['Active', 'On Leave', 'Inactive'];
const _documentTypes = [
  'Aadhaar Card',
  'Technician Photo',
  'WC Policy',
  'Medical Insurance Policy',
  'Other',
];
const _documentFileExtensions = [
  'pdf',
  'jpg',
  'jpeg',
  'png',
  'webp',
  'doc',
  'docx',
];
const _maxTechnicianDocumentBytes = 20 * 1024 * 1024;

class TechniciansScreen extends ConsumerStatefulWidget {
  const TechniciansScreen({super.key});

  @override
  ConsumerState<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends ConsumerState<TechniciansScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final next = query.trim();
      ref.read(searchQueryProvider.notifier).state = query;
      ref.read(techniciansProvider.notifier).search(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final lowerRole = role.toLowerCase();
    final canEdit = lowerRole != 'technician';
    final canDelete = canEdit;
    final state = ref.watch(techniciansProvider);

    ref.listen<String>(searchQueryProvider, (_, next) {
      if (_searchController.text != next) {
        _searchController.text = next;
      }
    });

    return RefreshIndicator(
      onRefresh: () => ref.read(techniciansProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          Icons.engineering_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      if (canEdit)
                        AppButton(
                          label: '+ Add Technician',
                          size: AppButtonSize.sm,
                          onPressed: () => context.push('/technicians/new'),
                        ),
                    ],
                  ),
                  Text(
                    'Technicians',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search technicians, open a profile, or jump into edit mode quickly.',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatPill(
                        label: 'Active',
                        value:
                            state.whenOrNull(
                              data: (d) => d.items
                                  .where((t) => t.status == 'Active')
                                  .length,
                            ) ??
                            0,
                        color: AppColors.emerald500,
                      ),
                      _StatPill(
                        label: 'On Leave',
                        value:
                            state.whenOrNull(
                              data: (d) => d.items
                                  .where((t) => t.status == 'On Leave')
                                  .length,
                            ) ??
                            0,
                        color: AppColors.amber500,
                      ),
                      _StatPill(
                        label: 'Inactive',
                        value:
                            state.whenOrNull(
                              data: (d) => d.items
                                  .where((t) => t.status == 'Inactive')
                                  .length,
                            ) ??
                            0,
                        color: AppColors.red500,
                      ),
                      _StatPill(
                        label: 'All',
                        value:
                            state.whenOrNull(data: (d) => d.items.length) ?? 0,
                        color: AppColors.blue600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    decoration: const InputDecoration(
                      hintText: 'Search technicians...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            state.when(
              loading: () => const _TechniciansSkeleton(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load',
                description: friendlyErrorMessage(e),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.engineering_outlined,
                    title: 'No technicians found',
                    description:
                        'Try a different search or add a new technician.',
                  );
                }

                final width = MediaQuery.sizeOf(context).width;
                final cols = width >= 1024 ? 3 : (width >= 600 ? 2 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: cols == 1
                        ? (canEdit ? 1.12 : 1.24)
                        : (canEdit ? 0.98 : 1.12),
                  ),
                  itemCount: data.items.length,
                  itemBuilder: (context, i) {
                    final tech = data.items[i];
                    return _TechnicianCard(
                      tech: tech,
                      canEdit: canEdit,
                      canDelete: canDelete,
                      onOpen: () => context.go('/technicians/${tech.id}'),
                      onEdit: () => _openFormSheet(context, tech),
                      onDelete: () => _confirmDelete(context, tech),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFormSheet(BuildContext context, Technician? tech) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => _TechnicianFormSheet(
        existing: tech,
        fetchById: tech == null
            ? null
            : () => ref.read(techniciansProvider.notifier).fetchById(tech.id),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Technician tech) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Technician',
      body:
          'Are you sure you want to remove ${tech.name}? This cannot be undone.',
      confirmLabel: 'Remove',
    );

    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(techniciansProvider.notifier).delete(tech.id);
      if (!context.mounted) return;
      AppToast.show(
        context,
        message: 'Technician removed',
        type: AppToastType.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        message: friendlyErrorMessage(e),
        type: AppToastType.error,
      );
    }
  }
}

class TechnicianCreateScreen extends ConsumerWidget {
  const TechnicianCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _TechnicianFormSheet(
      asSheet: false,
      existing: null,
      fetchById: null,
    );
  }
}

class TechnicianEditScreen extends ConsumerWidget {
  const TechnicianEditScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsedId = int.tryParse(id);
    if (parsedId == null) {
      return const Scaffold(body: Center(child: Text('Invalid technician id')));
    }

    return FutureBuilder<Technician?>(
      future: ref.read(techniciansProvider.notifier).fetchById(parsedId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final tech = snapshot.data;
        if (tech == null) {
          return const Scaffold(
            body: Center(child: Text('Technician not found')),
          );
        }

        return _TechnicianFormSheet(
          asSheet: false,
          existing: tech,
          fetchById: () =>
              ref.read(techniciansProvider.notifier).fetchById(parsedId),
        );
      },
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({
    required this.tech,
    required this.canEdit,
    required this.canDelete,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Technician tech;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBg = isDark ? const Color(0xFF111827) : AppColors.gray50;

    return AppCard(
      onTap: onOpen,
      hover: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AppAvatar(
                initials: initialsFromName(tech.name),
                size: AppAvatarSize.lg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tech.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tech.specialization,
                      style: const TextStyle(
                        color: AppColors.blue600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusBadge(label: tech.status),
            ],
          ),
          const SizedBox(height: 10),
          if (tech.email.isNotEmpty)
            _ContactRow(icon: Icons.mail_outline, text: tech.email),
          _ContactRow(icon: Icons.phone_outlined, text: tech.phone),
          const SizedBox(height: 8),
          _ContactRow(
            icon: Icons.star_outline,
            text: 'Rating ${tech.rating.toStringAsFixed(1)}',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Jobs',
                  value: tech.jobsCompleted.toString(),
                  bg: boxBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Rating',
                  value: '★ ${tech.rating.toStringAsFixed(1)}',
                  bg: boxBg,
                  valueColor: AppColors.amber500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Since',
                  value: tech.joinDate != null && tech.joinDate!.length >= 4
                      ? tech.joinDate!.substring(0, 4)
                      : '—',
                  bg: boxBg,
                ),
              ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Edit',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.sm,
                    leading: const Icon(Icons.edit_outlined),
                    expanded: true,
                    onPressed: onEdit,
                  ),
                ),
                if (canDelete) ...[
                  const SizedBox(width: 8),
                  AppButton(
                    label: '',
                    variant: AppButtonVariant.danger,
                    size: AppButtonSize.sm,
                    leading: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ],
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.gray400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.bg,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color bg;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianFormSheet extends ConsumerStatefulWidget {
  const _TechnicianFormSheet({
    required this.existing,
    required this.fetchById,
    this.asSheet = true,
  });

  final Technician? existing;
  final Future<Technician?> Function()? fetchById;
  final bool asSheet;

  @override
  ConsumerState<_TechnicianFormSheet> createState() =>
      _TechnicianFormSheetState();
}

class _TechnicianFormSheetState extends ConsumerState<_TechnicianFormSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final List<_TechnicianDocumentDraft> _documents = [];

  String _specialization = _specializations.first;
  String _status = _statuses.first;
  DateTime? _joinDate;

  bool _loading = false;
  bool _fetchingDetails = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _name.text = t.name;
      _email.text = t.email;
      _phone.text = t.phone;
      _specialization = t.specialization.isNotEmpty
          ? t.specialization
          : _specializations.first;
      _status = _statuses.contains(t.status) ? t.status : _statuses.first;
      _joinDate = _parseDate(t.joinDate);
      _loadLatestIfNeeded();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    for (final doc in _documents) {
      doc.dispose();
    }
    super.dispose();
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> _loadLatestIfNeeded() async {
    final fetch = widget.fetchById;
    if (fetch == null) return;
    setState(() => _fetchingDetails = true);
    final latest = await fetch();
    if (!mounted) return;
    setState(() => _fetchingDetails = false);
    if (latest == null) return;

    _name.text = latest.name;
    _email.text = latest.email;
    _phone.text = latest.phone;
    _specialization = latest.specialization.isNotEmpty
        ? latest.specialization
        : _specializations.first;
    _status = _statuses.contains(latest.status)
        ? latest.status
        : _statuses.first;
    _joinDate = _parseDate(latest.joinDate);
    setState(() {});
  }

  void _close() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      context.go('/technicians');
    }
  }

  void _addDocument() {
    setState(() => _documents.add(_TechnicianDocumentDraft()));
  }

  void _removeDocument(int index) {
    final doc = _documents.removeAt(index);
    doc.dispose();
    setState(() {});
  }

  Future<void> _pickDocumentFile(int index) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: _documentFileExtensions,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.path == null || file.path!.isEmpty) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'File picking is not supported on this platform yet.',
        type: AppToastType.info,
      );
      return;
    }

    final size = await File(file.path!).length();
    if (size > _maxTechnicianDocumentBytes) {
      if (!mounted) return;
      AppToast.show(
        context,
        message:
            'Document is too large. Please choose a file smaller than 20 MB.',
        type: AppToastType.error,
      );
      return;
    }

    setState(() {
      _documents[index].file = file;
      if (_documents[index].documentName.text.trim().isEmpty) {
        _documents[index].documentName.text = file.name;
      }
    });
  }

  Future<void> _pickJoinDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _joinDate = picked);
    }
  }

  Future<void> _pickExpiryDate(_TechnicianDocumentDraft doc) async {
    final initial = doc.expiryDate.text.isNotEmpty
        ? DateTime.tryParse(doc.expiryDate.text)
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        doc.expiryDate.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<Map<String, dynamic>> _uploadDocument(
    _TechnicianDocumentDraft doc,
  ) async {
    final file = doc.file;
    if (file == null || file.path == null || file.path!.isEmpty) {
      throw Exception('Please attach a file for each technician document.');
    }

    return ref
        .read(techniciansRepositoryProvider)
        .uploadTechnicianDocument(
          filePath: file.path!,
          filename: file.name,
          documentType: doc.documentType,
          documentName: doc.documentName.text.trim().isEmpty
              ? file.name
              : doc.documentName.text.trim(),
          expiryDate: doc.expiryDate.text.trim().isEmpty
              ? null
              : doc.expiryDate.text.trim(),
          notes: doc.notes.text.trim().isEmpty ? null : doc.notes.text.trim(),
        );
  }

  Map<String, dynamic> _normalizeUploadedDocument(
    Map<String, dynamic> uploaded,
    _TechnicianDocumentDraft draft,
  ) {
    final documentName = draft.documentName.text.trim().isEmpty
        ? (uploaded['original_name'] ?? uploaded['file_name'] ?? '').toString()
        : draft.documentName.text.trim();
    final fileName = (uploaded['file_name'] ?? uploaded['original_name'] ?? '')
        .toString();
    return <String, dynamic>{
      if ((uploaded['document_type'] ?? draft.documentType ?? '')
          .toString()
          .trim()
          .isNotEmpty)
        'document_type': (uploaded['document_type'] ?? draft.documentType)
            .toString(),
      'document_name': documentName,
      'file_name': fileName.isNotEmpty ? fileName : documentName,
      if ((uploaded['file_url'] ?? '').toString().isNotEmpty)
        'file_url': uploaded['file_url'].toString(),
      if ((uploaded['mime_type'] ?? '').toString().isNotEmpty)
        'mime_type': uploaded['mime_type'].toString(),
      if ((uploaded['expiry_date'] ?? draft.expiryDate.text)
          .toString()
          .isNotEmpty)
        'expiry_date': (uploaded['expiry_date'] ?? draft.expiryDate.text)
            .toString(),
      if ((uploaded['notes'] ?? draft.notes.text).toString().isNotEmpty)
        'notes': (uploaded['notes'] ?? draft.notes.text).toString(),
    };
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      AppToast.show(
        context,
        message: 'Name and phone are required.',
        type: AppToastType.error,
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final payload = <String, dynamic>{
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'specialization': _specialization,
        'status': _status,
        if (_joinDate != null)
          'join_date': _joinDate!.toIso8601String().substring(0, 10),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
      };

      if (!_isEdit) {
        final password = _password.text.trim();
        if (password.isNotEmpty) {
          payload['password'] = password;
        }

        final uploadedDocs = <Map<String, dynamic>>[];
        for (final doc in _documents) {
          if (doc.file == null) continue;
          try {
            final uploaded = await _uploadDocument(doc);
            uploadedDocs.add(_normalizeUploadedDocument(uploaded, doc));
          } catch (e) {
            if (!mounted) return;
            AppToast.show(
              context,
              message: friendlyErrorMessage(e),
              type: AppToastType.error,
            );
            return;
          }
        }

        if (uploadedDocs.isNotEmpty) {
          payload['documents'] = uploadedDocs;
        }
      }

      final notifier = ref.read(techniciansProvider.notifier);
      final ok = _isEdit && widget.existing != null
          ? await notifier.updateTechnician(widget.existing!.id, payload)
          : await notifier.create(payload);

      if (!mounted) return;
      if (ok) {
        _close();
        AppToast.show(
          context,
          message: _isEdit ? 'Technician updated!' : 'Technician added!',
          type: AppToastType.success,
        );
      } else {
        AppToast.show(
          context,
          message: 'Unable to save the technician. Please try again.',
          type: AppToastType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: friendlyErrorMessage(e),
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    Widget content(ScrollController? scroll) {
      final width = MediaQuery.sizeOf(context).width;
      final wide = width >= 720;

      return SingleChildScrollView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(
          16,
          widget.asSheet ? 0 : 16,
          16,
          bottomInset + 16,
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
                      onPressed: _loading ? null : _close,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text(
                      _isEdit ? 'Edit Technician' : 'Add Technician',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ] else ...[
                Text(
                  _isEdit ? 'Edit Technician' : 'Add Technician',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                _isEdit
                    ? 'Update the technician details.'
                    : 'Add the technician details, optional login password, and any documents you want linked at creation time.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 16),
              if (_fetchingDetails)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic Info',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 16),
                      _field('Full Name *', _name, hint: 'Ravi Kumar'),
                      const SizedBox(height: 12),
                      if (wide)
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                'Email (optional)',
                                _email,
                                hint: 'ravi@ism.com',
                                keyboard: TextInputType.emailAddress,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                'Phone *',
                                _phone,
                                hint: '9876543210',
                                keyboard: TextInputType.phone,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _field(
                          'Email (optional)',
                          _email,
                          hint: 'ravi@ism.com',
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          'Phone *',
                          _phone,
                          hint: '9876543210',
                          keyboard: TextInputType.phone,
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (wide)
                        Row(
                          children: [
                            Expanded(
                              child: _dropdown(
                                'Specialization',
                                _specialization,
                                (_specialization.isNotEmpty &&
                                        !_specializations.contains(
                                          _specialization,
                                        ))
                                    ? [..._specializations, _specialization]
                                    : _specializations,
                                (v) => setState(
                                  () => _specialization =
                                      v ?? _specializations.first,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dropdown(
                                'Status',
                                _status,
                                _statuses,
                                (v) => setState(
                                  () => _status = v ?? _statuses.first,
                                ),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _dropdown(
                          'Specialization',
                          _specialization,
                          (_specialization.isNotEmpty &&
                                  !_specializations.contains(_specialization))
                              ? [..._specializations, _specialization]
                              : _specializations,
                          (v) => setState(
                            () => _specialization = v ?? _specializations.first,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _dropdown(
                          'Status',
                          _status,
                          _statuses,
                          (v) => setState(() => _status = v ?? _statuses.first),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _datePicker(context),
                    ],
                  ),
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Login Account',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Technicians can log in with their registered mobile number. Email is optional.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                        const SizedBox(height: 12),
                        _field(
                          'Password (optional)',
                          _password,
                          hint: 'Leave blank if no login needed',
                          type: AppInputType.password,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'If provided, this technician can also log in via email.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ],
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
                              child: Text(
                                'Documents',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            AppButton(
                              label: 'Add Document',
                              variant: AppButtonVariant.secondary,
                              size: AppButtonSize.sm,
                              leading: const Icon(Icons.add),
                              onPressed: _loading ? null : _addDocument,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload files first, then the app will attach their URLs to the technician create request.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                        const SizedBox(height: 12),
                        if (_documents.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF0B1220)
                                  : AppColors.gray50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No documents added yet',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add Aadhaar, photo, insurance, or policy documents if you want them linked at creation time.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _documents.length,
                            separatorBuilder: (context, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final doc = _documents[index];
                              return _TechnicianDocumentCard(
                                index: index,
                                draft: doc,
                                onRemove: _loading
                                    ? null
                                    : () => _removeDocument(index),
                                onPickFile: _loading
                                    ? null
                                    : () => _pickDocumentFile(index),
                                onPickExpiry: _loading
                                    ? null
                                    : () => _pickExpiryDate(doc),
                                onChanged: () => setState(() {}),
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
                          onPressed: _loading ? null : _close,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: _isEdit
                              ? 'Update Technician'
                              : 'Add Technician',
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

    if (!widget.asSheet) return content(null);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scroll) => content(scroll),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    TextInputType? keyboard,
    AppInputType type = AppInputType.text,
  }) {
    final effectiveType = switch (keyboard) {
      TextInputType.emailAddress => AppInputType.email,
      TextInputType.phone => AppInputType.phone,
      TextInputType.number => AppInputType.number,
      _ => type,
    };

    return AppInput(
      label: label,
      controller: ctrl,
      type: effectiveType,
      placeholder: hint,
      enabled: !_loading,
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return AppDropdownField<String>(
      label: label,
      value: value,
      items: [for (final o in options) AppDropdownItem(value: o, label: o)],
      enabled: !_loading,
      onChanged: onChanged,
    );
  }

  Widget _datePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Join Date',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _loading ? null : _pickJoinDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? const Color(0xFF374151) : AppColors.gray200,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isDark ? const Color(0xFF0B1220) : AppColors.gray50,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.gray400,
                ),
                const SizedBox(width: 8),
                Text(
                  _joinDate != null
                      ? _joinDate!.toIso8601String().substring(0, 10)
                      : 'Select date',
                  style: TextStyle(
                    color: _joinDate != null ? null : AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TechnicianDocumentDraft {
  _TechnicianDocumentDraft()
    : documentName = TextEditingController(),
      expiryDate = TextEditingController(),
      notes = TextEditingController();

  String? documentType;
  PlatformFile? file;
  final TextEditingController documentName;
  final TextEditingController expiryDate;
  final TextEditingController notes;

  void dispose() {
    documentName.dispose();
    expiryDate.dispose();
    notes.dispose();
  }
}

class _TechnicianDocumentCard extends StatelessWidget {
  const _TechnicianDocumentCard({
    required this.index,
    required this.draft,
    required this.onRemove,
    required this.onPickFile,
    required this.onPickExpiry,
    required this.onChanged,
  });

  final int index;
  final _TechnicianDocumentDraft draft;
  final VoidCallback? onRemove;
  final VoidCallback? onPickFile;
  final VoidCallback? onPickExpiry;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final file = draft.file;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1220) : AppColors.gray50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Document ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Remove document',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AppDropdownField<String>(
            label: 'Document Type',
            value: draft.documentType,
            items: [
              for (final type in _documentTypes)
                AppDropdownItem(value: type, label: type),
            ],
            allowNull: true,
            nullLabel: 'Select document type',
            onChanged: (value) {
              draft.documentType = value;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.documentName,
            enabled: onPickFile != null,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Document Name',
              hintText: 'Ravi Aadhaar Front',
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPickExpiry,
            child: IgnorePointer(
              child: TextField(
                controller: draft.expiryDate,
                onChanged: (_) => onChanged(),
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'YYYY-MM-DD',
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.notes,
            onChanged: (_) => onChanged(),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Optional notes',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: file == null ? 'Choose File' : 'Replace File',
                  variant: AppButtonVariant.secondary,
                  leading: const Icon(Icons.attach_file),
                  onPressed: onPickFile,
                ),
              ),
              if (file != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
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

class _TechniciansSkeleton extends StatelessWidget {
  const _TechniciansSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 1024 ? 3 : (width >= 600 ? 2 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: cols == 1 ? 1.35 : 1.05,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(width: 48, height: 48, borderRadius: 999),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 140, height: 14, borderRadius: 8),
                      SizedBox(height: 6),
                      ShimmerBox(width: 90, height: 12, borderRadius: 8),
                    ],
                  ),
                ),
                ShimmerBox(width: 54, height: 16, borderRadius: 999),
              ],
            ),
            SizedBox(height: 10),
            ShimmerBox(height: 11, borderRadius: 8),
            SizedBox(height: 6),
            ShimmerBox(width: 180, height: 11, borderRadius: 8),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: ShimmerBox(height: 38, borderRadius: 12)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 38, borderRadius: 12)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 38, borderRadius: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
