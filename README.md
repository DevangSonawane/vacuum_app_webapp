# VDTI Flutter App — Full Parity Codex Prompt

> **Purpose:** Bring the Flutter `lib/` to 100% feature, design, and API parity with the React web app's **mobile view**. The React mobile view is the single source of truth for all UI/UX decisions. Fix every overflow, alignment, and layout issue found in the current Flutter code.

---

## 0. Project Context

**App name:** VDTI Service Hub  
**API base:** `https://vaccumapi-production.up.railway.app/api`  
**Flutter stack:** Flutter 3.x · Riverpod (flutter_riverpod) · go_router · Dio or http for network  
**Architecture already in place:** feature-first folders under `lib/features/`, shared widgets under `lib/shared/widgets/`, core constants/theme/router under `lib/core/`

The existing Flutter code already has:
- `AppColors`, `AppTheme` (light + dark) — keep these, extend only
- `AppShell` (sidebar + topbar), `LoginScreen`, `ForgotPasswordScreen`, `DashboardScreen` (stub), `UsersScreen`
- Shared widgets: `AppCard`, `AppButton`, `AppInput`, `AppAvatar`, `AppToast`, `StatusBadge`, `SectionHeader`, `EmptyState`, `PageLoader`
- `AuthNotifier` / `AuthState` with Riverpod
- `GoRouter` with all routes defined

---

## 1. Design Tokens (match React exactly)

### Fonts
```
Primary body:   DM Sans  (weights 300, 400, 500, 600, 700)
Display/titles: Syne     (weights 600, 700, 800)
```
Add to `pubspec.yaml` via Google Fonts package:
```yaml
dependencies:
  google_fonts: ^6.x
```
In `AppTheme`:
```dart
import 'package:google_fonts/google_fonts.dart';
textTheme: GoogleFonts.dmSansTextTheme(...)
```
Use `GoogleFonts.syne()` for all `h1`/page title / stat-card values.

### Color Palette (already in `AppColors` — do NOT change)
| Token | Hex |
|---|---|
| blue600 | #2563EB |
| blue500 | #3B82F6 |
| blue400 | #60A5FA |
| blue200 | #BFDBFE |
| emerald500 | #10B981 |
| amber500 | #F59E0B |
| red500 | #EF4444 |
| purple500 | #A855F7 |
| orange500 | #F97316 |
| sidebar | #0F172A |
| darkBg | #030712 |
| darkCard | #1F2937 |

### Border Radius Convention
| Element | Radius |
|---|---|
| Cards, modals | 16 dp |
| Buttons, inputs | 12 dp |
| Badges/chips | 999 dp (pill) |
| Avatars | circular |
| Stat-card icon box | 12 dp |
| Logo icon box | 14 dp |

### Spacing
- Page horizontal padding: **16 dp** on mobile
- Card internal padding: **16–20 dp**
- Section gap: **16 dp**
- Item list gap: **12 dp**

### Elevation / Shadow
Cards: `BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))`  
No Material elevation — use custom shadows only.

### Status / Badge Colors
```dart
static const badgeColors = {
  'Active':         (Color(0xFFD1FAE5), Color(0xFF065F46)),  // bg, text
  'Inactive':       (Color(0xFFF3F4F6), Color(0xFF6B7280)),
  'On Leave':       (Color(0xFFFEF3C7), Color(0xFF92400E)),
  'Raised':         (Color(0xFFF3E8FF), Color(0xFF6B21A8)),
  'Assigned':       (Color(0xFFDBEAFE), Color(0xFF1E40AF)),
  'In Progress':    (Color(0xFFFEF3C7), Color(0xFF92400E)),
  'Closed':         (Color(0xFFD1FAE5), Color(0xFF065F46)),
  'Pending':        (Color(0xFFFEF3C7), Color(0xFF92400E)),
  'Approved':       (Color(0xFFD1FAE5), Color(0xFF065F46)),
  'Rejected':       (Color(0xFFFEE2E2), Color(0xFF991B1B)),
  'Expiring Soon':  (Color(0xFFFFEDD5), Color(0xFF9A3412)),
  'Critical':       (Color(0xFFFEE2E2), Color(0xFF991B1B)),
  'High':           (Color(0xFFFFEDD5), Color(0xFF9A3412)),
  'Medium':         (Color(0xFFDBEAFE), Color(0xFF1E40AF)),
  'Low':            (Color(0xFFF3F4F6), Color(0xFF6B7280)),
  'Present':        (Color(0xFFD1FAE5), Color(0xFF065F46)),
  'Absent':         (Color(0xFFFEE2E2), Color(0xFF991B1B)),
  'Late':           (Color(0xFFFEF3C7), Color(0xFF92400E)),
};
```

---

## 2. Architecture Rules

1. **State management:** Riverpod only (`flutter_riverpod`). No `setState` outside purely local UI state (e.g., text controllers, password visibility toggle).
2. **Navigation:** `go_router`. All routes already defined — keep them. Add sub-routes where needed (e.g., `/jobs/:id`, `/reports/:id`).
3. **HTTP:** Use `Dio` with a singleton client (`ApiClient`) that injects the Bearer token from `SecureStorage` on every request. Already partially set up in `lib/core/network/api_client.dart` — complete it.
4. **Token storage:** `flutter_secure_storage` via `SecureTokenStorage`. Tokens NEVER go in plain SharedPreferences.
5. **Error handling:** Every network call must be wrapped in try/catch. Show `AppToast` on error. Show shimmer skeleton on loading.
6. **Dark mode:** Controlled by `AppSettingsNotifier`. All widgets must respond to `Theme.of(context).brightness`.
7. **Responsive:** Mobile-first (all screens ≤ 480 dp wide). On tablet/desktop (≥ 1024 dp), show persistent sidebar. For this task, the **mobile layout from the React app is the reference** — use `SingleChildScrollView` with `Column` unless a 2-column grid is explicitly specified.

---

## 3. Shared Widget Spec (update existing, add missing)

### 3.1 `AppCard`
```dart
// Rounded-2xl white card, border gray100, shadow-sm
// Padding: passed in or defaults to EdgeInsets.all(16)
// Dark mode: gray-800 background, gray-700 border
Container(
  decoration: BoxDecoration(
    color: isDark ? AppColors.darkCard : Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: isDark ? Color(0xFF374151) : Color(0xFFF3F4F6)),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0,2))],
  ),
  padding: padding ?? EdgeInsets.all(16),
  child: child,
)
```

### 3.2 `StatusBadge`
Pill badge. Lookup color from `badgeColors` map above.
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
  decoration: BoxDecoration(
    color: bgColor,
    borderRadius: BorderRadius.circular(999),
  ),
  child: Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600)),
)
```

### 3.3 `AppButton`
Variants: `primary` (blue-600), `secondary` (gray-100), `danger` (red-500), `outline` (border blue-600).  
Height: 44 dp. BorderRadius: 12. Font: DM Sans SemiBold 14.  
`loading` state shows a white 16×16 CircularProgressIndicator inside.

### 3.4 `AppInput`
- `fillColor`: gray-50 light / dark input bg
- Border: gray-200 light / dark border
- Focus border: blue-600 width 2
- Border radius: 12
- `prefixIcon` support
- `AppInputType.password` shows eye-toggle suffix icon
- Label above field: DM Sans 13 SemiBold gray-700
- Required marker: red asterisk after label

### 3.5 `AppAvatar`
Gradient `from blue-500 to blue-700`, circular, shows 1–2 initials, white bold text.  
Sizes: `sm`=28, `md`=36, `lg`=48.

### 3.6 `StatCard` (NEW — add to shared/widgets)
```
┌─────────────────────────────────┐
│ Title text (sm gray-500)        │  icon box (gradient) top-right
│ 32dp bold value (Syne)          │  overlapping corner
│ subtitle / change% text (xs)    │
└─────────────────────────────────┘
```
- White card, 16dp radius, 16dp padding, gray-200 border
- Top-right decorative circle: gradient color, 96×96, clipped, opacity 0.1, offset +8, -8
- Icon box: 40×40, 12dp radius, gradient color, icon size 20 white
- Change %: green if ≥0, red if <0, "±X% vs last month"
- Animate value slide-in on mount

### 3.7 `Shimmer` skeleton widgets
Use `shimmer` package. All list/grid pages must show skeleton placeholders while loading.  
Pattern: `ShimmerBox(width, height, borderRadius)` — a single reusable widget.

### 3.8 `EmptyState`
Icon centered in a blue-50 rounded-2xl container, title DM Sans Bold, subtitle gray-400.

### 3.9 `AppToast`
Already exists. Ensure it supports `success` (emerald), `error` (red), `info` (blue) with icon + message, shown bottom-right or bottom-center on mobile, auto-dismiss 3s.

### 3.10 `ConfirmDialog`
Reusable bottom sheet or dialog:
```dart
showConfirmDialog(context, title, body, onConfirm)
```
Two buttons: Cancel (secondary) + Confirm (danger/primary).

### 3.11 `SectionHeader`
```
Row: [Column(title+subtitle), Spacer(), action widget]
title: Syne Bold 22, subtitle: DM Sans 13 gray-500
```

### 3.12 `DetailPanel` (for Jobs, Clients, Reports, AMC on tablet)
On mobile: push to a new route. On tablet (≥720dp wide): show as a sticky right panel (384dp wide) alongside the list.

---

## 4. Screen-by-Screen Specification

---

### 4.1 Login Screen (`/login`)

**React mobile reference:** Single-column card, full screen, no branding panel on mobile.

#### Layout (mobile — width < 900)
```
Scaffold
└── Center
    └── SingleChildScrollView
        └── Padding(h:16)
            └── AppCard (padding: 32dp vertical, 24dp horizontal)
                ├── "Welcome Back" — Syne Bold 28
                ├── "Sign in to access your dashboard" — DM Sans 14 gray-500
                ├── SizedBox(20)
                ├── TabBar [Email | Mobile Number] (segmented, 2 tabs)
                │    — selected: white bg, blue-600 text, shadow
                │    — unselected: transparent, gray-500 text
                │    — outer container: gray-100 bg, 14dp radius, 4dp padding
                ├── SizedBox(20)
                ├── AnimatedSwitcher → Email input OR Phone input
                │    Email: AppInput(label:"Email Address", placeholder:"email@vdti.com", prefixIcon: Icons.mail_outline)
                │    Phone: Row["+91" prefix chip, AppInput(tel)]
                ├── SizedBox(16)
                ├── AppInput(label:"Password", type:password, placeholder:"••••••••")
                ├── SizedBox(12)
                ├── Row[Checkbox "Remember me", Spacer, TextButton "Forgot password?"]
                ├── SizedBox(16)
                ├── Error banner (AnimatedOpacity, red-50 bg, red dot + message)
                ├── SizedBox(12)
                └── AppButton("Sign In", primary, expanded, loading)
```

#### Logic
- Tab toggle switches between `email` and `phone_number` credential mode
- Phone tab: prepend `+91` if not already starting with `+`
- POST `https://vaccumapi-production.up.railway.app/api/auth/login`
  - Email mode body: `{ "email": "...", "password": "..." }`
  - Phone mode body: `{ "phone_number": "+91XXXXXXXXXX", "password": "..." }`
- On success: store token via `SecureTokenStorage.write("token", token)`, navigate to `/`
- On error: display error banner below password field

---

### 4.2 Forgot Password Screen (`/forgot-password`)

Two-step flow:

**Step 1 — Request reset token**
```
AppCard
├── BackButton row ("← Back to Sign In")
├── "Forgot Password?" Syne Bold 28
├── subtitle text
├── AppInput(label:"Email Address", type:email, prefixIcon: mail icon)
├── error banner
└── AppButton("Send Reset Token")
```
POST `/api/auth/forgot-password` `{ "email": "..." }`  
On success → step 2. If `dev_only_reset_token` in response, pre-fill token field.

**Step 2 — Enter token + new password**
```
AppCard
├── "Reset Password" heading
├── AppInput(label:"Reset Token", placeholder:"Paste your token", prefixIcon: key icon)
├── Dev token hint box (blue-50, monospace) if dev token present
├── AppInput(label:"New Password", type:password)
├── AppInput(label:"Confirm Password", type:password)
├── "Passwords do not match" error text (conditional)
├── error banner
└── AppButton("Reset Password", disabled if passwords don't match)
```
POST `/api/auth/reset-password` `{ "token": "...", "new_password": "...", "confirm_password": "..." }`  
On success: show success card with green checkmark icon, then navigate to `/login` after 3s.

---

### 4.3 App Shell (`AppShell`) — fix existing

#### TopBar (mobile)
```
Material (white/darkBg bg, border-bottom)
SafeArea
└── Row(height:56)
    ├── [mobile only] Hamburger IconButton → opens Drawer
    ├── [≥ 420dp] Text(pageTitle) DM Sans Bold 18 gray-900
    ├── Spacer
    ├── Expanded(max 200dp) SearchField (AppInput compact, gray-50 bg, search icon)
    ├── SizedBox(8)
    ├── NotificationBell (bell icon + red badge + green/gray ws dot)
    ├── SizedBox(4)
    ├── Divider vertical (gray-200)
    ├── SizedBox(4)
    └── UserAvatar → taps PopupMenu
```

**CRITICAL overflow fixes for TopBar:**
- The search field MUST be `Flexible` or `Expanded` with a `maxWidth` constraint — never unconstrained
- On screens < 420dp, hide the page title completely (not just shrink it)
- All children in the Row must be wrapped with `Flexible` or `Expanded` where needed — never use unconstrained `Text` directly in a `Row`
- Use `Overflow.ellipsis` on all text in the row

#### Sidebar (drawer on mobile, fixed on desktop ≥ 1024dp)
```
Container(color: AppColors.sidebar, width:256)
Column
├── _LogoBlock (VDTI logo + "Service Hub")
├── Expanded → ListView of _NavItems
└── AppButton("Sign Out", danger, expanded)
```
Nav items active state: `blue-600` bg, white text/icon, `chevron_right` icon.  
Inactive: transparent, `blue-200` text/icon.

**CRITICAL overflow fix:** Every `_NavItem` Text must use `overflow: TextOverflow.ellipsis` and `maxLines: 1`.

#### Notification Bell dropdown
On mobile: show as a `ModalBottomSheet` with max-height 400dp, showing last N notifications.  
Each notification row:
- Unread dot (color-coded) or gray dot if read
- Title (DM Sans SemiBold 13) + message (gray-500 13, 2 lines max) + relative time
- Tap → navigate to entity route if applicable
- Header: "Notifications" + Live/Offline chip + mark-all-read + clear-all icons

---

### 4.4 Dashboard Screen (`/`)

**Full live API integration — no mock data.**

#### API
`GET /api/dashboard` → `{ stats, job_status_breakdown, monthly_stats, revenue_trend, quick_overview, recent_jobs }`

#### Loading state
Animated shimmer skeletons matching layout:
- 2-column grid of 4 StatCard skeletons (2×2 on mobile, 4×1 on desktop)
- Bar chart placeholder box
- Donut placeholder with spinning ring
- Progress bars placeholder
- Table rows placeholder

#### Loaded layout (mobile — vertical scroll)
```
SingleChildScrollView → Column
├── SectionHeader("Dashboard", "Welcome back — here's what's happening today.")
│   trailing: RefreshButton (RefreshCw equivalent → call fetchDashboard)
├── SizedBox(16)
├── 2-column GridView of 4 StatCards (cross:2, aspect:1.6)
│   1. Active Jobs        — blue gradient
│   2. Total Clients      — emerald gradient
│   3. Technicians        — purple gradient (subtitle "X total")
│   4. Revenue (Approved) — amber gradient, formatted ₹XL/₹Xk
├── SizedBox(16)
├── AppCard → "Jobs & Revenue" bar chart (use fl_chart or syncfusion_flutter_charts)
│   - Title: "Jobs & Revenue", subtitle "Last 6 months", trending icon
│   - Dual bar: light-blue (jobs raised) + dark-blue (jobs completed) per month
│   - Height: 220dp, horizontal scroll if data > 6 months
├── SizedBox(16)
├── AppCard → "Job Status" donut chart
│   - Donut (innerRadius:50, outerRadius:75) with 4 status slices
│   - Colors: Raised=purple500, Assigned=blue500, In Progress=amber500, Closed=emerald500
│   - Legend below: dot + label + count, right-aligned count
├── SizedBox(16)
├── AppCard → "Revenue Trend" line chart
│   - Blue line, dots, grid, month labels, ₹Xk Y-axis
│   - Height: 180dp
├── SizedBox(16)
├── AppCard → "Quick Overview" progress bars
│   - 4 rows: Jobs This Month / Jobs Completed / Active Technicians / AMC Active
│   - Each row: label (left) + "X/Y" (right) + colored progress bar (animated)
├── SizedBox(16)
└── AppCard → "Recent Work Orders" table
    ├── Header: "Recent Work Orders" + "View all →" button
    └── ListView of job rows (each row):
        Row: [JobID monospace blue | Title (expanded, ellipsis) | Client | StatusBadge | PriorityBadge | ₹Amount]
        — tappable → navigate to /jobs/:id
```

**CRITICAL mobile overflow fixes for Dashboard:**
- The "Recent Work Orders" table must use `SingleChildScrollView(scrollDirection: Axis.horizontal)` wrapping the table — columns must never overflow the screen width
- OR use a `ListView` of `ListTile`-style rows instead of a horizontal table
- Stat cards: value text (32sp Syne Bold) must use `FittedBox` with `fit: BoxFit.scaleDown` to prevent overflow
- Chart containers: always constrained with explicit height, never unbounded

#### Revenue formatter
```dart
String fmtRevenue(num v) {
  if (v >= 100000) return '₹${(v/100000).toStringAsFixed(1)}L';
  if (v >= 1000)   return '₹${(v/1000).toStringAsFixed(0)}k';
  return '₹${v.toStringAsFixed(0)}';
}
```

---

### 4.5 Technicians Screen (`/technicians`)

#### API
- `GET /api/technicians?limit=50&search=...` → list
- `GET /api/technicians/:id` → single (for edit pre-fill)
- `POST /api/technicians` → create
- `PUT /api/technicians/:id` → update
- `DELETE /api/technicians/:id` → delete

#### Layout
```
Scaffold body → RefreshIndicator → SingleChildScrollView
├── SectionHeader("Technicians", "X active of Y total")
│   action: [admin/manager/engineer only] AppButton("+  Add Technician")
├── SizedBox(12)
├── SearchBar (full width, search icon, debounce 400ms)
├── SizedBox(16)
└── GridView (crossAxisCount:1 mobile, 2 tablet, 3 desktop, spacing:12)
    └── TechnicianCard per item
```

#### TechnicianCard
```
AppCard
├── Row
│   ├── AppAvatar(lg, initials from name)
│   ├── SizedBox(12)
│   ├── Expanded → Column
│   │   ├── name (DM Sans Bold 14 gray-900)
│   │   └── specialization (blue-600 12)
│   └── StatusBadge(status)
├── SizedBox(12)
├── Column of contact rows (icon + text, ellipsis)
│   ├── email row (mail icon)
│   └── phone row (phone icon)
├── SizedBox(12)
├── Row of 3 mini-stat boxes (gray-50 bg, 12dp radius)
│   ├── Jobs: number + "Jobs" label
│   ├── Rating: ★ + rating + "Rating" label
│   └── Since: year + "Since" label
└── [canEdit only] Row [Edit Button (flex:1), Delete Button (danger)]
```

#### Add/Edit Bottom Sheet (use `showModalBottomSheet`)
```
DraggableScrollableSheet or fixed
├── Handle bar
├── Title: "Add Technician" / "Edit Technician"
├── [loading overlay while fetching by ID for edit]
├── Form fields (vertical scroll):
│   ├── Full Name* (col-span full)
│   ├── Row [Email, Phone*]
│   ├── Row [Specialization* dropdown, Status dropdown]
│   ├── Join Date (date picker)
│   └── [create only] Password (optional, hint text)
└── Row [Cancel, Submit] buttons
```

Specializations: `["HVAC", "Electrical", "Plumbing", "Carpentry", "Generator", "Civil", "IT"]`  
Statuses: `["Active", "On Leave", "Inactive"]`

**Role-based access:**
- `canEdit = role ∉ ['technician']`
- Show Edit/Delete buttons only if `canEdit`

---

### 4.6 Clients Screen (`/clients`)

#### API
- `GET /api/clients?limit=50&search=...&type=...` → list
- `GET /api/clients/:id` → detail + stats
- `POST /api/clients` → create
- `PUT /api/clients/:id` → update
- `DELETE /api/clients/:id` → delete

#### Layout
```
├── SectionHeader("Clients", "X active clients")  [Add Client button right]
├── Row [SearchBar(flex:1), Type filter chips (horizontal scroll)]
│   Types: All | Corporate | Residential | Commercial | Healthcare | Government
└── GridView (1 col mobile, 2 col tablet)
    └── ClientCard per item
```

#### ClientCard
```
AppCard (tappable → slide detail panel or push /clients/:id route)
├── Row
│   ├── BuildingIcon box (blue gradient 44×44, 12dp radius)
│   ├── SizedBox(12)
│   ├── Expanded → Column [company name bold, contact person gray]
│   └── Column [StatusBadge, SizedBox(4), TypeChip]
├── SizedBox(10)
├── contact info rows (email, phone, address with icons, ellipsis)
├── Divider
└── Row [contract value (bold), since date, action buttons]
```

Type chip colors:
- Corporate: blue-100/blue-700
- Residential: emerald-100/emerald-700
- Commercial: purple-100/purple-700
- Healthcare: red-100/red-700
- Government: amber-100/amber-700

#### Client Detail Panel / Page
On mobile: push new route `/clients/:id`. On tablet: side panel.
```
Gradient header (blue-600 → blue-800)
├── Row [BuildingIcon white, name white bold, contact person blue-200, X button]
└── StatusBadge + TypeChip

Scrollable body:
├── Stats row (3 boxes): Total Jobs | Open Jobs | Active AMC
├── Contact section (email, phone, address with icon boxes)
├── Contract section (Value + Since date, 2 boxes)
└── [canEdit] Action row [Edit Client, Delete]
```

---

### 4.7 Work Orders Screen (`/jobs`)

#### API
- `GET /api/jobs?limit=100&status=...` → list
- `GET /api/jobs/:id` → detail + images + reports
- `POST /api/jobs` → create
- `PATCH /api/jobs/:id/status` → advance status
- `POST /api/upload?entity_type=job&entity_id=:id` → upload image
- `POST /api/jobs/:id/images` → link image to job

#### Layout
```
├── SectionHeader("Work Orders", "X active orders")  [Raise Job button]
├── Filter tab row: All | Raised | Assigned | In Progress | Closed
│   with counts on each non-All tab
└── Body (depends on filter):
    Filter="All" → Kanban columns (horizontal scroll on mobile OR stacked vertically)
    Filter=status → Vertical list of JobCards
```

**MOBILE CRITICAL:** On mobile, the "All" view should render as **4 stacked vertical columns** (not horizontal scroll), each column being a labeled section:
```
StatusSection("Raised", jobs) → StatusSection("Assigned", jobs) → etc.
```
Each section:
```
Row [StatusBadge, count] SizedBox(8)
Column of JobCards
SizedBox(16)
```

#### JobCard (vertical — in kanban section)
```
AppCard (left border 4dp, colored by status, tappable → detail)
ring if selected (blue-500 border 2dp)
├── Row [mono-id (blue), Spacer, PriorityBadge]
├── SizedBox(4)
├── title (DM Sans SemiBold 14, maxLines:2, ellipsis)
├── SizedBox(6)
├── contact info rows (client icon+name, technician icon+name, calendar icon+date)
```

Border color by status: Raised=purple, Assigned=blue, In Progress=amber, Closed=emerald.

#### JobCard (horizontal — in filtered list view)
```
AppCard (left border 4dp)
Row
├── Expanded → Column [id, title (ellipsis), client]
└── Column [StatusBadge, ₹amount bold]
```

#### Job Detail (mobile → push `/jobs/:id`)
```
Scaffold appBar [← back | Job ID monospace | External link button]
background: status-color light bg

SingleChildScrollView → Column
├── StatusBg header card
│   ├── title (bold 18)
│   ├── Row [StatusBadge, PriorityBadge, category text]
├── SizedBox(16)
├── 2×3 InfoGrid cards (gray-50):
│   [Client, Technician, Amount, Raised, Scheduled, Closed]
├── SizedBox(16)
├── [description] AppCard "Description" → body text
├── SizedBox(16)
├── Pipeline stepper Row:
│   Raised → Assigned → In Progress → Closed
│   (filled blue-600 for completed steps, gray for future)
├── SizedBox(16)
├── [images] AppCard "Verification Photos (N)"
│   → 3-column image grid, tappable → fullscreen
├── SizedBox(16)
├── [reports] AppCard "Reports (N)"
│   → list of report rows [id mono blue, title, StatusBadge]
├── SizedBox(24)
└── [canRaise && status ≠ Closed] AppButton (full width):
    - Raised→Assigned: "Advance to Assigned →"
    - Assigned→In Progress: "Advance to In Progress →"
    - In Progress→Closed: "📷 Close Job with Verification" → opens close-verification bottom sheet
```

#### Raise Job Modal/Bottom Sheet
```
Form fields:
├── Job Title* (full width)
├── Row [Client* dropdown, Technician dropdown]
├── Row [Priority dropdown, Category dropdown]
├── Row [Scheduled Date (date picker), Amount ₹]
└── Description (multiline 3 rows)
Buttons: [Cancel, Raise Work Order]
```
Categories: `["Maintenance", "Repair", "Installation", "Inspection"]`  
Priorities: `["Low", "Medium", "High", "Critical"]`

#### Close Job Verification Bottom Sheet
```
Handle
"Close Job — Add Verification Photos" title
Warning banner (amber-50, camera icon): "Upload completion photos before closing"
Job summary card (blue icon box, id + title)
Upload zone (dashed border, upload icon, "Click to add photos")
  → ImagePicker (camera or gallery)
Image preview grid (3 col):
  each image: thumbnail + uploading/success/error overlay + remove button
Action Row [Cancel, Close Job (emerald)]
```
Flow: tap zone → `image_picker` → add to list → on submit: upload each to `/api/upload`, then PATCH status to "Closed".

---

### 4.8 Service Reports Screen (`/reports`)

#### API
- `GET /api/reports?limit=100&status=...` → list
- `GET /api/reports/:id` → detail
- `POST /api/reports` → create
- `PATCH /api/reports/:id/status` → approve/reject
- `POST /api/upload?entity_type=report&entity_id=:id` → upload
- `POST /api/reports/:id/images` → link

#### Layout
```
├── SectionHeader("Inspection & Service Reports", "X reports") [New Report button]
├── Filter tabs: All | Pending | Approved | Rejected (with counts)
└── GridView (1 col mobile, 2 col tablet) of ReportCards
```

#### ReportCard
```
AppCard (tappable → detail)
├── Row [mono-id blue | Spacer | StatusBadge]
├── title (DM Sans Bold 14)
├── client_name / job subtitle (gray-500 12)
├── [findings] gray-50 box (2 lines preview, ellipsis)
├── [image_count>0] image count chip (image icon + "N photos")
├── Divider
└── Row [technician · date | [admin+pending] Approve/Reject buttons]
```

#### Report Detail (mobile → push `/reports/:id`)
```
Scaffold appBar [← back | Report ID | External link]
Gradient header (slate-700 → slate-900)
├── id mono blue, title white, StatusBadge

Body:
├── 2×3 InfoGrid: [Job, Job Title, Client, Technician, Date, Approved At]
├── [findings] "Findings" section → gray-50 box whitespace-pre-wrap
├── [recommendations] "Recommendations" → blue-50 box
├── [images] "Attached Photos (N)" → 3-col grid, tappable fullscreen
└── [admin+pending] Row [Approve (emerald), Reject (danger)] buttons
    [approved] emerald success banner
    [rejected] red rejection banner
```

#### New Report Modal/Bottom Sheet
```
Linked Job* → searchable dropdown (id — title format)
Technician* → dropdown
Report Title* → text field
Findings → multiline (3 rows)
Recommendations → multiline (2 rows)
Attach Photos → upload zone + preview thumbnails
Buttons: [Cancel, Submit Report]
```

---

### 4.9 AMC Contracts Screen (`/amc`)

#### API
- `GET /api/amc?limit=100&status=...` → list
- `GET /api/amc/:id` → detail
- `POST /api/amc` → create
- `PUT /api/amc/:id` → update
- `DELETE /api/amc/:id` → delete

#### Layout
```
├── SectionHeader("AMC Contracts", total value formatted)
│   action: [canEdit] Add Contract button
├── Filter tabs: All | Active | Expiring Soon | Expired
└── GridView (1 col mobile, 2 col tablet) of AMCCards
```

#### AMCCard
```
AppCard (left-top gradient strip or icon)
├── Row
│   ├── gradient icon box (status gradient) with ShieldCheck icon
│   ├── Expanded → Column [title bold, client name gray]
│   └── StatusBadge
├── SizedBox(10)
├── 2×2 info grid:
│   [Start: date, End: date, Value: ₹X, Reminder: X days]
├── [services] chip row (horizontal scroll, small gray-100 rounded pills)
├── [next_service_date] calendar row
└── [canEdit] action Row [Edit, Delete]
```

Status gradients:
- Active: blue-500 → blue-700
- Expiring Soon: orange-500 → orange-700
- Expired: gray-400 → gray-600

---

### 4.10 Attendance Screen (`/attendance`)

**Note:** Current React uses mock data. Flutter should call live API if available, otherwise use same mock pattern.

#### Layout
```
├── SectionHeader("Attendance Tracking", "Daily records")
│   action: [canEdit] "Mark Attendance" button
├── SizedBox(12)
├── 2-col StatCard grid (4 cards: Present, Late, Absent, Total)
├── SizedBox(16)
├── Date picker row (label + date field)
├── SizedBox(16)
└── AppCard → attendance table
    Header: [Technician, Specialization, Check In, Check Out, Hours, Status]
    Rows: avatar+name, spec, times (monospace), hours bold, StatusBadge
```

**CRITICAL overflow fix for table:** Wrap in `SingleChildScrollView(scrollDirection: Axis.horizontal)`. Each cell text must use `overflow: TextOverflow.ellipsis`.

---

### 4.11 Quotations Screen (`/quotations`)

#### Layout
```
├── SectionHeader + [canEdit] New Quotation button
└── GridView (1 col, 2 col tablet, 3 col desktop) of QuotationCards
```

#### QuotationCard
```
AppCard
├── Row [mono-id, Spacer, StatusBadge]
├── title bold
├── client name gray-500
├── Divider
└── Row
    ├── Column [₹amount Syne Bold 22 blue-600, "Valid till date" xs gray]
    └── [canEdit+pending] Row [Approve (green), Reject (red)] icon buttons
```

#### New Quotation Modal
```
Row [Client dropdown, Title field]
Valid Till date picker
─── Line Items ───
ListView of item rows: [Description, Qty (number), Rate (₹), Total (calculated)]
[+ Add Item] button
─── Total ───
Row [Spacer, "Total: ₹X,XXX" Syne Bold 22]
Buttons: [Cancel, Create Quotation]
```

---

### 4.12 Users Screen (`/users`) — admin only

#### API
- `GET /api/users` → paginated list
- `POST /api/users` → create
- `PUT /api/users/:id` → update
- `DELETE /api/users/:id` → soft delete

#### Layout
```
├── SectionHeader("User Management", "X users")
│   action: Add User button
├── SearchBar
└── ListView of UserCards
```

#### UserCard
```
AppCard
├── Row
│   ├── AppAvatar(md, initials from first+last name)
│   ├── SizedBox(12)
│   ├── Expanded
│   │   ├── "FirstName LastName" DM Sans Bold 14
│   │   ├── email gray-500 12 (ellipsis)
│   │   └── phone gray-400 11
│   └── Column [RoleBadge, SizedBox(4), is_active indicator]
└── [admin] Row [Edit button, Delete button]
```

Role badge variant:
- admin → red bg
- manager → purple bg
- engineer → blue bg
- technician → amber bg
- labour → gray bg

#### Add/Edit User Modal
```
Row [First Name*, Last Name*]
Email (optional if phone provided)
Phone (optional if email provided, +91 prefix)
Row [Role* dropdown, Is Active toggle]
[create only] Password*
Buttons: [Cancel, Save]
```
Roles dropdown: `admin | manager | engineer | technician | labour`

---

### 4.13 Activity History Screen (`/activity`) — admin only

#### API
`GET /api/activity?limit=50&type=...` → list of activity log entries

Also show WebSocket notifications if connected (same as React `NotificationContext`).

#### Layout
```
SectionHeader + Refresh button

Two tabs (or two sections):
1. "Activity Log" — server-side activity entries
2. "Live Notifications" — WebSocket events

Activity Log tab:
Filter chips: All | job | client | report | technician | amc | user
ListView of ActivityRows

ActivityRow:
Row
├── Icon box (colored by type, 36×36, 10dp radius)
├── SizedBox(12)
├── Expanded Column
│   ├── action text (DM Sans SemiBold 14)
│   ├── "by UserName" gray-500 12
│   └── relative time gray-400 11
└── [clickable entity] ChevronRight icon

Notifications tab:
Mark All Read + Clear All buttons
ListView of NotificationRows (same as sidebar bell dropdown, full-width)
```

---

### 4.14 Profile Screen (`/profile`)

```
SingleChildScrollView
├── Row [Title "My Profile", Edit Profile button]
├── SizedBox(24)
├── Column (mobile) or Row (tablet)
│   ├── Profile card (centered):
│   │   ├── Avatar 96×96 blue-600, initials, shadow
│   │   ├── full name Syne Bold 20
│   │   ├── role badge (uppercase blue-600 tracking-wider)
│   │   ├── Divider
│   │   ├── Row [Status | Active green dot]
│   │   └── Row [Member since | 2024]
│   └── Info card:
│       "Personal Information" heading
│       2-col grid (mobile: 1-col) of info items:
│       [Email, Phone, Role, Joining Date]
│       Each: label xs uppercase gray, icon box + value DM Sans SemiBold
```

---

### 4.15 Settings Screen (`/settings`)

```
├── "Settings" heading + subtitle
├── AppCard "Appearance"
│   ├── Section icon (settings, blue-50 box)
│   ├── Dark Mode row:
│   │   Row [Moon/Sun icon, "Dark Mode" label, Spacer, Switch]
├── AppCard "Security"
│   ├── Lock icon + "Change Password" heading
│   ├── [success banner OR form]:
│   │   AppInput "New Password" (password)
│   │   AppInput "Confirm Password" (password)
│   │   "Passwords do not match" error
│   │   AppButton "Update Password" (disabled if no match)
└── AppCard "Account Info"
    ├── name, email, role chips
    └── [last login if available]
```
POST `/api/auth/change-password` for the password change (authenticated endpoint).

---

### 4.16 Job Detail Page (`/jobs/:id`)

Full dedicated Scaffold (not inside shell? Yes, still inside shell with back button in AppBar).

```
appBar: title=job.id monospace, actions=[ExternalLink (no-op or share), more]

body: SingleChildScrollView
├── StatusHeader (colored bg): title, StatusBadge, PriorityBadge, category
├── 2×3 InfoGrid: Client | Technician | Amount | Raised | Scheduled | Closed
├── [description] Description card
├── Pipeline stepper
├── [images] Verification Photos grid
├── [reports] Linked Reports list (each row taps to /reports/:id)
└── Action zone:
    [In Progress] "Close Job with Verification" full-width button → bottom sheet
    [other status] "Advance to X" full-width button
    [Closed] "This job is closed." emerald chip
```

---

### 4.17 Report Detail Page (`/reports/:id`)

```
appBar: title=report.id monospace, actions=[share]

body: SingleChildScrollView
├── Gradient header (slate-700→slate-900) with title white, StatusBadge
├── 2×3 InfoGrid: Job | Job Title | Client | Technician | Date | Approved At
├── Findings card (gray-50)
├── Recommendations card (blue-50)
├── Photos grid (3 col, tappable fullscreen)
└── [admin+pending] Approve/Reject buttons row
    [approved] success banner
    [rejected] rejection banner
```

---

## 5. Navigation Routes (complete)

All routes exist in `AppRouter`. Add missing ones:
```dart
'/jobs/:id'    → JobDetailScreen(id: state.pathParameters['id']!)
'/reports/:id' → ReportDetailScreen(id: state.pathParameters['id']!)
'/clients/:id' → ClientDetailScreen(id: state.pathParameters['id']!) // optional
```

---

## 6. API Client (complete `lib/core/network/api_client.dart`)

```dart
class ApiClient {
  static const _base = 'https://vaccumapi-production.up.railway.app/api';
  
  final Dio _dio;
  final SecureTokenStorage _storage;

  ApiClient(this._storage) : _dio = Dio(BaseOptions(baseUrl: _base)) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read('token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // trigger logout via auth notifier
        }
        handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> uploadMultipart(String path, FormData formData) =>
      _dio.post(path, data: formData);
}
```

---

## 7. Feature State Pattern (Riverpod)

Each feature follows this pattern:

```dart
// State
@freezed
class TechniciansState with _$TechniciansState {
  const factory TechniciansState({
    @Default([]) List<Technician> items,
    @Default(false) bool loading,
    String? error,
  }) = _TechniciansState;
}

// Notifier
class TechniciansNotifier extends AutoDisposeAsyncNotifier<TechniciansState> {
  @override
  Future<TechniciansState> build() async => _fetch();

  Future<TechniciansState> _fetch([String search = '']) async { ... }
  Future<void> create(Map payload) async { ... }
  Future<void> update(String id, Map payload) async { ... }
  Future<void> delete(String id) async { ... }
}

final techniciansProvider = AutoDisposeAsyncNotifierProvider<TechniciansNotifier, TechniciansState>(
  TechniciansNotifier.new
);
```

Required features to implement (each with repository + notifier + state + screen):
1. `features/technicians/`
2. `features/clients/`
3. `features/jobs/`
4. `features/reports/`
5. `features/amc/`
6. `features/quotations/`
7. `features/attendance/`
8. `features/activity/`
9. `features/dashboard/` (already started, complete it)
10. `features/profile/`

---

## 8. Image Handling

Use `image_picker` package for camera/gallery selection.

Upload flow:
```dart
// 1. Pick images
final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);

// 2. Upload to /api/upload
final formData = FormData.fromMap({
  'images': await MultipartFile.fromFile(image.path, filename: basename(image.path)),
});
final uploadRes = await apiClient.uploadMultipart(
  '/upload?entity_type=job&entity_id=$jobId',
  formData,
);
final uploaded = uploadRes.data['data'][0];

// 3. Link to entity
await apiClient.post('/jobs/$jobId/images', data: {
  'file_name': uploaded['original_name'],
  'file_url': uploaded['file_url'],
  'mime_type': uploaded['mime_type'] ?? 'image/jpeg',
  'file_size_bytes': uploaded['file_size_bytes'],
});
```

Show image thumbnails with `CachedNetworkImage` + loading placeholder.  
Fullscreen viewer: use `photo_view` package.

---

## 9. Critical UI/UX Rules (overflow & alignment fixes)

These are the most common Flutter overflow issues found. **Every rule below is mandatory:**

### 9.1 Text Overflow
- Every `Text` inside a `Row` that could overflow MUST have `overflow: TextOverflow.ellipsis` and be wrapped in `Expanded` or `Flexible`
- Never put unsized `Text` directly in a `Row` without flex

### 9.2 Row Children
- NEVER: `Row([Text(...), Text(...), Text(...)])` without explicit sizing
- ALWAYS: `Row([Expanded(child: Text(..., overflow: ellipsis)), Spacer(), Text(...)])` when the content is dynamic

### 9.3 Horizontal Scrolling Tables
- Any table with 4+ columns must be wrapped: `SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(...))`
- Alternatively, use card-based list rows (avoid tables on mobile entirely)

### 9.4 Unbounded Height
- Never place `GridView` or `ListView` as a direct child of `Column` without `shrinkWrap: true` and `physics: NeverScrollableScrollPhysics()`
- Prefer wrapping the entire page in `SingleChildScrollView` with a `Column` child

### 9.5 Stat Card Values
```dart
FittedBox(
  fit: BoxFit.scaleDown,
  alignment: Alignment.centerLeft,
  child: Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
)
```

### 9.6 Chip/Badge Rows
Use `Wrap(spacing: 6, runSpacing: 6)` for badge rows — never `Row` for dynamic badge lists

### 9.7 Modal/Bottom Sheet Height
- `showModalBottomSheet` with `isScrollControlled: true` + `DraggableScrollableSheet` for form sheets
- Max height: `MediaQuery.of(context).size.height * 0.9`
- Use `SingleChildScrollView` inside to prevent overflow

### 9.8 AppBar Title
Always wrap appBar title text: `Text(title, overflow: TextOverflow.ellipsis)`

### 9.9 Search Bar in TopBar
```dart
ConstrainedBox(
  constraints: BoxConstraints(maxWidth: 200),
  child: SearchField(),
)
```
Or `Flexible(child: SearchField())` — never `Expanded` directly if there are other flex children

### 9.10 Bottom Safe Area
All `Column` with bottom buttons must use `SafeArea(bottom: true)` to avoid iOS home bar overlap.

---

## 10. Animation Guidelines

Match React's Framer Motion animations with Flutter equivalents:

| React pattern | Flutter equivalent |
|---|---|
| `initial: opacity 0, y:20` → `animate: opacity 1, y:0` | `FadeTransition` + `SlideTransition` on route entry |
| `AnimatePresence` exit | `AnimatedSwitcher` with `duration: 200ms` |
| `motion.div whileHover: y:-4` | `AnimatedContainer` or `GestureDetector` + `Transform.translate` |
| `motion.div whileTap: scale:0.97` | `GestureDetector` with `onTapDown` → scale transform |
| Skeleton shimmer | `shimmer` package |
| Progress bar animate width | `TweenAnimationBuilder<double>` |

Page transitions: use `CustomTransitionPage` in go_router with a `FadeTransition` slide-up.

---

## 11. Dependencies to Add to `pubspec.yaml`

```yaml
dependencies:
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  go_router: ^14.x
  dio: ^5.x
  flutter_secure_storage: ^9.x
  google_fonts: ^6.x
  shimmer: ^3.x
  image_picker: ^1.x
  cached_network_image: ^3.x
  photo_view: ^0.15.x
  fl_chart: ^0.68.x          # for bar/line/pie charts
  intl: ^0.19.x
  freezed_annotation: ^2.x

dev_dependencies:
  build_runner: ^2.x
  freezed: ^2.x
  riverpod_generator: ^2.x
```

---

## 12. Role-Based Access Control

Read role from `auth.user.role` (lowercase string).

| Role | Permissions |
|---|---|
| `admin` | Full access — all screens, create/edit/delete everything, approve reports, manage users, email settings |
| `manager` | Most routes except `/users` and `/email` |
| `engineer` | Jobs, clients, technicians — read + create |
| `technician` | Read only (jobs, clients, technicians) — no create/edit/delete buttons |
| `labour` | Read only |

UI enforcement:
```dart
// canRaise / canEdit
final canEdit = !['technician', 'labour'].contains(role);
final canApprove = role == 'admin';
final isAdmin = role == 'admin';
```

Admin-only nav items: `/users`, `/email`. Filter from sidebar if not admin.

---

## 13. WebSocket / Real-time Notifications

The React app connects to `wss://vaccumapi-production.up.railway.app/ws` with auth token.

Flutter implementation:
```dart
// lib/features/notifications/notification_service.dart
class NotificationService {
  WebSocketChannel? _channel;
  final List<AppNotification> notifications = [];
  
  void connect(String token) {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://vaccumapi-production.up.railway.app/ws?token=$token'),
    );
    _channel!.stream.listen((data) {
      final json = jsonDecode(data);
      // parse and add to notifications list
      // notify listeners
    });
  }
  
  void disconnect() => _channel?.sink.close();
}
```

Riverpod provider for notifications. Show unread count badge on bell. On new notification, show `AppToast`.

---

## 14. File Structure to Create/Update

```
lib/
├── core/
│   ├── constants/app_colors.dart          ✅ exists, keep
│   ├── constants/app_constants.dart       ✅ exists
│   ├── network/api_client.dart            ⚠️ complete
│   ├── router/app_router.dart             ⚠️ add job/:id, report/:id routes
│   ├── storage/secure_token_storage.dart  ✅ exists
│   ├── theme/app_theme.dart               ⚠️ add DM Sans + Syne fonts
│   └── ui/
│       ├── app_settings_notifier.dart     ✅ exists
│       └── ui_providers.dart              ✅ exists
├── features/
│   ├── auth/                              ✅ exists, minor fixes
│   ├── dashboard/                         ⚠️ replace stub with live API
│   ├── technicians/                       🆕 create fully
│   ├── clients/                           🆕 create fully
│   ├── jobs/                              🆕 create fully
│   ├── reports/                           🆕 create fully
│   ├── amc/                               🆕 create fully
│   ├── quotations/                        🆕 create fully
│   ├── attendance/                        🆕 create fully
│   ├── activity/                          🆕 create fully
│   ├── profile/                           🆕 create
│   ├── settings/                          🆕 create
│   ├── shell/presentation/app_shell.dart  ⚠️ fix overflows
│   └── users/                             ✅ exists, minor fixes
├── shared/
│   └── widgets/
│       ├── app_avatar.dart                ✅ exists
│       ├── app_button.dart                ✅ exists
│       ├── app_card.dart                  ✅ exists
│       ├── app_input.dart                 ✅ exists
│       ├── app_toast.dart                 ✅ exists
│       ├── empty_state.dart               ✅ exists
│       ├── page_loader.dart               ✅ exists
│       ├── section_header.dart            ✅ exists
│       ├── status_badge.dart              ⚠️ update colors
│       ├── stat_card.dart                 🆕 create
│       ├── shimmer_box.dart               🆕 create
│       └── confirm_dialog.dart            🆕 create
└── main.dart                              ✅ exists
```

---

## 15. Quality Checklist

Before submitting any screen implementation, verify:

- [ ] No RenderFlex overflow errors (run on 375×667 iPhone SE viewport)
- [ ] No unbounded constraints errors
- [ ] Dark mode works correctly (toggle in settings)
- [ ] All text in Row widgets uses `Expanded`/`Flexible` + `overflow: ellipsis`
- [ ] Loading states use shimmer skeleton, not spinner alone
- [ ] Empty states show correct `EmptyState` widget with icon + title + description
- [ ] Error states show `AppToast` with error message
- [ ] All modals/bottom-sheets are scrollable with no overflow
- [ ] Images use `CachedNetworkImage` with placeholder
- [ ] All API calls include Bearer token from `SecureTokenStorage`
- [ ] Role-based UI elements are properly gated
- [ ] Back navigation works correctly from all screens
- [ ] Form validation shows inline errors before submission
- [ ] `RefreshIndicator` on all list screens
- [ ] `SafeArea` applied to all screens

---

## 16. Priority Order

Implement in this order:

1. **Shared widgets** — `StatCard`, `ShimmerBox`, `ConfirmDialog`, update `StatusBadge`
2. **Core fixes** — `AppShell` TopBar overflow, font setup
3. **Dashboard** — replace stub with live API + all charts
4. **Login** — add tab-based email/phone toggle
5. **Technicians** — full CRUD
6. **Clients** — full CRUD + detail panel
7. **Jobs** — full CRUD + status advance + close verification
8. **Reports** — full CRUD + approve/reject
9. **AMC** — full CRUD
10. **Quotations** — full CRUD
11. **Attendance** — table view
12. **Activity History** — log + notifications
13. **Profile** — read-only view
14. **Settings** — dark mode + password change
15. **Users** — already mostly done, polish
16. **Job Detail page** (`/jobs/:id`)
17. **Report Detail page** (`/reports/:id`)