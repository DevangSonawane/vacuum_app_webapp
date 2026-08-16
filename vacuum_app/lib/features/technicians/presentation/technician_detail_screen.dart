import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dropdown_field.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/bottom_safe_area.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/technicians_notifier.dart';
import '../domain/technician.dart';

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

class TechnicianDetailScreen extends ConsumerStatefulWidget {
  const TechnicianDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TechnicianDetailScreen> createState() =>
      _TechnicianDetailScreenState();
}

class _TechnicianDetailScreenState
    extends ConsumerState<TechnicianDetailScreen> {
  AsyncValue<Technician?> _technician = const AsyncLoading();
  List<TechnicianDocument> _documents = const [];
  List<TechnicianRating> _ratings = const [];
  String _tab = 'documents';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _technician = const AsyncLoading());
    final parsed = int.tryParse(widget.id);
    if (parsed == null) {
      if (!mounted) return;
      setState(() {
        _technician = const AsyncData(null);
        _documents = const [];
        _ratings = const [];
      });
      return;
    }

    final repo = ref.read(techniciansRepositoryProvider);
    final tech = await ref.read(techniciansProvider.notifier).fetchById(parsed);
    if (!mounted) return;

    List<TechnicianDocument> documents = tech?.documents ?? const [];
    List<TechnicianRating> ratings = const [];

    try {
      documents = await repo.fetchDocuments(parsed);
    } catch (_) {
      // Fall back to the embedded documents from the technician response.
    }

    try {
      ratings = await repo.fetchRatings(parsed);
    } catch (_) {
      ratings = const [];
    }

    if (!mounted) return;
    setState(() {
      _technician = AsyncData(tech);
      _documents = documents;
      _ratings = ratings;
    });
  }

  bool get _canEdit {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    return role.toLowerCase() != 'technician';
  }

  Future<void> _openDocumentDialog({TechnicianDocument? existing}) async {
    final parsed = int.tryParse(widget.id);
    if (parsed == null) return;

    String? selectedType = existing?.documentType;
    final documentName = TextEditingController(
      text: existing?.documentName ?? '',
    );
    final expiryDate = TextEditingController(text: existing?.expiryDate ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    PlatformFile? pickedFile;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        Future<void> pickFile(void Function(void Function()) setDialogState) async {
          final result = await FilePicker.platform.pickFiles(
            allowMultiple: false,
            type: FileType.custom,
            allowedExtensions: _documentFileExtensions,
          );
          if (result == null || result.files.isEmpty) return;

          final file = result.files.single;
          if (file.path == null || file.path!.isEmpty) {
            if (!dialogContext.mounted) return;
            AppToast.show(
              dialogContext,
              message: 'File picking is not supported on this platform yet.',
              type: AppToastType.info,
            );
            return;
          }

          final size = await File(file.path!).length();
          if (size > _maxTechnicianDocumentBytes) {
            if (!dialogContext.mounted) return;
            AppToast.show(
              dialogContext,
              message:
                  'Document is too large. Please choose a file smaller than 20 MB.',
              type: AppToastType.error,
            );
            return;
          }

          setDialogState(() {
            pickedFile = file;
            if (documentName.text.trim().isEmpty) {
              documentName.text = file.name;
            }
          });
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Upload Document' : 'Edit Document',
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (existing == null) ...[
                        AppDropdownField<String>(
                          label: 'Document Type',
                          value: selectedType,
                          allowNull: true,
                          nullLabel: 'Select document type',
                          items: [
                            for (final type in _documentTypes)
                              AppDropdownItem(value: type, label: type),
                          ],
                          onChanged: (value) => setDialogState(
                            () => selectedType = value,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: pickedFile == null ? 'Choose File' : 'Replace File',
                          variant: AppButtonVariant.secondary,
                          leading: const Icon(Icons.attach_file),
                          expanded: true,
                          onPressed: saving ? null : () => pickFile(setDialogState),
                        ),
                        const SizedBox(height: 8),
                        if (pickedFile != null)
                          Text(
                            pickedFile!.name,
                            style: TextStyle(color: Theme.of(context).hintColor),
                          ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: documentName,
                        decoration: const InputDecoration(
                          labelText: 'Document Name',
                          hintText: 'Aadhaar Front',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: expiryDate,
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: expiryDate.text.isNotEmpty
                                ? DateTime.tryParse(expiryDate.text) ?? DateTime.now()
                                : DateTime.now(),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 3650),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                          );
                          if (picked != null) {
                            expiryDate.text = picked
                                .toIso8601String()
                                .substring(0, 10);
                            setDialogState(() {});
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date',
                          hintText: 'YYYY-MM-DD',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notes,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Optional notes',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: existing == null ? 'Upload' : 'Save',
                  loading: saving,
                  onPressed: saving
                      ? null
                      : () async {
                          if (existing == null && pickedFile == null) {
                            AppToast.show(
                              dialogContext,
                              message: 'Please select a file.',
                              type: AppToastType.error,
                            );
                            return;
                          }
                          if (documentName.text.trim().isEmpty) {
                            AppToast.show(
                              dialogContext,
                              message: 'Document name is required.',
                              type: AppToastType.error,
                            );
                            return;
                          }

                          setDialogState(() => saving = true);
                          try {
                            final repo = ref.read(techniciansRepositoryProvider);
                            if (existing == null) {
                              final uploaded = await repo.uploadTechnicianDocument(
                                filePath: pickedFile!.path!,
                                filename: pickedFile!.name,
                                documentType: selectedType,
                                documentName: documentName.text.trim(),
                                expiryDate: expiryDate.text.trim().isEmpty
                                    ? null
                                    : expiryDate.text.trim(),
                                notes: notes.text.trim().isEmpty
                                    ? null
                                    : notes.text.trim(),
                              );
                              await repo.createDocument(parsed, {
                                'document_type': selectedType,
                                'document_name': documentName.text.trim(),
                                'file_name': (uploaded['file_name'] ?? uploaded['original_name'] ?? documentName.text.trim()).toString(),
                                'file_url': uploaded['file_url']?.toString(),
                                'mime_type': uploaded['mime_type']?.toString(),
                                if (expiryDate.text.trim().isNotEmpty)
                                  'expiry_date': expiryDate.text.trim(),
                                if (notes.text.trim().isNotEmpty)
                                  'notes': notes.text.trim(),
                              });
                              if (!dialogContext.mounted) return;
                              AppToast.show(
                                dialogContext,
                                message: 'Document uploaded!',
                                type: AppToastType.success,
                              );
                            } else {
                              await repo.updateDocument(parsed, existing.id, {
                                'document_name': documentName.text.trim(),
                                if (expiryDate.text.trim().isNotEmpty)
                                  'expiry_date': expiryDate.text.trim(),
                                if (notes.text.trim().isNotEmpty)
                                  'notes': notes.text.trim(),
                              });
                              if (!dialogContext.mounted) return;
                              AppToast.show(
                                dialogContext,
                                message: 'Document updated!',
                                type: AppToastType.success,
                              );
                            }
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            await _load();
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            AppToast.show(
                              dialogContext,
                              message: friendlyErrorMessage(e),
                              type: AppToastType.error,
                            );
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => saving = false);
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );

    documentName.dispose();
    expiryDate.dispose();
    notes.dispose();
  }

  Future<void> _openRatingDialog({TechnicianRating? existing}) async {
    final parsed = int.tryParse(widget.id);
    if (parsed == null) return;

    double ratingValue = existing?.rating ?? 0;
    final review = TextEditingController(text: existing?.review ?? '');
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Rating' : 'Edit Rating'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        children: List.generate(5, (index) {
                          final star = index + 1;
                          return IconButton(
                            onPressed: saving
                                ? null
                                : () => setDialogState(() {
                                    ratingValue = star.toDouble();
                                  }),
                            icon: Icon(
                              Icons.star,
                              color: ratingValue >= star
                                  ? Colors.amber.shade600
                                  : Colors.grey.shade300,
                            ),
                          );
                        }),
                      ),
                      Text(
                        ratingValue > 0
                            ? ratingValue.toStringAsFixed(1)
                            : 'Select a rating',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: review,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Review (optional)',
                          hintText: 'Share your experience...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: existing == null ? 'Submit' : 'Update',
                  loading: saving,
                  onPressed: saving
                      ? null
                      : () async {
                          if (ratingValue <= 0) {
                            AppToast.show(
                              dialogContext,
                              message: 'Please select a rating.',
                              type: AppToastType.error,
                            );
                            return;
                          }
                          setDialogState(() => saving = true);
                          try {
                            final repo = ref.read(techniciansRepositoryProvider);
                            final payload = <String, dynamic>{
                              'rating': ratingValue,
                              if (review.text.trim().isNotEmpty)
                                'review': review.text.trim(),
                            };
                            if (existing == null) {
                              await repo.createRating(parsed, payload);
                              if (!dialogContext.mounted) return;
                              AppToast.show(
                                dialogContext,
                                message: 'Rating submitted!',
                                type: AppToastType.success,
                              );
                            } else {
                              await repo.updateRating(parsed, existing.id, payload);
                              if (!dialogContext.mounted) return;
                              AppToast.show(
                                dialogContext,
                                message: 'Rating updated!',
                                type: AppToastType.success,
                              );
                            }
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            await _load();
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            AppToast.show(
                              dialogContext,
                              message: friendlyErrorMessage(e),
                              type: AppToastType.error,
                            );
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => saving = false);
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );

    review.dispose();
  }

  Future<void> _openPasswordDialog() async {
    final parsed = int.tryParse(widget.id);
    if (parsed == null) return;

    final password = TextEditingController();
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Set Password'),
              content: SizedBox(
                width: 360,
                child: TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Minimum 6 characters',
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'Update',
                  loading: saving,
                  onPressed: saving
                      ? null
                      : () async {
                          if (password.text.trim().length < 6) {
                            AppToast.show(
                              dialogContext,
                              message: 'Password must be at least 6 characters.',
                              type: AppToastType.error,
                            );
                            return;
                          }
                          setDialogState(() => saving = true);
                          try {
                            await ref
                                .read(techniciansRepositoryProvider)
                                .setPassword(parsed, password.text.trim());
                            if (!dialogContext.mounted) return;
                            AppToast.show(
                              dialogContext,
                              message: 'Password updated!',
                              type: AppToastType.success,
                            );
                            Navigator.of(dialogContext).pop();
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            AppToast.show(
                              dialogContext,
                              message: friendlyErrorMessage(e),
                              type: AppToastType.error,
                            );
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => saving = false);
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );

    password.dispose();
  }

  Future<void> _deleteDocument(TechnicianDocument doc) async {
    final parsed = int.tryParse(widget.id);
    if (parsed == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Document',
      body: 'Are you sure you want to delete this document? This cannot be undone.',
      confirmLabel: 'Delete',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(techniciansRepositoryProvider).deleteDocument(parsed, doc.id);
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Document deleted',
        type: AppToastType.success,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: friendlyErrorMessage(e),
        type: AppToastType.error,
      );
    }
  }

  Future<void> _deleteRating(TechnicianRating rating) async {
    final parsed = int.tryParse(widget.id);
    if (parsed == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Rating',
      body: 'Are you sure you want to delete this rating?',
      confirmLabel: 'Delete',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(techniciansRepositoryProvider).deleteRating(parsed, rating.id);
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Rating deleted',
        type: AppToastType.success,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: friendlyErrorMessage(e),
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsedId = int.tryParse(widget.id);

    return Scaffold(
      body: _technician.when(
        loading: () => const _TechnicianDetailSkeleton(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load',
          description: friendlyErrorMessage(e),
        ),
        data: (tech) {
          if (tech == null) {
            return const EmptyState(
              icon: Icons.engineering_outlined,
              title: 'Technician not found',
              description: 'The technician may have been deleted.',
            );
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppButton(
                        label: 'Back',
                        variant: AppButtonVariant.secondary,
                        size: AppButtonSize.sm,
                        leading: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/technicians'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tech.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (_canEdit && parsedId != null) ...[
                        AppButton(
                          label: 'Password',
                          variant: AppButtonVariant.secondary,
                          size: AppButtonSize.sm,
                          leading: const Icon(Icons.key_outlined),
                          onPressed: _openPasswordDialog,
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          label: 'Edit',
                          variant: AppButtonVariant.outline,
                          size: AppButtonSize.sm,
                          leading: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              context.push('/technicians/${widget.id}/edit'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _HeaderCard(tech: tech),
                  const SizedBox(height: 16),
                  _InfoGrid(tech: tech),
                  const SizedBox(height: 16),
                  _SectionTabs(
                    currentTab: _tab,
                    docsCount: _documents.length,
                    ratingsCount: _ratings.length,
                    jobsCount: tech.recentJobs.length,
                    onTabChanged: (tab) => setState(() => _tab = tab),
                  ),
                  const SizedBox(height: 12),
                  if (_tab == 'documents') ...[
                    _SectionTitle(
                      title: 'Documents',
                      subtitle: '${_documents.length} items',
                      action: _canEdit && parsedId != null
                          ? AppButton(
                              label: 'Upload',
                              size: AppButtonSize.sm,
                              leading: const Icon(Icons.upload_outlined),
                              onPressed: () => _openDocumentDialog(),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 8),
                    if (_documents.isEmpty)
                      Text(
                        'No documents uploaded.',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      )
                    else
                      Column(
                        children: [
                          for (final doc in _documents)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _DocumentCard(
                                doc: doc,
                                canEdit: _canEdit,
                                onOpen: doc.fileUrl.isEmpty
                                    ? null
                                    : () async {
                                        final uri = Uri.tryParse(doc.fileUrl);
                                        if (uri == null) return;
                                        final ok = await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (!ok && context.mounted) {
                                          AppToast.show(
                                            context,
                                            message: 'Unable to open file.',
                                            type: AppToastType.error,
                                          );
                                        }
                                      },
                                onEdit: () => _openDocumentDialog(existing: doc),
                                onDelete: () => _deleteDocument(doc),
                              ),
                            ),
                        ],
                      ),
                  ] else if (_tab == 'ratings') ...[
                    _SectionTitle(
                      title: 'Ratings',
                      subtitle: '${_ratings.length} items',
                      action: _canEdit && parsedId != null
                          ? AppButton(
                              label: 'Add Rating',
                              size: AppButtonSize.sm,
                              leading: const Icon(Icons.star_outline),
                              onPressed: () => _openRatingDialog(),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 8),
                    if (_ratings.isEmpty)
                      Text(
                        'No ratings yet.',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      )
                    else
                      Column(
                        children: [
                          for (final rating in _ratings)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _RatingCard(
                                rating: rating,
                                canEdit: _canEdit,
                                onEdit: () => _openRatingDialog(existing: rating),
                                onDelete: () => _deleteRating(rating),
                              ),
                            ),
                        ],
                      ),
                  ] else ...[
                    _SectionTitle(
                      title: 'Recent Jobs',
                      subtitle: '${tech.recentJobs.length} items',
                    ),
                    const SizedBox(height: 8),
                    if (tech.recentJobs.isEmpty)
                      Text(
                        'No recent jobs available.',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      )
                    else
                      Column(
                        children: [
                          for (final job in tech.recentJobs)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job.id,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.blue600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            job.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (job.closedDate != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Closed: ${job.closedDate}',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).hintColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    StatusBadge(label: job.status),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                  if (_canEdit && parsedId != null) ...[
                    const SizedBox(height: 12),
                    BottomSafeArea(
                      child: AppButton(
                        label: 'Delete Technician',
                        variant: AppButtonVariant.danger,
                        expanded: true,
                        onPressed: () async {
                          final confirmed = await showConfirmDialog(
                            context,
                            title: 'Delete Technician',
                            body:
                                'This will permanently remove ${tech.name}. This cannot be undone.',
                            confirmLabel: 'Delete',
                            confirmVariant: AppButtonVariant.danger,
                          );
                          if (!confirmed || !context.mounted) return;
                          try {
                            await ref
                                .read(techniciansProvider.notifier)
                                .delete(tech.id);
                            if (!context.mounted) return;
                            context.go('/technicians');
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
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.tech});

  final Technician tech;

  @override
  Widget build(BuildContext context) {
    final initials = tech.avatar.isNotEmpty
        ? (tech.avatar.length <= 2 ? tech.avatar : tech.avatar.substring(0, 2))
        : initialsFromName(tech.name);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAvatar(initials: initials, size: AppAvatarSize.lg),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tech.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tech.specialization.isEmpty
                            ? 'Technician'
                            : tech.specialization,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusBadge(label: tech.status),
                          if (tech.email.isNotEmpty)
                            _MetaChip(
                              icon: Icons.mail_outline,
                              label: tech.email,
                              dark: true,
                            ),
                          if (tech.phone.isNotEmpty)
                            _MetaChip(
                              icon: Icons.phone_outlined,
                              label: tech.phone,
                              dark: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SummaryChip(
                  icon: Icons.star_outline,
                  label: 'Rating',
                  value: tech.rating.toStringAsFixed(1),
                ),
                _SummaryChip(
                  icon: Icons.work_outline,
                  label: 'Jobs',
                  value: tech.jobsCompleted.toString(),
                ),
                _SummaryChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Joined',
                  value: tech.joinDate ?? '—',
                ),
                if (tech.userId != 0)
                  _SummaryChip(
                    icon: Icons.badge_outlined,
                    label: 'User',
                    value: tech.userId.toString(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.tech});

  final Technician tech;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 720 ? 3 : 2;
    final items = [
      ('Jobs Completed', tech.jobsCompleted.toString()),
      ('Rating', tech.rating.toStringAsFixed(1)),
      ('Join Date', tech.joinDate ?? '—'),
      ('User ID', tech.userId == 0 ? '—' : tech.userId.toString()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.$1,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.$2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({
    required this.currentTab,
    required this.docsCount,
    required this.ratingsCount,
    required this.jobsCount,
    required this.onTabChanged,
  });

  final String currentTab;
  final int docsCount;
  final int ratingsCount;
  final int jobsCount;
  final ValueChanged<String> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('documents', 'Documents', docsCount),
      ('ratings', 'Ratings', ratingsCount),
      ('jobs', 'Recent Jobs', jobsCount),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTabChanged(tab.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: currentTab == tab.$1
                        ? Theme.of(context).cardColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tab.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: currentTab == tab.$1
                              ? null
                              : Theme.of(context).hintColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.$3.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: currentTab == tab.$1
                              ? AppColors.blue600
                              : Theme.of(context).hintColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.doc,
    required this.canEdit,
    this.onOpen,
    this.onEdit,
    this.onDelete,
  });

  final TechnicianDocument doc;
  final bool canEdit;
  final VoidCallback? onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.documentName.isNotEmpty ? doc.documentName : doc.fileName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (doc.documentType.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        doc.documentType,
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ],
                  ],
                ),
              ),
              if (doc.expiryStatus.isNotEmpty) StatusBadge(label: doc.expiryStatus),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (doc.fileName.isNotEmpty)
                _MetaChip(
                  icon: Icons.insert_drive_file_outlined,
                  label: doc.fileName,
                ),
              if (doc.expiryDate != null && doc.expiryDate!.isNotEmpty)
                _MetaChip(
                  icon: Icons.event_outlined,
                  label: doc.expiryDate!,
                ),
              if (doc.mimeType.isNotEmpty)
                _MetaChip(
                  icon: Icons.description_outlined,
                  label: doc.mimeType,
                ),
            ],
          ),
          if (doc.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              doc.notes,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onOpen != null)
                AppButton(
                  label: 'Open File',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  leading: const Icon(Icons.open_in_new_outlined),
                  onPressed: onOpen,
                ),
              if (canEdit && onEdit != null)
                AppButton(
                  label: 'Edit',
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.sm,
                  leading: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
              if (canEdit && onDelete != null)
                AppButton(
                  label: 'Delete',
                  variant: AppButtonVariant.danger,
                  size: AppButtonSize.sm,
                  leading: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.rating,
    required this.canEdit,
    this.onEdit,
    this.onDelete,
  });

  final TechnicianRating rating;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final value = rating.rating;
    final createdAt = rating.createdAt;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...List.generate(5, (index) {
                      final star = index + 1;
                      return Icon(
                        Icons.star,
                        size: 16,
                        color: value >= star
                            ? Colors.amber.shade600
                            : Colors.grey.shade300,
                      );
                    }),
                    Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue600,
                      ),
                    ),
                    if (rating.jobId.isNotEmpty)
                      Text(
                        rating.jobId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppColors.gray400,
                        ),
                      ),
                  ],
                ),
              ),
              if (canEdit)
                Wrap(
                  spacing: 4,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        tooltip: 'Edit rating',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    if (onDelete != null)
                      IconButton(
                        tooltip: 'Delete rating',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
            ],
          ),
          if (rating.review.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(rating.review),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (rating.ratedByName.isNotEmpty)
                _MetaChip(
                  icon: Icons.person_outline,
                  label: rating.ratedByName,
                ),
              if (createdAt case final value?)
                _MetaChip(
                  icon: Icons.event_outlined,
                  label: value,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.dark = false});

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.08)
            : Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF111827)
            : AppColors.gray50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.12)
              : Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: dark ? Colors.white70 : AppColors.gray400,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: dark ? Colors.white : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.subtitle,
    this.action = const SizedBox.shrink(),
  });

  final String title;
  final String? subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        action,
      ],
    );
  }
}

class _TechnicianDetailSkeleton extends StatelessWidget {
  const _TechnicianDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCard(
            child: Row(
              children: [
                ShimmerBox(width: 56, height: 56, borderRadius: 999),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 160, height: 16, borderRadius: 8),
                      SizedBox(height: 8),
                      ShimmerBox(width: 120, height: 12, borderRadius: 8),
                      SizedBox(height: 8),
                      ShimmerBox(width: 220, height: 12, borderRadius: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: 4,
            itemBuilder: (context, index) =>
                const AppCard(child: ShimmerBox(height: 50, borderRadius: 12)),
          ),
          const SizedBox(height: 16),
          const ShimmerBox(height: 18, width: 140, borderRadius: 8),
          const SizedBox(height: 8),
          const AppCard(
            child: Column(
              children: [
                ShimmerBox(height: 56, borderRadius: 14),
                SizedBox(height: 12),
                ShimmerBox(height: 56, borderRadius: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
