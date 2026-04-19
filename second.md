# VDTI Flutter ↔ React Parity Audit Report

## Overall Verdict: ~88% Parity — Not 100%

The Flutter app is in very good shape. The architecture, design tokens, auth flow, dashboard, and most CRUD screens are correctly implemented. However there are **7 confirmed gaps** ranging from critical to minor that prevent a 100% parity claim.

---

## ✅ What IS at Parity (Correct)

| Area | Status |
|---|---|
| Login screen — email/phone tabs, animated switcher, error banner, +91 prefix | ✅ |
| Forgot password — 2-step flow, dev token hint, password mismatch, timed redirect | ✅ |
| App shell — sidebar, topbar, overflow-safe TopBar, nav items, dark/light toggle | ✅ |
| Nav items — all 11 items match React, adminOnly gating matches exactly | ✅ |
| User menu — Profile, Settings, User Management (admin), dark mode toggle, Sign Out | ✅ |
| Dashboard — live API, stat cards (2×2 mobile, 4 wide), bar chart, donut, line chart, progress bars, recent jobs table | ✅ |
| Dashboard skeleton — shimmer loading state | ✅ |
| Dashboard recent jobs — horizontal scroll DataTable, monospace IDs, tap to `/jobs/:id` | ✅ |
| Technicians — full CRUD, search debounce, 1/2/3-col grid, avatar+mini-stats cards, form bottom sheet, fetchById for edit pre-fill | ✅ |
| Clients — full CRUD, search, type filter chips, detail bottom sheet with stats from `/clients/:id` | ✅ |
| Jobs — filter tabs with counts, kanban (4 vertical sections on mobile), filtered list, raise job sheet (live client/tech dropdowns), close verification (image picker + upload + PATCH), status advance | ✅ |
| Job Detail page — header card, 6-item info grid, pipeline stepper, images grid (CachedNetworkImage), reports list (tap to `/reports/:id`), advance button | ✅ |
| Reports — filter tabs, report cards with findings preview + image count, approve/reject (admin), new report sheet (image upload) | ✅ |
| Report Detail page — gradient header, info grid, findings/recommendations boxes, photos grid, approve/reject | ✅ |
| AMC — filter tabs, gradient icon cards, service chips, all form fields (services, reminder days, next service date), CRUD | ✅ |
| Quotations — local state (matching React mock pattern), card grid, approve/reject, create sheet with line items | ✅ |
| Attendance — live API attempt with fallback to seed data, stat cards, date picker, DataTable wrapped in horizontal scroll | ✅ |
| Activity History — admin-only gate ✅, type filter chips, relative time, tappable rows to jobs/reports | ✅ |
| Profile — left card (avatar, name, role, status, since), right card (info grid with email/phone/role) | ✅ |
| Settings — dark mode switch (live), change password form, success banner, mismatch validation | ✅ |
| Users — DataTable, pagination, add/edit/deactivate with bottom sheet, role dropdown | ✅ |
| Role-based access — `canEdit`, `canRaise`, `canApprove`, `isAdmin` all correctly derived and applied | ✅ |
| Status badge colors — all 18 statuses match React exactly | ✅ |
| Design tokens — DM Sans body, Syne display, all AppColors match, 16dp border radius on cards, 12dp on inputs/buttons | ✅ |
| API client — Dio with Bearer token auto-injection from SecureStorage, 401 token deletion | ✅ |
| Dark mode — full theme propagation, all custom color containers check `isDark` | ✅ |
| RefreshIndicator — on Technicians, Clients, Jobs, Reports, AMC, Activity | ✅ |
| Empty states — all screens | ✅ |
| Shimmer skeletons — Dashboard, Technicians, Clients, Jobs, Reports, AMC, Users | ✅ |
| AppToast — success/error/info on all mutations | ✅ |
| Confirm dialog — before all delete operations | ✅ |

---

## ❌ Gap 1 — CRITICAL: Email Settings Screen is a Stub

**React:** Full screen with SMTP configuration fields (host, port, from email, from name, password) + notification toggle switches (6 toggles: job raised, job assigned, job completed, report approved, AMC renewal, quotation sent) + Save button.

**Flutter:** `/email` route still points to `SimplePage(title: 'Email Settings')` — renders "This screen is scaffolded" placeholder.

**React file:** `EmailSettings.jsx`  
**Flutter file:** `app_router.dart` line: `builder: (context, state) => const SimplePage(title: 'Email Settings')`

**Fix needed:** Implement `lib/features/email_settings/presentation/email_settings_screen.dart` with SMTP config form and notification toggles. Since React uses mock data from AppContext for this, Flutter can also use local state (no API endpoint needed). Update router to point to the new screen.

---

## ❌ Gap 2 — CRITICAL: Notification Bell is Hardcoded — Not Live

**React:** The notification bell in the TopBar:
- Connects to WebSocket `wss://vaccumapi-production.up.railway.app/ws` on login
- Loads persisted notifications from `GET /api/notifications?limit=30` on mount
- Shows real unread count badge (red)
- Dropdown with notification list: title, message, relative time, read/unread dot, mark-as-read per item, mark-all-read, clear-all
- Shows Live/Offline indicator (green dot = connected, gray dot = disconnected)
- Tapping a job notification navigates to `/jobs/:id`, report to `/reports/:id`, AMC to `/amc`
- "View all notifications →" link at bottom navigates to `/activity`

**Flutter:** `_NotificationBell(count: 3, onTap: ...)` — **hardcoded count of 3**, tapping shows `AppToast.show('Notifications coming soon…')`. No WebSocket, no API call, no dropdown, no real count.

**Fix needed:**
1. Create `lib/features/notifications/` feature with a `NotificationsNotifier` that fetches from `GET /api/notifications` and connects to WebSocket
2. Replace the hardcoded bell with a live badge count
3. Implement the notification dropdown (BottomSheet on mobile, overlay on desktop) with the full notification list matching React's design

---

## ❌ Gap 3 — MODERATE: Job Detail Screen Close Verification Redirects Away Instead of Handling In-Place

**React `JobDetail.jsx`:** When user taps "Close Job with Verification" on the detail page, it opens a modal with image upload (camera + gallery), previews, and closes the job directly from that page. The detail page refreshes in-place after closing.

**Flutter `job_detail_screen.dart` line 169:**
```dart
if (job.status == 'In Progress') {
  context.go('/jobs'); // close flow is in list for now
  AppToast.show(context, message: 'Use the Work Orders page to close with verification photos.', type: AppToastType.info);
  return;
}
```
It redirects the user to the Jobs list with a toast telling them to go there instead. This is a degraded UX — React handles it inline.

**Fix needed:** Open `_CloseJobSheet` directly from `job_detail_screen.dart` (it already exists in `jobs_screen.dart`), then call `_load()` to refresh the detail after closing. The `_CloseJobSheet` widget just needs to be moved to a shared location or duplicated.

---

## ❌ Gap 4 — MODERATE: Users Screen Search Field is Wired to Nothing

**React `UserManagement.jsx`:** Search bar filters the user list client-side (filters by name + email in the existing loaded data).

**Flutter `users_screen.dart` line 73:**
```dart
onChanged: (_) {},
```
The search field is rendered but does nothing. Typing in it has zero effect.

**Fix needed:** Either:
- Wire search to client-side filter in `UsersNotifier` (simplest), or
- Add a `search` parameter to `UsersRepository.fetchUsers()` and call it with debounce

---

## ❌ Gap 5 — MODERATE: Activity History Not Admin-Only in React Sidebar (Navigation Discrepancy)

**React sidebar nav items:**
```js
{ id: "activity", label: "Activity History", path: "/activity", adminOnly: true },
```
React marks Activity History as `adminOnly: true` in the sidebar — only admins see it in the nav.

**Flutter sidebar nav items:**
```dart
_NavDescriptor(label: 'Activity History', route: '/activity', icon: ..., adminOnly: false),
```
Flutter has `adminOnly: false` — all roles see "Activity History" in the sidebar. The screen itself correctly gates the content (`if (!isAdmin) return EmptyState(...)`), but non-admin users see the nav item which leads to a "locked" empty state. React doesn't even show the nav item to non-admins.

**Fix needed:** Change `adminOnly: false` → `adminOnly: true` for the Activity History `_NavDescriptor` in `app_shell.dart`.

---

## ⚠️ Gap 6 — MINOR: Desktop Side-Panel Pattern Missing for Jobs/Clients/Reports

**React (desktop ≥ 1024dp):** Tapping a job/client/report card opens a **sticky right side panel** (384dp wide) alongside the list. The list narrows to flex-1. This gives a master-detail layout on desktop.

**Flutter:** Tapping a card either:
- Opens a `showModalBottomSheet` (clients, reports)
- Navigates to a full detail route (jobs → `/jobs/:id`, reports → `/reports/:id`)

The full-route navigation is fine for **mobile** (the spec says mobile view is the source of truth), but on tablet/desktop there's no side panel — it's always a full-page navigation.

**Severity:** Low — the spec says "mobile view is the source of truth" and the mobile experience matches. The desktop side-panel is a tablet/desktop enhancement that wasn't in the mobile spec. This is acceptable for now but worth noting.

---

## ⚠️ Gap 7 — MINOR: Reports Screen Uses Column List, Not 2-Column Grid on Tablet

**React:** Reports list uses `grid grid-cols-1 lg:grid-cols-2` — 2-column grid on desktop.

**Flutter `reports_screen.dart`:** Uses a `Column` with individual `_ReportCard` items — always single column regardless of screen width.

**Fix needed:** Replace the `Column` in the reports list with a responsive grid:
```dart
final width = MediaQuery.sizeOf(context).width;
final cols = width >= 720 ? 2 : 1;
GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: cols,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: cols == 1 ? 1.55 : 1.35,
  ),
  ...
)
```

---

## Summary Table

| Gap | Severity | Screen | Description |
|---|---|---|---|
| Email Settings is a stub | 🔴 Critical | `/email` | Still shows `SimplePage` placeholder |
| Notification bell is hardcoded | 🔴 Critical | TopBar | Count=3, no WebSocket, no dropdown |
| Job detail can't close in-place | 🟠 Moderate | `/jobs/:id` | Redirects to list instead of opening close sheet |
| Users search does nothing | 🟠 Moderate | `/users` | `onChanged: (_) {}` — wired to nothing |
| Activity History wrong adminOnly | 🟠 Moderate | Sidebar | `adminOnly: false` should be `adminOnly: true` |
| No desktop side-panel | 🟡 Minor | Jobs/Clients/Reports | Mobile is fine; tablet/desktop lacks master-detail layout |
| Reports always 1 column | 🟡 Minor | `/reports` | Should be 2-col grid on tablet |

---

## Precise Fix Instructions

### Fix 5 (30 seconds)
In `lib/features/shell/presentation/app_shell.dart`, find:
```dart
_NavDescriptor(label: 'Activity History', route: '/activity', icon: Icons.description_outlined, adminOnly: false),
```
Change to:
```dart
_NavDescriptor(label: 'Activity History', route: '/activity', icon: Icons.description_outlined, adminOnly: true),
```

### Fix 4 (5 minutes)
In `lib/features/users/presentation/users_screen.dart`, in the search TextField:
```dart
// Replace:
onChanged: (_) {},

// With:
onChanged: (query) {
  ref.read(usersProvider.notifier).search(query);
},
```
Then add a `search(String query)` method to `UsersNotifier` that filters client-side:
```dart
Future<void> search(String query) async {
  // Simple client-side filter on already-loaded data
  // OR call _fetch() with search param to the API
}
```

### Fix 7 (10 minutes)
In `lib/features/reports/presentation/reports_screen.dart`, wrap the reports list in a responsive GridView instead of the current Column.

### Fix 3 (30 minutes)
Move `_CloseJobSheet` from `jobs_screen.dart` to a shared location (or inline it), then call it from `job_detail_screen.dart` when status is 'In Progress', and call `_load()` after completion.

### Fix 1 (2–3 hours)
Create `lib/features/email_settings/presentation/email_settings_screen.dart` with:
- SMTP config form (host, port, from email, from name, password)
- 6 notification toggle switches using local `StateNotifier`
- Save button with toast
- Update router to use new screen

### Fix 2 (4–6 hours — largest gap)
Implement real-time notifications:
- `lib/features/notifications/` feature with WebSocket connection + `GET /api/notifications`
- Replace hardcoded bell with live count
- Notification dropdown (BottomSheet on mobile) matching React's design