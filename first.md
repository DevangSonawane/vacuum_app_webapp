# VDTI Flutter — Full Feature Parity: Continuation Prompt

> **Context:** The foundation is already built and compiling. This prompt continues from exactly where the previous pass stopped. Do NOT re-implement what already exists — extend it.

---

## What Already Exists (DO NOT REWRITE)

The following files are complete and working. Reference them; do not touch them unless a specific fix is listed below:

| File | Status |
|---|---|
| `lib/main.dart` | ✅ Complete |
| `lib/core/constants/app_colors.dart` | ✅ Complete |
| `lib/core/constants/app_constants.dart` | ✅ Complete |
| `lib/core/network/api_client.dart` | ✅ Complete (Dio + Bearer token interceptor) |
| `lib/core/router/app_router.dart` | ✅ Complete (has `/jobs/:id` stub route) |
| `lib/core/storage/secure_token_storage.dart` | ✅ Complete |
| `lib/core/theme/app_theme.dart` | ✅ Complete (DM Sans body + Syne display) |
| `lib/core/ui/app_settings_notifier.dart` | ✅ Complete |
| `lib/core/ui/ui_providers.dart` | ✅ Complete |
| `lib/core/utils/initials.dart` | ✅ Complete |
| `lib/core/utils/revenue.dart` | ✅ Complete (`fmtRevenue`) |
| `lib/features/auth/**` | ✅ Complete (login tabs, forgot pw 2-step, notifier, repository, domain) |
| `lib/features/dashboard/**` | ✅ Complete (live API, bar/donut/line charts, stat cards, recent jobs table) |
| `lib/features/shell/presentation/app_shell.dart` | ✅ Complete (overflow-safe TopBar, drawer sidebar, nav items) |
| `lib/features/users/**` | ✅ Complete (list, pagination, DataTable) |
| `lib/shared/widgets/app_avatar.dart` | ✅ Complete |
| `lib/shared/widgets/app_button.dart` | ✅ Complete |
| `lib/shared/widgets/app_card.dart` | ✅ Complete |
| `lib/shared/widgets/app_input.dart` | ✅ Complete |
| `lib/shared/widgets/app_toast.dart` | ✅ Complete |
| `lib/shared/widgets/confirm_dialog.dart` | ✅ Complete |
| `lib/shared/widgets/empty_state.dart` | ✅ Complete |
| `lib/shared/widgets/page_loader.dart` | ✅ Complete |
| `lib/shared/widgets/section_header.dart` | ✅ Complete |
| `lib/shared/widgets/shimmer_box.dart` | ✅ Complete |
| `lib/shared/widgets/stat_card.dart` | ✅ Complete |
| `lib/shared/widgets/status_badge.dart` | ✅ Complete |

**All routes in `app_router.dart` are defined but most point to `SimplePage` stubs. Replace each stub with the real screen as described below.**

---

## Existing Patterns to Follow (copy these exactly)

### Repository pattern
```dart
// Every repository takes Dio injected via dioProvider
class XxxRepository {
  XxxRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;
  
  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }
  static List<dynamic> _asList(Object? v) => v is List ? v : const [];
  static int _asInt(Object? v) { ... }
  static num _asNum(Object? v) { ... }
}
```

### Notifier pattern
```dart
final xxxProvider = AsyncNotifierProvider<XxxNotifier, XxxState>(XxxNotifier.new);

class XxxNotifier extends AsyncNotifier<XxxState> {
  @override
  Future<XxxState> build() async => _fetch();
  
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }
}
```

### Provider registration
```dart
final xxxRepositoryProvider = Provider<XxxRepository>((ref) {
  return XxxRepository(dio: ref.read(dioProvider));
});
```

### API error display
```dart
// In screen's .when():
error: (error, _) => EmptyState(
  icon: Icons.error_outline,
  title: 'Failed to load',
  description: error.toString(),
),
```

### Toast calls
```dart
AppToast.show(context, message: '...', type: AppToastType.success); // or .error / .info
```

### Confirm before delete
```dart
final confirmed = await showConfirmDialog(
  context,
  title: 'Confirm Delete',
  body: 'This cannot be undone.',
  confirmLabel: 'Delete',
  confirmVariant: AppButtonVariant.danger,
);
if (confirmed && context.mounted) { ... }
```

### Skeleton loading pattern
```dart
// Use ShimmerBox(height: X, width: Y, borderRadius: Z)
// Inside AppCard for card-shaped skeletons
// Inside GridView/ListView for grid/list skeletons
```

---

## API Base URL
All endpoints are relative to: `https://vaccumapi-production.up.railway.app/api`
The `dioProvider` Dio instance already has this as `baseUrl` and injects the token automatically.

---

## Implementation Order (priority order)

1. Technicians — full CRUD
2. Clients — full CRUD + detail
3. Jobs — list + kanban + raise + close verification + detail page
4. Reports — list + submit + approve/reject + detail page
5. AMC Contracts — full CRUD
6. Quotations — full CRUD
7. Attendance — table view
8. Activity History — log list
9. Profile screen
10. Settings screen

---

## PART 1 — Technicians Feature

**Create these files:**
- `lib/features/technicians/domain/technician.dart`
- `lib/features/technicians/data/technicians_repository.dart`
- `lib/features/technicians/application/technicians_notifier.dart`
- `lib/features/technicians/presentation/technicians_screen.dart`

**Update router:** Replace `SimplePage(title: 'Technicians')` with `TechniciansScreen()`

---

### 1a. Domain Model

```dart
// lib/features/technicians/domain/technician.dart

class Technician {
  const Technician({
    required this.id,
    required this.name,
    required this.phone,
    required this.specialization,
    required this.status,
    required this.email,
    required this.joinDate,
    required this.jobsCompleted,
    required this.rating,
  });

  final int id;
  final String name;
  final String phone;
  final String specialization;
  final String status; // Active | On Leave | Inactive
  final String email;
  final String? joinDate;
  final int jobsCompleted;
  final double rating;

  static Technician fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : v.toString();
    int i(dynamic v) { if (v is int) return v; if (v is num) return v.toInt(); return int.tryParse(s(v)) ?? 0; }
    double d(dynamic v) { if (v is double) return v; if (v is num) return v.toDouble(); return double.tryParse(s(v)) ?? 0.0; }

    return Technician(
      id: i(json['id']),
      name: s(json['name']),
      phone: s(json['phone']),
      specialization: s(json['specialization']),
      status: s(json['status'].isEmpty ? 'Active' : json['status']),
      email: s(json['email']),
      joinDate: json['join_date']?.toString(),
      jobsCompleted: i(json['jobs_completed']),
      rating: d(json['rating']),
    );
  }

  Map<String, dynamic> toCreatePayload() => {
    'name': name,
    'phone': phone,
    'specialization': specialization,
    'status': status,
    if (email.isNotEmpty) 'email': email,
    if (joinDate != null && joinDate!.isNotEmpty) 'join_date': joinDate,
  };

  Map<String, dynamic> toUpdatePayload() => {
    'name': name,
    'phone': phone,
    'specialization': specialization,
    'status': status,
    if (email.isNotEmpty) 'email': email,
    if (joinDate != null && joinDate!.isNotEmpty) 'join_date': joinDate,
  };
}
```

---

### 1b. Repository

```dart
// lib/features/technicians/data/technicians_repository.dart

import 'package:dio/dio.dart';
import '../domain/technician.dart';

class TechniciansRepository {
  TechniciansRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<List<Technician>> fetchTechnicians({String search = ''}) async {
    final response = await _dio.get(
      '/technicians',
      queryParameters: {
        'limit': 50,
        if (search.isNotEmpty) 'search': search,
      },
    );
    final data = _asMap(response.data);
    final list = _asList(data['data']);
    return list
        .whereType<Map>()
        .map((e) => Technician.fromJson(e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  Future<Technician> fetchById(int id) async {
    final response = await _dio.get('/technicians/$id');
    final data = _asMap(_asMap(response.data)['data']);
    return Technician.fromJson(data);
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await _dio.post('/technicians', data: payload);
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    await _dio.put('/technicians/$id', data: payload);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/technicians/$id');
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return {};
  }
  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}
```

---

### 1c. Notifier & State

```dart
// lib/features/technicians/application/technicians_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/technicians_repository.dart';
import '../domain/technician.dart';

final techniciansRepositoryProvider = Provider<TechniciansRepository>((ref) =>
    TechniciansRepository(dio: ref.read(dioProvider)));

class TechniciansState {
  const TechniciansState({required this.items, this.search = ''});
  final List<Technician> items;
  final String search;
  TechniciansState copyWith({List<Technician>? items, String? search}) =>
      TechniciansState(items: items ?? this.items, search: search ?? this.search);
}

final techniciansProvider =
    AsyncNotifierProvider<TechniciansNotifier, TechniciansState>(TechniciansNotifier.new);

class TechniciansNotifier extends AsyncNotifier<TechniciansState> {
  TechniciansRepository get _repo => ref.read(techniciansRepositoryProvider);

  @override
  Future<TechniciansState> build() async {
    final items = await _repo.fetchTechnicians();
    return TechniciansState(items: items);
  }

  Future<void> search(String query) async {
    final current = state.valueOrNull ?? const TechniciansState(items: []);
    state = AsyncData(current.copyWith(search: query));
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchTechnicians(search: query);
      return TechniciansState(items: items, search: query);
    });
  }

  Future<void> refresh() async {
    final search = state.valueOrNull?.search ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchTechnicians(search: search);
      return TechniciansState(items: items, search: search);
    });
  }

  Future<bool> create(Map<String, dynamic> payload) async {
    try {
      await _repo.create(payload);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(int id, Map<String, dynamic> payload) async {
    try {
      await _repo.update(id, payload);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _repo.delete(id);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Technician?> fetchById(int id) async {
    try {
      return await _repo.fetchById(id);
    } catch (_) {
      return null;
    }
  }
}
```

---

### 1d. Technicians Screen

**React mobile reference:** Grid of cards (1 col mobile, 2 col tablet, 3 col desktop), each card showing avatar + name + specialization + status badge + contact details + 3 mini-stat boxes + Edit/Delete buttons. Search bar at top. Shimmer skeleton while loading.

```dart
// lib/features/technicians/presentation/technicians_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/technicians_notifier.dart';
import '../domain/technician.dart';

// --- Dropdown options ---
const _specializations = ['HVAC', 'Electrical', 'Plumbing', 'Carpentry', 'Generator', 'Civil', 'IT'];
const _statuses = ['Active', 'On Leave', 'Inactive'];

class TechniciansScreen extends ConsumerStatefulWidget {
  const TechniciansScreen({super.key});
  @override
  ConsumerState<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends ConsumerState<TechniciansScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(techniciansProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canEdit = !['technician', 'labour'].contains(role);
    final state = ref.watch(techniciansProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(techniciansProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Technicians',
              subtitle: state.whenOrNull(data: (d) =>
                  '${d.items.where((t) => t.status == "Active").length} active of ${d.items.length} total'),
              action: canEdit
                  ? AppButton(
                      label: '+ Add Technician',
                      onPressed: () => _openFormSheet(context, null, canEdit),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            // Search bar
            TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: 'Search technicians...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            state.when(
              loading: () => _TechniciansSkeleton(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load',
                description: e.toString(),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  return EmptyState(
                    icon: Icons.engineering_outlined,
                    title: 'No technicians found',
                    description: 'Try a different search or add a new technician.',
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
                    childAspectRatio: cols == 1 ? 2.0 : 1.4,
                  ),
                  itemCount: data.items.length,
                  itemBuilder: (context, i) => _TechnicianCard(
                    tech: data.items[i],
                    canEdit: canEdit,
                    onEdit: () => _openFormSheet(context, data.items[i], canEdit),
                    onDelete: () => _confirmDelete(context, data.items[i]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFormSheet(BuildContext context, Technician? tech, bool canEdit) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => _TechnicianFormSheet(
        existing: tech,
        onSubmit: (payload, isEdit, id, password) async {
          bool ok;
          if (isEdit && id != null) {
            ok = await ref.read(techniciansProvider.notifier).update(id, payload);
          } else {
            if (password.isNotEmpty) payload['password'] = password;
            ok = await ref.read(techniciansProvider.notifier).create(payload);
          }
          if (context.mounted) {
            Navigator.of(ctx).pop();
            AppToast.show(
              context,
              message: ok ? (isEdit ? 'Technician updated!' : 'Technician added!') : 'Operation failed',
              type: ok ? AppToastType.success : AppToastType.error,
            );
          }
        },
        fetchById: tech != null
            ? () => ref.read(techniciansProvider.notifier).fetchById(tech.id)
            : null,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Technician tech) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Technician',
      body: 'Are you sure you want to remove ${tech.name}? This cannot be undone.',
      confirmLabel: 'Remove',
    );
    if (confirmed && context.mounted) {
      final ok = await ref.read(techniciansProvider.notifier).delete(tech.id);
      if (context.mounted) {
        AppToast.show(
          context,
          message: ok ? 'Technician removed' : 'Delete failed',
          type: ok ? AppToastType.error : AppToastType.error,
        );
      }
    }
  }
}

// --- Technician Card ---

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({
    required this.tech,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final Technician tech;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBg = isDark ? const Color(0xFF111827) : AppColors.gray50;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: avatar + name + status
          Row(
            children: [
              AppAvatar(initials: initialsFromName(tech.name), size: AppAvatarSize.lg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tech.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tech.specialization,
                      style: const TextStyle(color: AppColors.blue600, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusBadge(label: tech.status),
            ],
          ),
          const SizedBox(height: 10),
          // Contact info
          if (tech.email.isNotEmpty)
            _ContactRow(icon: Icons.mail_outline, text: tech.email),
          _ContactRow(icon: Icons.phone_outlined, text: tech.phone),
          const SizedBox(height: 10),
          // Mini stats
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'Jobs', value: tech.jobsCompleted.toString(), bg: boxBg)),
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
            const SizedBox(height: 10),
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
                const SizedBox(width: 8),
                AppButton(
                  label: '',
                  variant: AppButtonVariant.danger,
                  size: AppButtonSize.sm,
                  leading: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
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
  const _MiniStat({required this.label, required this.value, required this.bg, this.valueColor});
  final String label;
  final String value;
  final Color bg;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: valueColor),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
        ],
      ),
    );
  }
}

// --- Technician Form Bottom Sheet ---

class _TechnicianFormSheet extends ConsumerStatefulWidget {
  const _TechnicianFormSheet({
    required this.onSubmit,
    this.existing,
    this.fetchById,
  });

  final Technician? existing;
  final Future<Technician?> Function()? fetchById;
  final Future<void> Function(
    Map<String, dynamic> payload,
    bool isEdit,
    int? id,
    String password,
  ) onSubmit;

  @override
  ConsumerState<_TechnicianFormSheet> createState() => _TechnicianFormSheetState();
}

class _TechnicianFormSheetState extends ConsumerState<_TechnicianFormSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String _specialization = _specializations.first;
  String _status = 'Active';
  DateTime? _joinDate;
  bool _loading = false;
  bool _fetchingDetails = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _name.text = t.name;
      _email.text = t.email;
      _phone.text = t.phone;
      _specialization = _specializations.contains(t.specialization) ? t.specialization : _specializations.first;
      _status = _statuses.contains(t.status) ? t.status : 'Active';
      if (t.joinDate != null) _joinDate = DateTime.tryParse(t.joinDate!);
      _loadFreshDetails();
    }
  }

  Future<void> _loadFreshDetails() async {
    if (widget.fetchById == null) return;
    setState(() => _fetchingDetails = true);
    final fresh = await widget.fetchById!();
    if (fresh != null && mounted) {
      setState(() {
        _name.text = fresh.name;
        _email.text = fresh.email;
        _phone.text = fresh.phone;
        _specialization = _specializations.contains(fresh.specialization) ? fresh.specialization : _specializations.first;
        _status = _statuses.contains(fresh.status) ? fresh.status : 'Active';
        if (fresh.joinDate != null) _joinDate = DateTime.tryParse(fresh.joinDate!);
        _fetchingDetails = false;
      });
    } else if (mounted) {
      setState(() => _fetchingDetails = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'specialization': _specialization,
      'status': _status,
      if (_email.text.trim().isNotEmpty) 'email': _email.text.trim().toLowerCase(),
      if (_joinDate != null) 'join_date': _joinDate!.toIso8601String().substring(0, 10),
    };
    await widget.onSubmit(payload, widget.existing != null, widget.existing?.id, _password.text);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Technician' : 'Add Technician',
              style: Theme.of(context).textTheme.titleMedium,
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
              _field('Full Name *', _name, hint: 'Ravi Kumar'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field('Email', _email, hint: 'ravi@vdti.com', keyboard: TextInputType.emailAddress)),
                const SizedBox(width: 12),
                Expanded(child: _field('Phone *', _phone, hint: '9876543210', keyboard: TextInputType.phone)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _dropdown('Specialization', _specialization, _specializations, (v) => setState(() => _specialization = v!))),
                const SizedBox(width: 12),
                Expanded(child: _dropdown('Status', _status, _statuses, (v) => setState(() => _status = v!))),
              ]),
              const SizedBox(height: 12),
              _datePicker(context),
              if (!isEdit) ...[
                const SizedBox(height: 12),
                _field('Password (optional)', _password, hint: 'Leave blank if no login needed', obscure: true),
                const SizedBox(height: 4),
                Text(
                  'If provided, this technician can log in via the mobile app.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                ),
              ],
              const SizedBox(height: 20),
              Row(children: [
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
                    label: isEdit ? 'Update Technician' : 'Add Technician',
                    expanded: true,
                    loading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, TextInputType? keyboard, bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          obscureText: obscure,
          enabled: !_loading,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _dropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(isDense: true),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: _loading ? null : onChanged,
        ),
      ],
    );
  }

  Widget _datePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Join Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _loading
              ? null
              : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _joinDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _joinDate = picked);
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray200),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.gray50,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.gray400),
                const SizedBox(width: 8),
                Text(
                  _joinDate != null ? _joinDate!.toIso8601String().substring(0, 10) : 'Select date',
                  style: TextStyle(color: _joinDate != null ? null : AppColors.gray400),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- Skeleton ---

class _TechniciansSkeleton extends StatelessWidget {
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
        childAspectRatio: cols == 1 ? 2.0 : 1.4,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const ShimmerBox(height: 48, width: 48, borderRadius: 24),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const ShimmerBox(height: 14, width: 120, borderRadius: 8),
                const SizedBox(height: 6),
                const ShimmerBox(height: 11, width: 80, borderRadius: 6),
              ])),
            ]),
            const SizedBox(height: 10),
            const ShimmerBox(height: 10, borderRadius: 6),
            const SizedBox(height: 6),
            const ShimmerBox(height: 10, width: 120, borderRadius: 6),
            const SizedBox(height: 10),
            Row(children: const [
              Expanded(child: ShimmerBox(height: 40, borderRadius: 10)),
              SizedBox(width: 8),
              Expanded(child: ShimmerBox(height: 40, borderRadius: 10)),
              SizedBox(width: 8),
              Expanded(child: ShimmerBox(height: 40, borderRadius: 10)),
            ]),
          ],
        ),
      ),
    );
  }
}
```

---

## PART 2 — Clients Feature

**Create:**
- `lib/features/clients/domain/client.dart`
- `lib/features/clients/data/clients_repository.dart`
- `lib/features/clients/application/clients_notifier.dart`
- `lib/features/clients/presentation/clients_screen.dart`

**Update router:** Replace `SimplePage(title: 'Clients')` → `ClientsScreen()`

### 2a. Domain Model

```dart
// lib/features/clients/domain/client.dart

class Client {
  const Client({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.address,
    required this.type,
    required this.status,
    required this.contractValue,
    required this.joinDate,
    this.stats,
  });

  final int id;
  final String name;
  final String contactPerson;
  final String email;
  final String phone;
  final String address;
  final String type; // Corporate | Residential | Commercial | Healthcare | Government
  final String status; // Active | Inactive
  final num contractValue;
  final String? joinDate;
  final ClientStats? stats;

  static Client fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : v.toString();
    num n(dynamic v) { if (v is num) return v; return num.tryParse(s(v)) ?? 0; }

    return Client(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: s(json['name']),
      contactPerson: s(json['contact_person']),
      email: s(json['email']),
      phone: s(json['phone']),
      address: s(json['address']),
      type: s(json['type'].isEmpty ? 'Corporate' : json['type']),
      status: s(json['status'].isEmpty ? 'Active' : json['status']),
      contractValue: n(json['contract_value']),
      joinDate: json['join_date']?.toString(),
      stats: json['stats'] != null ? ClientStats.fromJson(_asMap(json['stats'])) : null,
    );
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return {};
  }

  Map<String, dynamic> toPayload() => {
    'name': name,
    'contact_person': contactPerson,
    'type': type,
    'status': status,
    if (email.isNotEmpty) 'email': email,
    if (phone.isNotEmpty) 'phone': phone,
    if (address.isNotEmpty) 'address': address,
    if (contractValue > 0) 'contract_value': contractValue,
  };
}

class ClientStats {
  const ClientStats({required this.totalJobs, required this.openJobs, required this.activeAmcCount});
  final int totalJobs;
  final int openJobs;
  final int activeAmcCount;

  static ClientStats fromJson(Map<String, dynamic> json) {
    int i(dynamic v) { if (v is int) return v; if (v is num) return v.toInt(); return 0; }
    return ClientStats(
      totalJobs: i(json['total_jobs']),
      openJobs: i(json['open_jobs']),
      activeAmcCount: i(json['active_amc_count']),
    );
  }
}
```

### 2b. Repository

```dart
// lib/features/clients/data/clients_repository.dart

import 'package:dio/dio.dart';
import '../domain/client.dart';

class ClientsRepository {
  ClientsRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<List<Client>> fetchClients({String search = '', String type = ''}) async {
    final response = await _dio.get('/clients', queryParameters: {
      'limit': 50,
      if (search.isNotEmpty) 'search': search,
      if (type.isNotEmpty && type != 'All') 'type': type,
    });
    final data = _asMap(response.data);
    return _asList(data['data'])
        .whereType<Map>()
        .map((e) => Client.fromJson(e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  Future<Client> fetchById(int id) async {
    final response = await _dio.get('/clients/$id');
    return Client.fromJson(_asMap(_asMap(response.data)['data']));
  }

  Future<void> create(Map<String, dynamic> payload) => _dio.post('/clients', data: payload);
  Future<void> update(int id, Map<String, dynamic> payload) => _dio.put('/clients/$id', data: payload);
  Future<void> delete(int id) => _dio.delete('/clients/$id');

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return {};
  }
  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}
```

### 2c. Notifier

```dart
// lib/features/clients/application/clients_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/clients_repository.dart';
import '../domain/client.dart';

final clientsRepositoryProvider = Provider<ClientsRepository>((ref) =>
    ClientsRepository(dio: ref.read(dioProvider)));

class ClientsState {
  const ClientsState({required this.items, this.search = '', this.typeFilter = 'All'});
  final List<Client> items;
  final String search;
  final String typeFilter;
  ClientsState copyWith({List<Client>? items, String? search, String? typeFilter}) =>
      ClientsState(items: items ?? this.items, search: search ?? this.search, typeFilter: typeFilter ?? this.typeFilter);
}

final clientsProvider = AsyncNotifierProvider<ClientsNotifier, ClientsState>(ClientsNotifier.new);

class ClientsNotifier extends AsyncNotifier<ClientsState> {
  ClientsRepository get _repo => ref.read(clientsRepositoryProvider);

  @override
  Future<ClientsState> build() async {
    final items = await _repo.fetchClients();
    return ClientsState(items: items);
  }

  Future<void> filter({String? search, String? type}) async {
    final current = state.valueOrNull ?? const ClientsState(items: []);
    final s = search ?? current.search;
    final t = type ?? current.typeFilter;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchClients(search: s, type: t);
      return ClientsState(items: items, search: s, typeFilter: t);
    });
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ?? const ClientsState(items: []);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchClients(search: current.search, type: current.typeFilter);
      return ClientsState(items: items, search: current.search, typeFilter: current.typeFilter);
    });
  }

  Future<Client?> fetchDetail(int id) async {
    try { return await _repo.fetchById(id); } catch (_) { return null; }
  }
  Future<bool> create(Map<String, dynamic> p) async { try { await _repo.create(p); await refresh(); return true; } catch (_) { return false; } }
  Future<bool> update(int id, Map<String, dynamic> p) async { try { await _repo.update(id, p); await refresh(); return true; } catch (_) { return false; } }
  Future<bool> delete(int id) async { try { await _repo.delete(id); await refresh(); return true; } catch (_) { return false; } }
}
```

### 2d. Clients Screen

**Spec:** List of client cards (1 col mobile, 2 col tablet). Each card: building icon box (blue gradient 44×44) + company name + contact person + status badge + type chip + email/phone/address rows + contract value + since date + edit/delete buttons. Type filter chips horizontally scrollable. Tapping a card shows a detail bottom sheet (on mobile) with stats from `GET /clients/:id`.

```dart
// lib/features/clients/presentation/clients_screen.dart
// Implement the full screen following the EXACT same pattern as TechniciansScreen.
// Key differences from Technicians:

// TYPE CHIP COLORS:
const _typeColors = <String, (Color, Color)>{
  'Corporate':   (Color(0xFFDBEAFE), Color(0xFF1E40AF)),
  'Residential': (Color(0xFFD1FAE5), Color(0xFF065F46)),
  'Commercial':  (Color(0xFFF3E8FF), Color(0xFF6B21A8)),
  'Healthcare':  (Color(0xFFFEE2E2), Color(0xFF991B1B)),
  'Government':  (Color(0xFFFEF3C7), Color(0xFF92400E)),
};

const _clientTypes = ['All', 'Corporate', 'Residential', 'Commercial', 'Healthcare', 'Government'];
const _clientStatuses = ['Active', 'Inactive'];

// CARD LAYOUT (inside AppCard):
// Row [BuildingIcon box (44×44, blue gradient, 12dp radius) | name + contactPerson | StatusBadge + TypeChip]
// contact rows (email, phone, address) with icons
// Divider
// Row [contractValue bold | since date | edit/delete buttons]

// CLIENT DETAIL BOTTOM SHEET (on card tap):
// Gradient header (blue-600 → blue-800): BuildingIcon + name + contactPerson + X button
// Stats row (3 boxes): Total Jobs | Open Jobs | Active AMC  (loaded from GET /clients/:id)
// Contact section (email, phone, address with icon boxes)
// Contract section (value + since date, 2 boxes)
// [canEdit] Edit + Delete buttons

// API CALLS:
// List: GET /api/clients?limit=50&search=...&type=...
// Detail: GET /api/clients/:id → { stats: { total_jobs, open_jobs, active_amc_count }, ...client }
// Create: POST /api/clients { name, contact_person, type, status, email?, phone?, address?, contract_value? }
// Update: PUT /api/clients/:id (same payload)
// Delete: DELETE /api/clients/:id

// FORM FIELDS:
// Company Name*, Contact Person*, Email, Phone
// Contract Value (₹, number), Type dropdown, Status dropdown
// Address (full width)
```

---

## PART 3 — Jobs Feature

**Create:**
- `lib/features/jobs/domain/job.dart`
- `lib/features/jobs/data/jobs_repository.dart`
- `lib/features/jobs/application/jobs_notifier.dart`
- `lib/features/jobs/presentation/jobs_screen.dart`
- `lib/features/jobs/presentation/job_detail_screen.dart`

**Update router:**
- `'/jobs'` → `JobsScreen()`
- `'/jobs/:id'` → `JobDetailScreen(id: state.pathParameters['id']!)`

### 3a. Domain Model

```dart
// lib/features/jobs/domain/job.dart

class Job {
  const Job({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.category,
    required this.clientName,
    required this.technicianName,
    required this.amount,
    required this.raisedDate,
    required this.scheduledDate,
    required this.closedDate,
    required this.description,
    this.clientId,
    this.technicianId,
    this.images = const [],
    this.reports = const [],
  });

  final String id;
  final String title;
  final String status;   // Raised | Assigned | In Progress | Closed
  final String priority; // Low | Medium | High | Critical
  final String category;
  final String clientName;
  final String technicianName;
  final num amount;
  final String? raisedDate;
  final String? scheduledDate;
  final String? closedDate;
  final String description;
  final int? clientId;
  final int? technicianId;
  final List<JobImage> images;
  final List<JobReport> reports;

  static Job fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : v.toString();
    num n(dynamic v) { if (v is num) return v; return num.tryParse(s(v)) ?? 0; }
    List<dynamic> l(dynamic v) => v is List ? v : const [];

    return Job(
      id: s(json['id']),
      title: s(json['title']),
      status: s(json['status']),
      priority: s(json['priority']),
      category: s(json['category']),
      clientName: s(json['client_name']),
      technicianName: s(json['technician_name']),
      amount: n(json['amount']),
      raisedDate: json['raised_date']?.toString(),
      scheduledDate: json['scheduled_date']?.toString(),
      closedDate: json['closed_date']?.toString(),
      description: s(json['description']),
      clientId: (json['client_id'] as num?)?.toInt(),
      technicianId: (json['technician_id'] as num?)?.toInt(),
      images: l(json['images']).whereType<Map>().map((e) => JobImage.fromJson(e.map((k, v) => MapEntry(k.toString(), v)))).toList(),
      reports: l(json['reports']).whereType<Map>().map((e) => JobReport.fromJson(e.map((k, v) => MapEntry(k.toString(), v)))).toList(),
    );
  }
}

class JobImage {
  const JobImage({required this.id, required this.fileUrl, required this.fileName});
  final int id;
  final String fileUrl;
  final String fileName;
  static JobImage fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : v.toString();
    return JobImage(id: (json['id'] as num?)?.toInt() ?? 0, fileUrl: s(json['file_url']), fileName: s(json['file_name']));
  }
}

class JobReport {
  const JobReport({required this.id, required this.title, required this.status});
  final String id;
  final String title;
  final String status;
  static JobReport fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : v.toString();
    return JobReport(id: s(json['id']), title: s(json['title']), status: s(json['status']));
  }
}
```

### 3b. Repository

```dart
// lib/features/jobs/data/jobs_repository.dart

import 'package:dio/dio.dart';
import '../domain/job.dart';

class JobsRepository {
  JobsRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<List<Job>> fetchJobs({String status = ''}) async {
    final response = await _dio.get('/jobs', queryParameters: {
      'limit': 100,
      if (status.isNotEmpty && status != 'All') 'status': status,
    });
    final data = _asMap(response.data);
    return _asList(data['data'])
        .whereType<Map>()
        .map((e) => Job.fromJson(e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  Future<Job> fetchById(String id) async {
    final response = await _dio.get('/jobs/$id');
    return Job.fromJson(_asMap(_asMap(response.data)['data']));
  }

  Future<void> create(Map<String, dynamic> payload) => _dio.post('/jobs', data: payload);

  Future<void> advanceStatus(String id, String newStatus) =>
      _dio.patch('/jobs/$id/status', data: {'status': newStatus});

  Future<String?> uploadImage(String jobId, String filePath, String filename) async {
    final formData = FormData.fromMap({
      'images': await MultipartFile.fromFile(filePath, filename: filename),
    });
    final response = await _dio.post(
      '/upload',
      queryParameters: {'entity_type': 'job', 'entity_id': jobId},
      data: formData,
    );
    final uploaded = _asList(_asMap(response.data)['data']);
    return uploaded.isNotEmpty ? _asMap(uploaded.first)['file_url']?.toString() : null;
  }

  Future<void> linkImage(String jobId, Map<String, dynamic> imageData) =>
      _dio.post('/jobs/$jobId/images', data: imageData);

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return {};
  }
  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}
```

### 3c. Notifier

```dart
// lib/features/jobs/application/jobs_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/jobs_repository.dart';
import '../domain/job.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) =>
    JobsRepository(dio: ref.read(dioProvider)));

class JobsState {
  const JobsState({required this.items, this.statusFilter = 'All'});
  final List<Job> items;
  final String statusFilter;
  JobsState copyWith({List<Job>? items, String? statusFilter}) =>
      JobsState(items: items ?? this.items, statusFilter: statusFilter ?? this.statusFilter);
}

final jobsProvider = AsyncNotifierProvider<JobsNotifier, JobsState>(JobsNotifier.new);

class JobsNotifier extends AsyncNotifier<JobsState> {
  JobsRepository get _repo => ref.read(jobsRepositoryProvider);

  @override
  Future<JobsState> build() async {
    final items = await _repo.fetchJobs();
    return JobsState(items: items);
  }

  Future<void> setFilter(String status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchJobs(status: status);
      return JobsState(items: items, statusFilter: status);
    });
  }

  Future<void> refresh() async {
    final filter = state.valueOrNull?.statusFilter ?? 'All';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchJobs(status: filter);
      return JobsState(items: items, statusFilter: filter);
    });
  }

  Future<bool> create(Map<String, dynamic> payload) async {
    try { await _repo.create(payload); await refresh(); return true; } catch (_) { return false; }
  }

  Future<bool> advanceStatus(String id, String next) async {
    try { await _repo.advanceStatus(id, next); await refresh(); return true; } catch (_) { return false; }
  }

  Future<Job?> fetchDetail(String id) async {
    try { return await _repo.fetchById(id); } catch (_) { return null; }
  }
}
```

### 3d. Jobs Screen

**Spec:**
- Filter tabs row: `All | Raised | Assigned | In Progress | Closed` with count badge on each non-All tab
- `filter == 'All'` → **Kanban view on mobile = 4 stacked vertical sections**, one per status. Each section has `[StatusBadge + count]` header then `Column` of `JobCard`s (vertical cards)
- `filter == status` → Vertical list of horizontal `JobCard`s
- `JobCard` (vertical): left border 4dp colored by status, shows ID (monospace blue), title, priority badge, client/technician/date rows
- `JobCard` (horizontal): ID + title + client in `Expanded` column, then `StatusBadge + ₹amount` on right
- Tap any card → `context.go('/jobs/${job.id}')`
- `[canRaise]` button → opens `_RaiseJobSheet`

**Status left-border colors:**
```dart
const _statusBorderColor = {
  'Raised':       Color(0xFFA855F7), // purple-500
  'Assigned':     Color(0xFF3B82F6), // blue-500
  'In Progress':  Color(0xFFF59E0B), // amber-500
  'Closed':       Color(0xFF10B981), // emerald-500
};
```

**Status section bg (light tint for section header/badge):**
```dart
const _statusBg = {
  'Raised':      (Color(0xFFF3E8FF), Color(0xFF6B21A8)),
  'Assigned':    (Color(0xFFDBEAFE), Color(0xFF1E40AF)),
  'In Progress': (Color(0xFFFEF3C7), Color(0xFF92400E)),
  'Closed':      (Color(0xFFD1FAE5), Color(0xFF065F46)),
};
```

**`_RaiseJobSheet` form fields:**
- Job Title* (full width)
- Client* dropdown (fetched from `GET /api/clients?limit=100`)
- Assign Technician dropdown (fetched from `GET /api/technicians?limit=100&status=Active`)
- Priority dropdown: `Low | Medium | High | Critical`
- Category dropdown: `Maintenance | Repair | Installation | Inspection`
- Scheduled Date (date picker)
- Amount ₹ (number)
- Description (multiline 3 rows)

**API payload for create:**
```json
{
  "title": "...",
  "client_id": 1,
  "priority": "Medium",
  "category": "Maintenance",
  "technician_id": 2,       // optional
  "description": "...",     // optional
  "scheduled_date": "...",  // optional
  "amount": 12000           // optional
}
```

```dart
// lib/features/jobs/presentation/jobs_screen.dart
// Implement full screen. Key structural points:

const _statuses = ['Raised', 'Assigned', 'In Progress', 'Closed'];
const _priorities = ['Low', 'Medium', 'High', 'Critical'];
const _categories = ['Maintenance', 'Repair', 'Installation', 'Inspection'];

// STATUS_FLOW for advancing:
const _statusFlow = {
  'Raised': 'Assigned',
  'Assigned': 'In Progress',
  'In Progress': 'Closed',  // special: opens close-verification sheet
};

// Advance status button in job card (only if canRaise and status != 'Closed'):
// - show small icon button or text button next to card
// - for 'In Progress' → open _CloseJobSheet
// - for others → call notifier.advanceStatus(job.id, next)

// CLOSE VERIFICATION SHEET:
// Use image_picker to pick images
// For each picked image: upload to /upload?entity_type=job&entity_id=X then link via POST /jobs/:id/images
// Show thumbnail grid with upload progress overlay
// "Close Job" button → after all uploads, PATCH /jobs/:id/status { status: 'Closed' }
// Warning banner (amber): "Upload completion photos before closing. You can close without photos if needed."
```

---

### 3e. Job Detail Screen

```dart
// lib/features/jobs/presentation/job_detail_screen.dart

// This screen is a full Scaffold (inside the ShellRoute).
// It loads the job via GET /api/jobs/:id

// LAYOUT (SingleChildScrollView):
// 1. Status-colored header card:
//    - job.id (monospace blue, small)
//    - job.title (bold 18)
//    - Wrap([StatusBadge, PriorityBadge, category chip])
//
// 2. 2×3 info grid (6 AppCard-like gray boxes):
//    Client | Technician | Amount(₹) | Raised date | Scheduled date | Closed date
//
// 3. [description] "Description" section header + body text
//
// 4. Pipeline stepper:
//    Row of [Raised → Assigned → In Progress → Closed]
//    Each stage: small box, blue-600 if completed/current, gray-100 if future
//    ArrowRight icon between stages
//
// 5. [images] "Verification Photos (N)" section + 3-col image grid
//    Each image: CachedNetworkImage or Image.network, aspect ratio 1:1, rounded
//
// 6. [reports] "Reports (N)" section + list of rows [id mono blue | title | StatusBadge]
//    Each row tappable → context.go('/reports/${r.id}')
//
// 7. Action area (bottom, full width):
//    [status == 'Closed']:   emerald chip "This job is closed."
//    [canRaise, In Progress]: "📷 Close Job with Verification" button → opens _CloseJobSheet
//    [canRaise, other open]:  "Advance to {next}" button → PATCH status

// AppBar: title = job.id (monospace), back button auto, leading icon

// Loading state: shimmer boxes for each section
// Error state: EmptyState widget

// CRITICAL: After advancing/closing, call context.pop() or refresh local state
```

---

## PART 4 — Reports Feature

**Create:**
- `lib/features/reports/domain/report.dart`
- `lib/features/reports/data/reports_repository.dart`
- `lib/features/reports/application/reports_notifier.dart`
- `lib/features/reports/presentation/reports_screen.dart`
- `lib/features/reports/presentation/report_detail_screen.dart`

**Update router:**
- `'/reports'` → `ReportsScreen()`
- Add `'/reports/:id'` → `ReportDetailScreen(id: state.pathParameters['id']!)`

### 4a. Domain

```dart
// lib/features/reports/domain/report.dart

class Report {
  const Report({
    required this.id,
    required this.title,
    required this.status,
    required this.jobId,
    required this.jobTitle,
    required this.clientName,
    required this.technicianName,
    required this.reportDate,
    required this.findings,
    required this.recommendations,
    required this.approvedAt,
    this.imageCount = 0,
    this.images = const [],
  });

  final String id;
  final String title;
  final String status; // Pending | Approved | Rejected
  final String jobId;
  final String jobTitle;
  final String clientName;
  final String technicianName;
  final String? reportDate;
  final String findings;
  final String recommendations;
  final String? approvedAt;
  final int imageCount;
  final List<ReportImage> images;

  static Report fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : v.toString();
    int i(dynamic v) { if (v is int) return v; if (v is num) return v.toInt(); return 0; }
    List<dynamic> l(dynamic v) => v is List ? v : const [];

    return Report(
      id: s(json['id']),
      title: s(json['title']),
      status: s(json['status']),
      jobId: s(json['job_id']),
      jobTitle: s(json['job_title']),
      clientName: s(json['client_name']),
      technicianName: s(json['technician_name']),
      reportDate: json['report_date']?.toString(),
      findings: s(json['findings']),
      recommendations: s(json['recommendations']),
      approvedAt: json['approved_at']?.toString(),
      imageCount: i(json['image_count']),
      images: l(json['images']).whereType<Map>().map((e) => ReportImage.fromJson(e.map((k, v) => MapEntry(k.toString(), v)))).toList(),
    );
  }
}

class ReportImage {
  const ReportImage({required this.id, required this.fileUrl, required this.fileName});
  final int id;
  final String fileUrl;
  final String fileName;
  static ReportImage fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : v.toString();
    return ReportImage(id: (json['id'] as num?)?.toInt() ?? 0, fileUrl: s(json['file_url']), fileName: s(json['file_name']));
  }
}
```

### 4b. Repository + Notifier

```dart
// lib/features/reports/data/reports_repository.dart
// Methods:
//   fetchReports({String status = ''}) → GET /reports?limit=100&status=...
//   fetchById(String id) → GET /reports/:id
//   create(Map payload) → POST /reports
//   updateStatus(String id, String status) → PATCH /reports/:id/status { status: status }
//   uploadImage(String reportId, String filePath, String filename) → POST /upload?entity_type=report&entity_id=:id
//   linkImage(String reportId, Map data) → POST /reports/:id/images

// lib/features/reports/application/reports_notifier.dart
// State: ReportsState { List<Report> items, String statusFilter }
// Methods: setFilter(String), refresh(), create(Map), updateStatus(String id, String status), fetchDetail(String id)
```

### 4c. Reports Screen

**Card layout:**
```
AppCard (tappable → push report detail)
├── Row [id mono blue | Spacer | StatusBadge]
├── title DM Sans Bold 14
├── clientName/jobTitle gray-500 12
├── [findings] gray-50 box (2 lines preview)
├── [imageCount > 0] Row [image icon, "${imageCount} photos"]
├── Divider
└── Row [technicianName · date | [admin+Pending] Approve/Reject icon buttons]
```

**Filter tabs:** `All | Pending | Approved | Rejected` with count badge

**New Report Bottom Sheet fields:**
- Linked Job* — searchable dropdown (`{id} — {title}`)
- Technician* — dropdown
- Report Title* 
- Findings — multiline 3 rows
- Recommendations — multiline 2 rows
- Attach Photos — upload zone + preview thumbnails (same pattern as close-job verification)

**API for create:**
```json
{
  "job_id": "JOB-001",
  "title": "...",
  "technician_id": 1,
  "findings": "...",
  "recommendations": "..."
}
```
After creation, upload images to `/upload?entity_type=report&entity_id=:id`, then link each via `POST /reports/:id/images`.

**Approve/Reject:** `PATCH /reports/:id/status { "status": "Approved" | "Rejected" }` — admin only.

### 4d. Report Detail Screen

Same pattern as Job Detail. Sections:
1. Gradient header (slate-700 → slate-900): id + title + StatusBadge
2. 2×3 info grid: Job | Job Title | Client | Technician | Date | Approved At
3. Findings section (gray-50 box, `whitespace-pre-wrap` equivalent)
4. Recommendations section (blue-50 box)
5. Photos grid (3 col, tap → open image URL in browser or full-screen viewer)
6. [admin + Pending]: Approve (emerald) + Reject (danger) buttons
7. [Approved]: emerald success banner
8. [Rejected]: red rejection banner

---

## PART 5 — AMC Contracts Feature

**Create:**
- `lib/features/amc/domain/amc_contract.dart`
- `lib/features/amc/data/amc_repository.dart`
- `lib/features/amc/application/amc_notifier.dart`
- `lib/features/amc/presentation/amc_screen.dart`

**Update router:** `'/amc'` → `AmcScreen()`

### 5a. Domain

```dart
// lib/features/amc/domain/amc_contract.dart

class AmcContract {
  const AmcContract({
    required this.id,
    required this.title,
    required this.clientId,
    required this.clientName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.value,
    required this.renewalReminderDays,
    required this.services,
    required this.nextServiceDate,
  });

  final String id;
  final String title;
  final int clientId;
  final String clientName;
  final String status; // Active | Expiring Soon | Expired
  final String? startDate;
  final String? endDate;
  final num value;
  final int renewalReminderDays;
  final List<String> services;
  final String? nextServiceDate;

  static AmcContract fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : v.toString();
    num n(dynamic v) { if (v is num) return v; return num.tryParse(s(v)) ?? 0; }
    int i(dynamic v) { if (v is int) return v; if (v is num) return v.toInt(); return 0; }
    List<dynamic> l(dynamic v) => v is List ? v : const [];

    return AmcContract(
      id: s(json['id']),
      title: s(json['title']),
      clientId: i(json['client_id']),
      clientName: s(json['client_name']),
      status: s(json['status']),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      value: n(json['value']),
      renewalReminderDays: i(json['renewal_reminder_days'] ?? 30),
      services: l(json['services']).map((e) => e.toString()).toList(),
      nextServiceDate: json['next_service_date']?.toString(),
    );
  }
}
```

### 5b. Screen Spec

**Card layout:**
```
AppCard
├── Row [gradient icon box (status gradient, 48×48, ShieldCheck icon) | Expanded [title bold, clientName gray] | StatusBadge]
├── 2×2 info grid: [Start: date | End: date | Value: ₹X | Reminder: X days]
├── [services] Wrap of service chips (gray-100 pills)
├── [nextServiceDate] calendar row
└── [canEdit] Row [Edit, Delete] buttons
```

**Status gradients:**
```dart
const _statusGrad = {
  'Active':         [Color(0xFF3B82F6), Color(0xFF2563EB)],  // blue
  'Expiring Soon':  [Color(0xFFF97316), Color(0xFFEA580C)],  // orange
  'Expired':        [Color(0xFF9CA3AF), Color(0xFF6B7280)],  // gray
};
```

**Filter tabs:** `All | Active | Expiring Soon | Expired`

**SectionHeader subtitle:** total contract value formatted with `fmtRevenue()`

**Form fields (create):**
- Client* dropdown
- Title*
- Start Date*, End Date*
- Value (₹)*
- Renewal Reminder Days (number, default 30)
- Services (comma-separated text → split on submit)
- Next Service Date

**API:**
- List: `GET /api/amc?limit=100&status=...`
- Detail: `GET /api/amc/:id`
- Create: `POST /api/amc { client_id, title, start_date, end_date, value, renewal_reminder_days, services[], next_service_date? }`
- Update: `PUT /api/amc/:id { title, end_date, value, renewal_reminder_days, services[], next_service_date? }`
- Delete: `DELETE /api/amc/:id`

---

## PART 6 — Quotations Feature

**Create:**
- `lib/features/quotations/domain/quotation.dart`
- `lib/features/quotations/data/quotations_repository.dart`
- `lib/features/quotations/application/quotations_notifier.dart`
- `lib/features/quotations/presentation/quotations_screen.dart`

**Update router:** `'/quotations'` → `QuotationsScreen()`

### 6a. Domain

```dart
class Quotation {
  final String id;
  final String title;
  final String clientName;
  final String status; // Pending | Approved | Rejected
  final num amount;
  final String? validTill;
  final String? createdDate;
  // items if returned
}
```

**Note:** The React quotations page uses mock data (AppContext). If the API doesn't have quotations endpoints yet, implement with the same mock-data approach using a `StateNotifier` instead of async API calls. Check if `GET /api/quotations` exists; if it returns 404, use local state seeded from mock data that matches the React mock.

**Card layout:**
```
AppCard (tappable)
├── Row [id mono blue | Spacer | StatusBadge]
├── title bold
├── clientName gray-500
├── Divider
└── Row [₹amount Syne Bold 22 blue-600, "Valid till date" | [canEdit+Pending] approve/reject icon buttons]
```

**New Quotation Sheet:**
- Client* dropdown
- Title*
- Valid Till (date picker)
- Line items (dynamic list):
  - Each row: Description | Qty (number) | Rate ₹ (number) | Total (auto-calculated)
  - "+ Add Item" button
- Total row: "Total: ₹X,XXX" bold

---

## PART 7 — Attendance Feature

**Create:**
- `lib/features/attendance/presentation/attendance_screen.dart`

**Update router:** `'/attendance'` → `AttendanceScreen()`

**Note:** The React attendance page uses mock data from `AppContext`. The Flutter version should call the API if a live endpoint exists (`GET /api/attendance?date=YYYY-MM-DD`), otherwise use a local state approach.

**Layout:**
```
SingleChildScrollView padding 16
├── SectionHeader("Attendance Tracking", "Daily check-in / check-out records")
│   action: [canEdit] AppButton("Mark Attendance")
├── 2-col StatCard grid (4 cards: Present | Late | Absent | Total Technicians)
├── SizedBox(16)
├── Row [Text("Date:"), SizedBox(8), date picker field]
├── SizedBox(16)
└── AppCard → attendance table
    Headers: Technician | Specialization | Check In | Check Out | Hours | Status
    SingleChildScrollView(horizontal) wrapping DataTable
    Each row: avatar+name | spec | times (monospace) | hours bold | StatusBadge
```

**CRITICAL:** Wrap `DataTable` in `SingleChildScrollView(scrollDirection: Axis.horizontal)` — this table WILL overflow on mobile without it.

---

## PART 8 — Activity History Feature

**Create:**
- `lib/features/activity/domain/activity_item.dart`
- `lib/features/activity/data/activity_repository.dart`
- `lib/features/activity/application/activity_notifier.dart`
- `lib/features/activity/presentation/activity_screen.dart`

**Update router:** `'/activity'` → `ActivityScreen()`

### 8a. Domain

```dart
class ActivityItem {
  final int id;
  final String type;    // job | client | report | technician | amc | user | email_settings
  final String action;
  final String user;
  final String? entityId;
  final String timestamp;
}
```

### 8b. Repository

```dart
// GET /api/activity?limit=50&type=... → list of activity log entries
Future<List<ActivityItem>> fetchActivity({String type = ''});
```

### 8c. Screen Layout

```
SingleChildScrollView
├── SectionHeader("Activity History") + Refresh button
├── Filter chips (horizontal scroll): All | job | client | report | technician | amc | user
├── SizedBox(12)
└── ListView.separated of ActivityRow widgets

ActivityRow:
Row
├── Container(36×36, 10dp radius, colored by type) → type icon inside
├── SizedBox(12)
├── Expanded Column
│   ├── action text (DM Sans SemiBold 14, ellipsis, maxLines 2)
│   ├── SizedBox(2)
│   ├── Row ["by ${user}" gray-500 12, Spacer, relativeTime gray-400 11]
└── [has entityId] Icon(chevron_right, gray-300)

TYPE ICON + COLOR MAP:
'job':           (Icons.work_outline,          Color(0xFFDBEAFE), Color(0xFF2563EB))
'client':        (Icons.groups_outlined,       Color(0xFFD1FAE5), Color(0xFF10B981))
'amc':           (Icons.verified_user_outlined, Color(0xFFF3E8FF), Color(0xFFA855F7))
'report':        (Icons.description_outlined,  Color(0xFFF3F4F6), Color(0xFF6B7280))
'technician':    (Icons.engineering_outlined,  Color(0xFFFEE2E2), Color(0xFFEF4444))
'user':          (Icons.person_outline,        Color(0xFFE0E7FF), Color(0xFF4F46E5))
'email_settings':(Icons.mail_outline,          Color(0xFFCFFAFE), Color(0xFF0891B2))
```

**Relative time helper:**
```dart
String relativeTime(String iso) {
  try {
    final diff = DateTime.now().difference(DateTime.parse(iso));
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  } catch (_) { return ''; }
}
```

---

## PART 9 — Profile Screen

**Create:** `lib/features/profile/presentation/profile_screen.dart`
**Update router:** `'/profile'` → `ProfileScreen()`

```
SingleChildScrollView padding 16
├── Row [title "My Profile" (Syne Bold 22), Spacer, AppButton("Edit Profile", outline, sm → go('/settings'))]
├── SizedBox(24)
└── [mobile: Column, tablet ≥600: Row] of:
    LEFT CARD (AppCard, centered content):
    ├── Container 96×96, blue-600, borderRadius 18, AppAvatar-like (initials from user.fullName)
    ├── SizedBox(12)
    ├── user.fullName Syne Bold 20
    ├── user.role (uppercase, blue-600, tracking-wide, 12)
    ├── Divider
    ├── Row [Text("Status") | Row[green dot, "Active" green]]
    └── Row [Text("Member since") | "2024"]

    RIGHT CARD (AppCard):
    "Personal Information" titleMedium
    2-col grid (mobile 1-col) of info items:
    [Email Address, Phone Number, Role, Joining Date]
    Each: label xs uppercase gray-400 + Icon box (gray-50, 12dp) + value DM Sans SemiBold
```

Data source: `ref.watch(authProvider).valueOrNull?.user` (the logged-in user from auth state).

---

## PART 10 — Settings Screen

**Create:** `lib/features/settings/presentation/settings_screen.dart`
**Update router:** `'/settings'` → `SettingsScreen()`

```
SingleChildScrollView padding 16
├── SectionHeader("Settings", "Manage your preferences and security")
├── SizedBox(16)
├── AppCard "Appearance"
│   ├── Row [Icon(settings) in blue-50 box, "Appearance" bold]
│   ├── SizedBox(8)
│   └── Container(gray-50 bg, 16dp radius, padding 16)
│       └── Row [Moon/Sun icon | "Dark Mode" label | Spacer | Switch]
│           Switch onChanged → ref.read(appSettingsProvider.notifier).toggleDarkMode()
│           Switch value → ref.watch(appSettingsProvider).valueOrNull ?? false
├── SizedBox(16)
└── AppCard "Security — Change Password"
    ├── Row [Lock icon in blue-50 box, "Change Password" bold]
    ├── SizedBox(16)
    ├── [success state]: emerald success banner
    ├── [form state]:
    │   AppInput("New Password", type:password, required)
    │   SizedBox(12)
    │   AppInput("Confirm Password", type:password, required)
    │   [mismatch]: Text "Passwords do not match" red
    │   SizedBox(12)
    │   AppButton("Update Password", expanded, disabled if mismatch or empty)
    └── [POST /api/auth/change-password { new_password, confirm_password }]
        OR use /api/auth/reset-password if change-password endpoint doesn't exist
```

---

## PART 11 — Router Updates

After implementing all screens, update `lib/core/router/app_router.dart`:

```dart
// Add these imports:
import '../../features/technicians/presentation/technicians_screen.dart';
import '../../features/clients/presentation/clients_screen.dart';
import '../../features/jobs/presentation/jobs_screen.dart';
import '../../features/jobs/presentation/job_detail_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/reports/presentation/report_detail_screen.dart';
import '../../features/amc/presentation/amc_screen.dart';
import '../../features/quotations/presentation/quotations_screen.dart';
import '../../features/attendance/presentation/attendance_screen.dart';
import '../../features/activity/presentation/activity_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

// Replace each SimplePage stub:
GoRoute(path: '/technicians', builder: (c, s) => const TechniciansScreen()),
GoRoute(path: '/clients',     builder: (c, s) => const ClientsScreen()),
GoRoute(path: '/jobs',        builder: (c, s) => const JobsScreen()),
GoRoute(path: '/jobs/:id',    builder: (c, s) => JobDetailScreen(id: s.pathParameters['id']!)),
GoRoute(path: '/reports',     builder: (c, s) => const ReportsScreen()),
GoRoute(path: '/reports/:id', builder: (c, s) => ReportDetailScreen(id: s.pathParameters['id']!)),
GoRoute(path: '/amc',         builder: (c, s) => const AmcScreen()),
GoRoute(path: '/quotations',  builder: (c, s) => const QuotationsScreen()),
GoRoute(path: '/attendance',  builder: (c, s) => const AttendanceScreen()),
GoRoute(path: '/activity',    builder: (c, s) => const ActivityScreen()),
GoRoute(path: '/profile',     builder: (c, s) => const ProfileScreen()),
GoRoute(path: '/settings',    builder: (c, s) => const SettingsScreen()),
```

Also add `/reports/:id` to the `adminOnly` guard exclusion (it's accessible to all authenticated users).

---

## PART 12 — Users Screen Completion

The existing `UsersScreen` renders a `DataTable` but Add User and Edit User buttons are no-ops. Complete them:

**Add to `UsersRepository`:**
```dart
Future<void> createUser(Map<String, dynamic> payload) => _dio.post('/users', data: payload);
Future<AppUser> fetchById(int id) async { ... GET /users/:id ... }
```

**Add to `UsersNotifier`:**
```dart
Future<bool> createUser(Map<String, dynamic> p) async { ... }
Future<bool> updateUser(int id, Map<String, dynamic> p) async { ... }
Future<bool> deactivate(int id) async { ... }
Future<AppUser?> fetchById(int id) async { ... }
```

**Add user form bottom sheet:** Same `DraggableScrollableSheet` pattern. Fields:
- First Name*, Last Name*
- Email (optional if phone given)
- Phone (optional if email given, +91 prefix)
- Role* dropdown: `admin | manager | engineer | technician | labour`
- Is Active toggle (Switch)
- Password* (create only)

**Wire up** the existing edit icon → open form sheet pre-filled (fetch by ID first)
**Wire up** the existing delete icon → `showConfirmDialog` → `notifier.deactivate(id)`
**Wire up** the "+ Add New User" button → open empty form sheet

---

## PART 13 — Required `pubspec.yaml` Dependencies

Ensure these are present (add any missing):
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.x
  go_router: ^14.x
  dio: ^5.x
  flutter_secure_storage: ^9.x
  shared_preferences: ^2.x
  google_fonts: ^6.x
  shimmer: ^3.x
  fl_chart: ^0.68.x
  image_picker: ^1.x
  cached_network_image: ^3.x
  intl: ^0.19.x
  characters: ^1.x
```

**Permissions to add in `android/app/src/main/AndroidManifest.xml`:**
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

**iOS `ios/Runner/Info.plist`:**
```xml
<key>NSCameraUsageDescription</key>
<string>Used to take verification photos for job completion</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to attach photos to service reports</string>
```

---

## PART 14 — Global Quality Rules

Apply to every screen without exception:

### Overflow prevention
```dart
// WRONG — will overflow:
Row(children: [Text(longString), Text(anotherLong)])

// CORRECT:
Row(children: [Expanded(child: Text(longString, overflow: TextOverflow.ellipsis)), Text(short)])
```

### Every card/list title
```dart
Text(title, overflow: TextOverflow.ellipsis, maxLines: 1)
// Or maxLines: 2 for descriptions
```

### Tables
```dart
// ALWAYS wrap DataTable in:
SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(...))
```

### GridView/ListView in Column
```dart
// ALWAYS use:
GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), ...)
// NEVER use without shrinkWrap inside SingleChildScrollView > Column
```

### BottomSheet safe area
```dart
// ALWAYS add padding for keyboard:
EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16)
```

### Dark mode colors
```dart
// ALWAYS check dark mode for custom colors:
final isDark = Theme.of(context).brightness == Brightness.dark;
final bg = isDark ? AppColors.darkCard : Colors.white;
```

### Image display
```dart
// Use Image.network with error builder (or cached_network_image if available):
Image.network(
  url,
  fit: BoxFit.cover,
  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
  loadingBuilder: (ctx, child, progress) =>
      progress == null ? child : const ShimmerBox(height: 80),
)
```

### Stat card values — never overflow
```dart
// StatCard already uses FittedBox — use StatCard widget, don't inline large text directly
```

---

## PART 15 — Role-Based Access Control Reference

Implement this check in every screen:

```dart
final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';

// canEdit (create/update/delete):
final canEdit = !['technician', 'labour'].contains(role);

// canApprove (approve/reject reports):
final canApprove = role == 'admin';

// canRaise (raise jobs, advance status):
final canRaise = !['technician', 'labour'].contains(role);

// isAdmin (users, email, activity):
final isAdmin = role == 'admin';
```

Show/hide action buttons based on these flags. Never just disable — hide them entirely using `if (canEdit) ... `.

---

## Summary of New Files to Create

```
lib/features/technicians/
  domain/technician.dart
  data/technicians_repository.dart
  application/technicians_notifier.dart
  presentation/technicians_screen.dart

lib/features/clients/
  domain/client.dart
  data/clients_repository.dart
  application/clients_notifier.dart
  presentation/clients_screen.dart

lib/features/jobs/
  domain/job.dart
  data/jobs_repository.dart
  application/jobs_notifier.dart
  presentation/jobs_screen.dart
  presentation/job_detail_screen.dart

lib/features/reports/
  domain/report.dart
  data/reports_repository.dart
  application/reports_notifier.dart
  presentation/reports_screen.dart
  presentation/report_detail_screen.dart

lib/features/amc/
  domain/amc_contract.dart
  data/amc_repository.dart
  application/amc_notifier.dart
  presentation/amc_screen.dart

lib/features/quotations/
  domain/quotation.dart
  data/quotations_repository.dart (or local state)
  application/quotations_notifier.dart
  presentation/quotations_screen.dart

lib/features/attendance/
  presentation/attendance_screen.dart

lib/features/activity/
  domain/activity_item.dart
  data/activity_repository.dart
  application/activity_notifier.dart
  presentation/activity_screen.dart

lib/features/profile/
  presentation/profile_screen.dart

lib/features/settings/
  presentation/settings_screen.dart
```

**Also update:**
- `lib/core/router/app_router.dart` — replace all `SimplePage` stubs
- `lib/features/users/` — complete CRUD actions