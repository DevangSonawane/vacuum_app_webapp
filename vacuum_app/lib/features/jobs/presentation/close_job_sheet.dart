import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';

class CloseJobSheet extends StatefulWidget {
  const CloseJobSheet({
    super.key,
    required this.jobId,
    required this.title,
    required this.onClose,
  });

  final String jobId;
  final String title;
  final Future<void> Function(List<({String path, String name})> files) onClose;

  @override
  State<CloseJobSheet> createState() => _CloseJobSheetState();
}

class _CloseJobSheetState extends State<CloseJobSheet> {
  final _picker = ImagePicker();
  final List<XFile> _files = [];
  bool _loading = false;

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
    setState(() => _loading = true);
    await widget.onClose([for (final f in _files) (path: f.path, name: f.name)]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
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
              'Close Job — Add Verification Photos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt_outlined, color: AppColors.amber500),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Upload completion photos before closing. You can close without photos if needed.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.work_outline, color: AppColors.blue600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.jobId,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            color: AppColors.blue600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(widget.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Add Photos',
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
                itemBuilder: (context, i) {
                  final f = _files[i];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(f.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image_outlined)),
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
                  );
                },
              )
            else
              Text('No photos selected', style: TextStyle(color: Theme.of(context).hintColor)),
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
                    label: 'Close Job',
                    expanded: true,
                    loading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

