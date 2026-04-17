# VDTI Service Hub — Flutter App Parity Specification

> **App:** VDTI Service Hub — Internal CRM / Field Service Management  
> **Company:** Vacuum Drying Technology India LLP  
> **Backend API:** `https://vaccumapi-production.up.railway.app/api`  
> **Target:** Feature-complete Flutter parity of the React web app  
> **Date:** April 2026

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Architecture & Tech Stack](#2-architecture--tech-stack)
3. [Authentication & Session Management](#3-authentication--session-management)
4. [App Navigation & Shell](#4-app-navigation--shell)
5. [Design System & Theme](#5-design-system--theme)
6. [Reusable Widget Library](#6-reusable-widget-library)
7. [Data Models](#7-data-models)
8. [State Management Architecture](#8-state-management-architecture)
9. [Screen Specifications](#9-screen-specifications)
    - 9.1 [Login Screen](#91-login-screen)
    - 9.2 [Forgot Password Screen](#92-forgot-password-screen)
    - 9.3 [Dashboard Screen](#93-dashboard-screen)
    - 9.4 [Technicians Screen](#94-technicians-screen)
    - 9.5 [Clients Screen](#95-clients-screen)
    - 9.6 [Jobs / Work Orders Screen](#96-jobs--work-orders-screen)
    - 9.7 [Service Reports Screen](#97-service-reports-screen)
    - 9.8 [Quotations Screen](#98-quotations-screen)
    - 9.9 [AMC Contracts Screen](#99-amc-contracts-screen)
    - 9.10 [Attendance Screen](#910-attendance-screen)
    - 9.11 [Activity History Screen](#911-activity-history-screen)
    - 9.12 [Profile Screen](#912-profile-screen)
    - 9.13 [Settings Screen](#913-settings-screen)
    - 9.14 [Email Settings Screen](#914-email-settings-screen)
    - 9.15 [User Management Screen](#915-user-management-screen)
10. [API Reference](#10-api-reference)
11. [Role-Based Access Control](#11-role-based-access-control)
12. [Offline & Data Strategy](#12-offline--data-strategy)
13. [Animations & Transitions](#13-animations--transitions)
14. [Platform Considerations](#14-platform-considerations)
15. [Folder Structure](#15-folder-structure)
16. [Recommended Packages](#16-recommended-packages)

---

## 1. Project Overview

VDTI Service Hub is a field-service CRM used internally by Vacuum Drying Technology India LLP. It manages the full lifecycle of service operations:

- **Technician management** — roster, specializations, status, attendance
- **Client management** — corporate/residential/commercial accounts
- **Work Orders (Jobs)** — raised → assigned → in-progress → closed pipeline
- **Service Reports** — field reports submitted by technicians, approved by admin
- **Quotations** — line-item quotes sent to clients, approved/rejected by admin
- **AMC Contracts** — annual maintenance contracts with renewal tracking
- **Attendance** — daily check-in/check-out, weekly overview
- **Activity History** — audit log of all system actions + global search
- **User Management** — admin-only CRUD for system users (via real API)
- **Email Settings** — SMTP config and notification triggers (admin-only)

### User Roles

| Role | Key Permissions |
|---|---|
| `admin` | Full access including User Management, Email Settings, report approvals, quotation approvals |
| `manager` | All operational screens; cannot manage users or email settings |
| `engineer` / `staff` | Operational screens; cannot add/delete clients, technicians, raise jobs |
| `technician` | Read-only on most screens; can submit reports; cannot add/edit/delete |

---

## 2. Architecture & Tech Stack

### Recommended Architecture: Feature-first Clean Architecture

```
lib/
├── core/          # Theme, constants, API client, router
├── features/      # One folder per feature module
│   ├── auth/
│   ├── dashboard/
│   ├── technicians/
│   └── ...
└── shared/        # Reusable widgets, models, utils
```

### State Management
Use **Riverpod** (preferred) or **Bloc/Cubit**. The React app uses Redux Toolkit — Riverpod's `AsyncNotifierProvider` maps closely to Redux async thunks + state slices.

### Routing
Use **GoRouter** for declarative routing with redirect guards for authentication.

### HTTP Client
Use **Dio** with an interceptor that automatically attaches the `Authorization: Bearer <token>` header (mirrors the axios interceptor in `authSlice.js`).

### Local Storage
Use **flutter_secure_storage** for the JWT token (replaces `localStorage.setItem('token', ...)`).  
Use **shared_preferences** for dark mode preference.

### Charts
Use **fl_chart** for bar charts, line charts, and pie/donut charts (mirrors Recharts usage in Dashboard).

### Image Picking
Use **image_picker** for the report photo attachment feature.

---

## 3. Authentication & Session Management

### Token Storage
- On login success, store JWT in `flutter_secure_storage` under key `"token"`.
- On app startup, read the token; if present, call `GET /api/auth/me` to restore the session.
- On `getMe` failure, clear the token and redirect to Login.
- On logout, delete the token and navigate to Login.

### Auth State
```dart
class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool loading;
  final String? error;
  final String? resetToken; // dev-only: returned by forgot-password API
}
```

### Login Flow
1. User enters email OR phone number + password.
2. If identifier contains `@` → send `{ "email": ..., "password": ... }`.
3. If identifier is digits → send `{ "phone_number": "+91XXXXXXXXXX", "password": ... }`.
4. On success, store token, parse user object, navigate to Dashboard.

### Forgot Password Flow
- **Step 1:** Enter email → `POST /api/auth/forgot-password` → on success, show Step 2.
- **Step 2:** Enter reset token (pre-filled from `dev_only_reset_token` in dev), new password, confirm password → `POST /api/auth/reset-password` → on success, redirect to Login after 3 seconds.

---

## 4. App Navigation & Shell

### Navigation Items (in order)

| Label | Icon | Route | Admin Only |
|---|---|---|---|
| Dashboard | LayoutDashboard | `/` | No |
| Technicians | UserCog | `/technicians` | No |
| Clients | Users | `/clients` | No |
| Work Orders | Briefcase | `/jobs` | No |
| Service Reports | ClipboardList | `/reports` | No |
| Quotations | DollarSign | `/quotations` | No |
| AMC Contracts | ShieldCheck | `/amc` | No |
| Attendance | Clock | `/attendance` | No |
| Email Settings | Mail | `/email` | **Yes** |
| Activity History | FileText | `/activity` | No |
| Users | Users | `/users` | **Yes** |

Additional routes (accessible from top-bar dropdown only):
- `/profile`
- `/settings`

### Shell Layout

**On tablet/desktop (width ≥ 1024 dp):**  
Persistent `NavigationDrawer` on the left (always visible, width 256 dp), main content area on the right. No hamburger menu needed.

**On mobile (width < 1024 dp):**  
`NavigationDrawer` is hidden by default, opened via hamburger icon in the `AppBar`. An overlay/scrim appears behind the drawer when open; tapping the scrim or any nav item closes it.

### Sidebar Design

- **Background:** `#0f172a` (dark navy)
- **Logo block at top:** Blue `HardHat` icon in a blue-600 rounded square; "VDTI" in white bold uppercase; "Service Hub" in blue-400 small uppercase below.
- **Nav items:** Active item = blue-600 background + white text + right chevron. Inactive = blue-200 text; hover = white text + white/5 background.
- **Bottom of sidebar:** Red "Sign Out" button with LogOut icon.

### Top Bar (AppBar equivalent)

Always visible at top of main content area.

**Contents (left to right on desktop; reversed on mobile):**
- **Hamburger** (mobile only, leftmost)
- **Page title** (current screen name, hidden on small mobile)
- **Global search input** (max-width 320 dp, full-width on mobile)
- **Bell icon** with red badge showing notification count (hardcoded `3` for now)
- **User avatar + name dropdown**

**User dropdown menu contains:**
- Profile link → `/profile`
- Settings link → `/settings`
- User Management link (admin only) → `/users`
- Dark Mode toggle (animated switch)
- Sign Out button (red)

---

## 5. Design System & Theme

### Color Palette

```dart
// Primary
static const blue600 = Color(0xFF2563EB);
static const blue500 = Color(0xFF3B82F6);
static const blue400 = Color(0xFF60A5FA);
static const blue200 = Color(0xFFBFDBFE);

// Semantic
static const emerald500 = Color(0xFF10B981);
static const amber500  = Color(0xFFF59E0B);
static const red500    = Color(0xFFEF4444);
static const purple500 = Color(0xFFA855F7);
static const orange500 = Color(0xFFF97316);

// Neutrals (light mode)
static const gray50  = Color(0xFFF9FAFB);
static const gray100 = Color(0xFFF3F4F6);
static const gray200 = Color(0xFFE5E7EB);
static const gray400 = Color(0xFF9CA3AF);
static const gray500 = Color(0xFF6B7280);
static const gray700 = Color(0xFF374151);
static const gray800 = Color(0xFF1F2937);
static const gray900 = Color(0xFF111827);

// Dark mode surface
static const darkBg   = Color(0xFF030712); // gray-950
static const darkCard = Color(0xFF1F2937); // gray-800
static const sidebar  = Color(0xFF0F172A); // navy

// Badge backgrounds (light/dark pairs defined per status)
```

### Typography

- **Display / Headings:** `fontWeight: FontWeight.w700`, letter-spacing tight
- **Body:** Regular weight, 14–16 sp
- **Mono:** Use `fontFamily: 'RobotoMono'` or `monospace` for IDs (JOB-001, QT-001, etc.)
- **Page titles:** 22–24 sp, bold
- **Section headers:** 18 sp, bold
- **Card body:** 13–14 sp
- **Badges / labels:** 11–12 sp, semibold

### Border Radius

All cards and containers use `BorderRadius.circular(16)` (matches `rounded-2xl`).  
Buttons use `BorderRadius.circular(12)` (`rounded-xl`).  
Small chips/badges use `BorderRadius.circular(999)` (pill shape).

### Elevation & Shadows

- Cards: subtle shadow, `BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))`
- Hover state on cards: `y: -4dp`, larger shadow with blue tint
- Modals: `blurRadius: 24, spreadRadius: 2`

### Dark Mode

- Toggle stored in `shared_preferences` key `"darkMode"`.
- Uses `ThemeMode.dark` / `ThemeMode.light` in `MaterialApp.router`.
- Dark mode card surface: `gray-800 (#1F2937)`.
- Dark mode page background: `gray-950 (#030712)`.

---

## 6. Reusable Widget Library

Create these widgets in `lib/shared/widgets/`:

### `AppCard`
```dart
// Props: child, hover (bool), onTap
// Behavior: white/dark-800 background, rounded-2xl, border, subtle shadow
// If hover=true: InkWell tap + slight scale/elevation on tap (AnimatedContainer)
```

### `StatusBadge`
```dart
// Props: label (String)
// Maps label → background color + text color (same mapping as BADGE_VARIANTS in ui.jsx)
// Full mapping:
// Active       → emerald bg/text
// Inactive     → gray
// On Leave     → amber
// Raised       → purple
// Assigned     → blue
// In Progress  → amber
// Closed       → emerald
// Pending      → amber
// Approved     → emerald
// Rejected     → red
// Expiring Soon → orange
// Critical     → red
// High         → orange
// Medium       → blue
// Low          → gray
// Present      → emerald
// Absent       → red
// Late         → amber
```

### `AppAvatar`
```dart
// Props: initials (String), size (sm/md/lg), 
// Sizes: sm=28dp, md=36dp, lg=48dp
// Background: gradient blue-500 → blue-700
// Text: white, bold
```

### `AppButton`
```dart
// Props: label, onPressed, variant (primary/secondary/danger/ghost/outline), 
//        size (sm/md/lg), leading icon (optional)
// Variants map to colors as in ui.jsx Button component
// primary   = blue-600 bg, white text
// secondary = gray-100 bg, gray-700 text
// danger    = red-500 bg, white text
// ghost     = transparent, gray hover
// outline   = blue border, blue text
```

### `AppInput`
```dart
// Props: label, controller, type (text/email/password/number/date/time), 
//        placeholder, required, suffix (widget)
// Style: gray-50 fill, gray-200 border, rounded-xl, blue focus ring
```

### `AppSelect`
```dart
// Props: label, value, onChanged, options (List<{value, label}>), required
// Style: matches AppInput
```

### `AppTextarea`
```dart
// Props: label, controller, rows, placeholder
// Uses TextField with maxLines
```

### `AppModal`
```dart
// Props: title, child, size (sm/md/lg/xl), onClose
// Rendered as showModalBottomSheet on mobile (easier to use on small screens)
// OR showDialog on tablet/desktop
// Has header with title + X close button
// Content scrollable (max 70% of screen height)
```

### `StatCard`
```dart
// Props: title, value, icon, change (double?), color, subtitle
// Has decorative gradient circle in top-right corner
// Shows "+X% vs last month" in green if change > 0, red if < 0
// Animated entry: fade + slide-up
```

### `SectionHeader`
```dart
// Props: title, subtitle, action (widget?)
// Row with title/subtitle on left, action button on right
```

### `EmptyState`
```dart
// Props: icon, title, description
// Centered column: icon in blue-50 container, title, description
```

### `AppToast`
```dart
// Props: message, type (success/error/info)
// Slide-in from right, auto-dismiss after 3 seconds
// success = emerald, error = red, info = blue
// Use OverlayEntry or a package like `toastification`
```

### `PageLoader`
```dart
// Full-screen overlay, white/80 with blur
// Rotating ring + "VDTI Service Hub" text + three pulsing dots
// Shown during initial auth check and route transitions
```

---

## 7. Data Models

All models should be immutable (use `freezed` or manual `copyWith`).

### User
```dart
class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String role; // admin, manager, engineer, technician, labour
  final bool isActive;
  final String? avatar; // initials fallback
}
```

### Technician
```dart
class Technician {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String specialization; // HVAC, Electrical, Plumbing, Carpentry, Generator, Civil, IT
  final String status; // Active, On Leave, Inactive
  final String joinDate; // ISO date string
  final int jobsCompleted;
  final double rating;
  final String avatar; // initials e.g. "RK"
}
```

### Client
```dart
class Client {
  final int id;
  final String name;
  final String contact; // contact person name
  final String email;
  final String phone;
  final String address;
  final String type; // Corporate, Residential, Commercial, Healthcare, Government
  final String status; // Active, Inactive
  final double contractValue; // in INR
  final String joinDate;
}
```

### Job
```dart
class Job {
  final String id; // e.g. "JOB-001"
  final String title;
  final int clientId;
  final int? technicianId;
  final String status; // Raised, Assigned, In Progress, Closed
  final String priority; // Low, Medium, High, Critical
  final String category; // Maintenance, Repair, Installation, Inspection
  final String raisedDate;
  final String? scheduledDate;
  final String? closedDate;
  final String description;
  final double amount;
  final List<JobImage> images;
}

class JobImage {
  final String name;
  final String url; // base64 data URI or remote URL
}
```

### Report
```dart
class Report {
  final String id; // e.g. "RPT-001"
  final String jobId;
  final String title;
  final int technicianId;
  final String date;
  final String findings;
  final String recommendations;
  final String status; // Pending, Approved, Rejected
  final List<JobImage> images;
}
```

### Quotation
```dart
class Quotation {
  final String id; // e.g. "QT-001"
  final int clientId;
  final String title;
  final double amount;
  final String status; // Pending, Approved, Rejected
  final String validTill;
  final String createdDate;
  final List<QuotationItem> items;
}

class QuotationItem {
  final String description;
  final int qty;
  final double rate;
  final double total;
}
```

### AMCContract
```dart
class AMCContract {
  final String id; // e.g. "AMC-001"
  final int clientId;
  final String title;
  final String startDate;
  final String endDate;
  final double value;
  final String status; // Active, Expiring Soon, Expired
  final List<String> services;
  final int renewalReminder; // days before end date
  final String nextService;
}
```

### AttendanceRecord
```dart
class AttendanceRecord {
  final int id;
  final int technicianId;
  final String date;
  final String? checkIn; // HH:mm
  final String? checkOut;
  final String status; // Present, Late, Absent
  final double hours;
}
```

### ActivityLog
```dart
class ActivityLog {
  final int id;
  final String type; // job, client, quotation, amc, report, technician
  final String action;
  final String user;
  final String timestamp;
}
```

### EmailSettings
```dart
class EmailSettings {
  final String smtpHost;
  final String smtpPort;
  final String fromEmail;
  final String fromName;
  final Map<String, bool> notifications;
  // Keys: jobRaised, jobAssigned, jobCompleted, reportApproved, amcRenewal, quotationSent
}
```

### MonthlyJobStat (for dashboard charts)
```dart
class MonthlyJobStat {
  final String month; // "Aug", "Sep", etc.
  final int jobs;
  final int completed;
  final int revenue;
}
```

---

## 8. State Management Architecture

Use **Riverpod** with `AsyncNotifierProvider` for data that involves async operations.

### Auth Provider
```dart
// authProvider: AsyncNotifierProvider<AuthNotifier, AuthState>
// Methods: login(credentials), getMe(), logout(), forgotPassword(email), resetPassword(...)
// On login success → store token in secure storage
// On getMe → called at app startup to restore session
```

### App Data Provider
```dart
// appDataProvider: NotifierProvider<AppDataNotifier, AppData>
// Holds: technicians, clients, jobs, reports, quotations, amcContracts, attendance, activityLog, emailSettings
// Initialized with mock data (mirrors mockData.js)
// Later: swap mock data for real API calls
// CRUD methods: addTechnician, updateTechnician, deleteTechnician, etc.
// addActivity(type, action) → prepends to activityLog with current user + timestamp
```

### UI Providers
```dart
// darkModeProvider: StateProvider<bool>
// searchQueryProvider: StateProvider<String>
// sidebarOpenProvider: StateProvider<bool> (mobile only)
```

### User Management Provider
```dart
// usersProvider: AsyncNotifierProvider<UsersNotifier, UsersState>
// Fetches from real API: GET /api/users
// Methods: fetchUsers(), updateUser(id, data), deactivateUser(id)
// Has pagination state: page, totalPages, total
```

---

## 9. Screen Specifications

---

### 9.1 Login Screen

**Route:** `/login`  
**Authenticated redirect:** If already authenticated → redirect to `/`

**Layout:**
- On wide screens (tablet+): Two-column layout.
  - **Left panel (45% width):** Dark navy (`#0f172a`) background with subtle grid pattern overlay. Contains: VDTI logo icon, "VDTI Service Hub" title (48 sp, bold), subtitle text, three feature bullet points (icon + title + description).  Footer: "© 2024 Vacuum Drying Technology India LLP."
  - **Right panel (55% width):** Gray-50 background, centered white card (`rounded-[32px]`).
- On mobile: Full-screen, show only the right panel content (no branding panel).

**Form Card Contents:**
1. Title: "Welcome Back" (30 sp bold), subtitle: "Sign in to access your dashboard"
2. **Email or Phone field:**
   - Auto-detects: if input contains `@` → show Mail icon, else show `+91` phone prefix with Phone icon
   - If phone mode and value is non-empty: show helper text "Will be sent as +91XXXXXXXXXX"
3. **Password field:**
   - Eye toggle button (show/hide)
4. **Row:** "Remember me" checkbox (left) + "Forgot password?" link → `/forgot-password` (right)
5. **Error banner** (red background, border, dot + message): Shown if `state.error != null`
6. **Sign In button:** Full width, blue-600, bold, disabled + spinner while loading

---

### 9.2 Forgot Password Screen

**Route:** `/forgot-password`

**Layout:** Same two-column structure as Login. Left panel shows "Secure Access / Data Recovery / 24/7 Support" bullets.

**Right panel — Step 1 (Email):**
- "Back to Sign In" link at top with left arrow
- Title: "Forgot Password?", subtitle about reset token
- Email field with Mail icon
- Error banner if error
- "Send Reset Token" button

**Right panel — Step 2 (Reset):**
- "Reset Token" field with Key icon
- If `devToken` is returned in API response: show a small dev info box below the field with the pre-filled token (blue-50 background, mono font)
- "New Password" field
- "Confirm Password" field
- Passwords-don't-match error if confirmPassword is non-empty and mismatched
- "Reset Password" button (disabled if passwords don't match or loading)

**Success state:** Replace form with centered success card: shield icon, "Password reset successfully! Redirecting to login..." message. Auto-navigate to Login after 3 seconds.

---

### 9.3 Dashboard Screen

**Route:** `/`

**Header:**
```
"Dashboard"
"Welcome back — here's what's happening today."
```

**Stats Row (2 columns on mobile, 4 on desktop):**

| Title | Value | Icon | Color | Change |
|---|---|---|---|---|
| Active Jobs | count of non-closed jobs | Briefcase | blue | +12% |
| Total Clients | clients.length | Users | emerald | +5% |
| Technicians | active technicians count | UserCog | purple | subtitle: "X total" |
| Revenue (Approved) | sum of approved quotations in ₹L format | DollarSign | amber | +18% |

Each `StatCard` has staggered fade+slide animation on entry (delay i * 80ms).

**Chart Row 1 (1 col on mobile, 3 cols on desktop):**

**Jobs & Revenue Bar Chart (spans 2/3 of desktop):**
- `fl_chart` `BarChart`
- Data: `MONTHLY_JOBS` static array (6 months: Aug–Jan)
- Two bar groups per month: total jobs (light blue) + completed jobs (blue-600)
- Left Y-axis: job counts; Right Y-axis: revenue in ₹k
- Title: "Jobs & Revenue", subtitle: "Last 6 months"
- Custom tooltip: white card with month + values

**Job Status Donut Chart (1/3 of desktop):**
- `fl_chart` `PieChart` with hole (innerRadius ~60%)
- Data: Raised (purple), Assigned (blue), In Progress (amber), Closed (emerald)
- Static data: Raised=4, Assigned=6, In Progress=8, Closed=22
- Legend below the chart with colored dots

**Chart Row 2 (1 col mobile, 3 cols desktop):**

**Revenue Trend Line Chart (2/3):**
- `fl_chart` `LineChart`
- Data: `MONTHLY_JOBS.revenue` over 6 months
- Blue line, stroke width 3, filled dots
- Y-axis: ₹k labels
- Title: "Revenue Trend"

**Quick Overview Card (1/3):**
- Four progress bars with labels:
  - Jobs This Month: 24/30
  - Jobs Completed: 19/24
  - Active Technicians: dynamic / total
  - AMC Active: 2/3
- Each bar: label + fraction (right-aligned), then `LinearProgressIndicator`-style bar
- Bars animate width from 0 to value on entry (0.8s, 0.3s delay)
- Colors: blue, emerald, purple, amber respectively

**Recent Work Orders Table:**
- Title: "Recent Work Orders"
- Shows first 5 jobs from state
- Columns: Job ID (blue mono), Title, Client, Status (badge), Priority (badge), Amount (₹)
- Rows: hover highlight (blue-50/10), animated entry

---

### 9.4 Technicians Screen

**Route:** `/technicians`

**Header:** "Technicians", subtitle: "X active of Y total"  
**Action button** (non-Technician role only): "+ Add Technician"

**Search Bar:**
- Single text field, Search icon prefix, "Search technicians..."
- Filters by name or specialization

**Grid layout:** 1 col (mobile), 2 col (tablet), 3 col (desktop)

**Technician Card (AppCard with hover):**
- Top row: `AppAvatar` (large, initials) + name (bold, 14sp) + specialization (blue-600, 12sp) + `StatusBadge` (top-right)
- Contact row: Mail icon + email; Phone icon + phone
- Stats row (3 equal boxes, gray-50 background, rounded-lg):
  - Jobs: `tech.jobsCompleted`
  - Rating: ⭐ + rating value
  - Since: join year
- Action buttons (non-Technician role only): "Edit" (secondary) + trash icon (danger)

**Add/Edit Technician Modal:**
- Fields:
  - Full Name (col-span-2)
  - Email
  - Phone
  - Specialization (dropdown: HVAC, Electrical, Plumbing, Carpentry, Generator, Civil, IT)
  - Status (dropdown: Active, On Leave, Inactive)
  - Join Date (date picker, col-span-2)
- On submit: compute initials from name → set as `avatar`
- Buttons: "Add/Update Technician" (primary, flex-1) + "Cancel" (secondary)

**Delete Confirmation Modal (sm size):**
- "Are you sure you want to remove this technician? This cannot be undone."
- "Delete" (danger, flex-1) + "Cancel" (secondary)

**Toast notifications:** "Technician added!", "Technician updated!", "Technician removed" (error type)

---

### 9.5 Clients Screen

**Route:** `/clients`

**Header:** "Clients", subtitle: "X active clients"  
**Action button** (non-Technician role): "+ Add Client"

**Filter bar:**
- Search input (min-width 192 dp)
- Type filter pills: All, Corporate, Residential, Commercial, Healthcare, Government
  - Active pill: blue-600 bg, white text
  - Inactive pill: gray-100 bg, gray-600 text

**Grid:** 1 col (mobile), 2 col (desktop)

**Client Card:**
- Top row:
  - Blue gradient square icon with `Building2` icon (white)
  - Name (bold) + contact person (gray, 12sp)
  - Right side: `StatusBadge` + type chip (colored per type: Corporate=blue, Residential=emerald, Commercial=purple, Healthcare=red, Government=amber)
- Contact details (xs, gray-500): Mail icon + email, Phone icon + phone, MapPin icon + address
- Bottom row (border-top):
  - Contract Value label + ₹ amount (bold)
  - Since label + joinDate (right-aligned)
  - Edit (secondary) + Delete (danger) buttons (non-Technician only)

**Add/Edit Client Modal (lg size):**
- Fields (2-column grid):
  - Company Name (col-span-2)
  - Contact Person
  - Email
  - Phone
  - Contract Value (₹, number)
  - Type (dropdown: Corporate, Residential, Commercial, Healthcare, Government)
  - Status (dropdown: Active, Inactive)
  - Address (col-span-2)
- Buttons: "Add/Update Client" + "Cancel"

**Delete Confirmation Modal:**
- "Remove this client permanently?"
- Delete (danger) + Cancel

---

### 9.6 Jobs / Work Orders Screen

**Route:** `/jobs`

**Header:** "Work Orders", subtitle: "X active orders"  
**Action button** (non-Technician): "+ Raise Job"

**Status Filter Tabs (horizontal scroll on mobile):**
All | Raised | Assigned | In Progress | Closed  
Each status tab shows a count badge. Active tab = blue-600 bg.

**"All" view — Kanban Board:**
- 4 columns: Raised | Assigned | In Progress | Closed
- Each column header: `StatusBadge` + count
- Each column has job cards stacked vertically
- Empty column: dashed border, centered "Empty" text

**Single-status view — List:**
- `JobCard` components in vertical `ListView`
- `horizontal=true` variant: card is a row with flex layout

**JobCard:**
- Left border accent (4 dp) colored by status: purple (Raised), blue (Assigned), amber (In Progress), emerald (Closed)
- Job ID (mono, blue-500), title (bold, 14sp), priority badge (top-right)
- Detail rows: User icon + client name; User(blue) icon + technician name (if assigned); Calendar icon + scheduledDate (if set)
- Horizontal variant additionally shows: StatusBadge + amount (₹, bold)

**Raise Job Modal (lg size):**
- Fields:
  - Job Title (col-span-2)
  - Client (dropdown from clients list)
  - Assign Technician (dropdown: "Not assigned yet" + active technicians only)
  - Priority (Low, Medium, High, Critical)
  - Category (Maintenance, Repair, Installation, Inspection)
  - Scheduled Date (date picker)
  - Amount (₹, number)
  - Description (textarea, col-span-2)
- On submit: auto-generates ID `JOB-{timestamp slice}`, status="Raised"

**Job Detail Modal (lg size):**
- 2-col info grid: Status badge, Priority badge, Client, Technician, Category, Amount (₹), Raised date, Scheduled date
- Description section
- **Status Pipeline:** Row of 4 steps (Raised → Assigned → In Progress → Closed). Completed steps = blue-600 bg; future steps = gray. Arrows between steps.
- **"Advance to [next status]" button** (full width, primary) — shown if job status is not Closed. On tap, calls `updateJob` and updates the modal display in-place.

**Status advance logic (STATUS_FLOW):**
```
Raised → Assigned
Assigned → In Progress  
In Progress → Closed (also sets closedDate = today)
```

---

### 9.7 Service Reports Screen

**Route:** `/reports`

**Header:** "Inspection & Service Reports", subtitle: "X reports submitted"  
**Action button** (all roles can submit): "+ New Report"

**Grid:** 1 col (mobile), 2 col (desktop)

**Report Card:**
- ID (mono, blue-500), title (bold), client/job title (gray, xs)
- `StatusBadge` (top-right)
- Findings preview box (gray-50 bg, rounded-xl): "Findings" label + 2-line truncated text
- Image thumbnails row: up to 3 square 56×56 dp thumbnails; if more than 3, show "+N" gray box
- Footer: technician name + date (left); approve/reject buttons (right, admin only, Pending reports only)

**Submit Report Modal (lg size):**
- Linked Job (dropdown: "JOB-XXXX — Title" format)
- Report Title
- Findings (textarea, 3 rows)
- Recommendations (textarea, 2 rows)
- **Image Upload Area:**
  - Dashed border container, Image icon centered, "Click to upload photos" text
  - On tap: open image picker (multiple selection, images only)
  - Preview grid of selected images (64×64 dp), each with a red × remove button (top-right corner)
- Buttons: Submit Report (primary, flex-1) + Cancel

**Report Detail Modal (lg size):**
- ID, Status badge, Linked Job, Date (2-col grid)
- Findings (gray-50 rounded box)
- Recommendations (blue-50 rounded box, blue label)
- Attached Images gallery (if any): 80×80 dp rounded thumbnails in a `Wrap`

**Approve/Reject actions (admin only, Pending status):**
On report card: small "✓ Approve" (emerald) and "✗ Reject" (red) text buttons.  
Calls `updateReport(id, { status: 'Approved' | 'Rejected' })`.

---

### 9.8 Quotations Screen

**Route:** `/quotations`

**Header:** "Quotations", subtitle: "X pending approval"  
**Action button** (non-Technician): "+ New Quotation"

**Grid:** 1 col (mobile), 2 col (tablet), 3 col (desktop)

**Quotation Card:**
- ID (mono, blue-500), title (bold), client name (gray, xs)
- `StatusBadge`
- Bottom row (border-top): Amount (₹, 24sp bold blue) + "Valid till [date]" (xs, gray)
- If Pending and user can edit: right side of bottom row shows ✓ (emerald) + ✗ (red) action buttons (tapping doesn't open detail, uses `stopPropagation` equivalent)

**New Quotation Modal (xl size):**
- Client (dropdown)
- Quotation Title
- Valid Till (date picker, col-span-2)
- **Line Items section:**
  - Header row: "Description" | "Qty" | "Rate (₹)" | "Total"
  - For each item: description input (5/12), qty input (2/12), rate input (2/12), total display (2/12, blue-50 bg), remove button (1/12, red ×)
  - "+ Add Item" link button at bottom
  - Total auto-computed (qty × rate per item; sum of all for grand total)
- Footer: "Total Amount" label + grand total (₹, 24sp bold blue) + Create/Cancel buttons

**Quotation Detail Modal (lg size):**
- ID, Status, Client, Valid Till (2-col info grid)
- Line items table: Description | Qty | Rate | Total (tfoot: Grand Total)

**Approve/Reject (Pending quotations, non-Technician role):**  
On card only; calls `updateQuotation(id, { status })`.

---

### 9.9 AMC Contracts Screen

**Route:** `/amc`

**Header:** "AMC Contracts", subtitle: "Total portfolio: ₹X.XL"  
**Action button** (non-Technician): "+ New AMC"

**Summary Row (3 equal cards, always visible):**
- Active count (blue)
- Expiring Soon count (orange)
- Expired count (gray)

**Grid:** 1 col (mobile), 2 col (tablet), 3 col (desktop)

**AMC Card:**
- 6 dp colored top stripe: blue (Active), orange (Expiring Soon), gray (Expired)
- AMC ID (mono, blue-500), title (bold), client name (gray, xs)
- `StatusBadge` (top-right)
- 2-col metric boxes:
  - Contract Value: ₹ amount (bold blue, 16sp)
  - Days Left: computed from `endDate - today`; if < 60 days → orange background + orange text; if expired → "Expired"
- Date row: Calendar icon + "startDate → endDate"
- Next service row: RefreshCw icon + "Next service: date"
- Expiring Soon alert: orange AlertTriangle icon + "Renewal reminder in X days"
- Services section: "Covered Services" label + pill chips for each service (blue-100 bg, blue-700 text)

**New AMC Modal (lg size):**
- Client (dropdown)
- Contract Title
- Start Date (date picker)
- End Date (date picker)
- Contract Value (₹, number)
- Next Service Date (date picker)
- Renewal Reminder (dropdown: 15 days / 30 days / 60 days, col-span-2)
- Services Covered (text input, comma-separated, col-span-2; split on submit)

**AMC Detail Modal (lg size):**
- 8 fields in 2-col grid: AMC ID, Status, Client, Contract Value, Start Date, End Date, Next Service, Renewal Reminder
- Services Covered: pill chips

---

### 9.10 Attendance Screen

**Route:** `/attendance`

**Header:** "Attendance Tracking", subtitle: "Daily check-in / check-out records"  
**Action button** (non-Technician): "+ Mark Attendance"

**Stats Row (2 cols mobile, 4 cols desktop):**
- Present Today (emerald, UserCheck icon) — count of Present records for selected date
- Late (amber, AlertCircle icon)
- Absent (red, UserX icon)
- Total Technicians (blue, Clock icon) — always `technicians.length`

**Date Picker:**
- Row: "Date:" label + date picker input field (max = today)
- Default: today's date

**Attendance Table (Card):**
- Title: "Attendance for [selectedDate]"
- Columns: Technician | Specialization | Check In | Check Out | Hours | Status
- Each row: avatar circle + name (Technician column); mono font for check-in/check-out times; StatusBadge for status; "Not marked" gray text if no record

**Weekly Overview Card:**
- 7-day date range ending today
- Table: rows = technicians; columns = each day
- Day header: 3-letter weekday + day number; today's date highlighted in blue
- Each cell: colored dot (16×16 dp circle): emerald=Present, amber=Late, red=Absent, gray=No Record
- Dot has tooltip (on long-press or hover) showing status
- Legend at bottom: colored dots with labels

**Mark Attendance Modal (sm size):**
- Technician (dropdown)
- Status (dropdown: Present, Late, Absent)
- If status ≠ Absent: show Check In (time picker) + Check Out (time picker) in 2-col grid
- Mark Attendance (primary) + Cancel

---

### 9.11 Activity History Screen

**Route:** `/activity`

**Dual-purpose screen:**
1. When `searchQuery` is empty or ≤ 1 char → show Activity History feed
2. When `searchQuery` has ≥ 2 chars → show Global Search Results

**When showing activity feed:**
- Title: "Activity History", subtitle: "X recent activities"
- Timeline Card:
  - Vertical line running down the left (gray-100)
  - Each entry: colored icon square (48×48 dp), action text, user (blue-600, bold), timestamp (gray), type chip (border + bg colored by type)

**Activity type icon/color mapping:**

| Type | Icon | Color |
|---|---|---|
| job | Briefcase | blue |
| client | Users | emerald |
| quotation | DollarSign | amber |
| amc | ShieldCheck | purple |
| report | FileText | gray |
| technician | UserCog | red |

**When showing search results:**
- Title: "Search Results", subtitle: `X results for "query"`
- Searches across: jobs (by id, title), clients (by name, contact), technicians (by name, specialization), quotations (by id, title), amcContracts (by id, title)
- Each result: type icon + name/ID (bold) + detail text + type chip + sub-status
- No results → EmptyState with History icon

**Global search is driven by `searchQuery` from the top-bar search input.** This screen listens to the same provider.

---

### 9.12 Profile Screen

**Route:** `/profile`

**Header:** "My Profile", subtitle: "View and manage your personal information"  
**Edit Profile button** → navigates to `/settings`

**Layout (1 col mobile, 3 col desktop with left panel + right panel):**

**Left panel (compact card):**
- Large avatar square (128×128 dp, rounded corners, blue gradient), shows initials
- Name (bold, 20sp), role (blue-600, uppercase, 12sp)
- Status row: "Status" + green dot + "Active"
- Member since: "2024"

**Right panel (personal info card):**
- Title: "Personal Information"
- 2-col grid (1 col on mobile) of info items:
  - Email Address (Mail icon)
  - Phone Number (Phone icon)
  - Role (Shield icon)
  - Joining Date (Calendar icon) — hardcoded "January 2024"
- Each item: label (xs, gray, uppercase tracking) + icon in gray-50 box + value (bold)

---

### 9.13 Settings Screen

**Route:** `/settings`

**Header:** "Settings", subtitle: "Manage your preferences and security"

**Appearance Card:**
- Settings icon (blue-50 bg)
- "Dark Mode" row: label + description + animated toggle switch
  - Toggle: gray bg (off) → blue-600 bg (on); thumb slides with Moon/Sun icon

**Security Card:**
- Lock icon (red-50 bg)
- Change password form:
  - New Password field
  - Confirm New Password field
  - Mismatch error (AlertCircle icon, red)
  - API error banner (red card)
  - Success banner (green card, CheckCircle2 icon, "Password changed successfully!")
  - "Update Password" button (disabled if passwords don't match or empty or loading)
- Calls `POST /api/auth/reset-password` with `token: "CURRENT_SESSION"`, new_password, confirm_password

---

### 9.14 Email Settings Screen

**Route:** `/email` (admin only)

**Header:** "Email Notification Settings", subtitle: "Configure SMTP and notification triggers"

**SMTP Configuration Card:**
- Mail icon (blue-100 bg)
- 2-col grid: SMTP Host, SMTP Port, From Email, From Name
- Password field (full width, masked, read-only display of bullets)
- "Send Test Email" outline button (Send icon)

**Notification Triggers Card:**
- List of 6 notification types, each row:
  - Label + description
  - Animated toggle switch (animated thumb: when on → x=20, off → x=2)

Notification trigger labels:
- jobRaised → "New Job Raised"
- jobAssigned → "Job Assigned to Technician"
- jobCompleted → "Job Completed / Closed"
- reportApproved → "Report Approved"
- amcRenewal → "AMC Renewal Reminder"
- quotationSent → "Quotation Created"

**Email Template Preview Card:**
- Static preview of the email template:
  - Blue header: "VDTI Service Hub Notification" + "Vacuum Drying Technology India LLP" (blue-200)
  - White body: greeting, job details box (blue-50 border), footer note using `fromName` value

**Save Settings button** (bottom-right, lg size, Save icon)

---

### 9.15 User Management Screen

**Route:** `/users` (admin only)

**Header:** "User Management", subtitle: "Manage system access and user roles"  
**Action button:** "+ Add New User" (UserPlus icon)

**Search bar:** Full search input within the card header area.

**Users Table (Card with overflow scroll):**
- Columns: User (avatar + name + email) | Role | Contact | Status | Actions
- **Loading skeleton:** 5 rows, each cell with a `shimmer` placeholder widget
- **User row:**
  - Avatar: 40×40 dp, rounded-xl, blue-50 bg, blue initials
  - Name (bold) + email (gray, xs)
  - Role: Shield icon (blue) + role name (capitalized)
  - Contact: phone number or "—"
  - Status: Active (green pill, CheckCircle2) or Inactive (red pill, XCircle)
  - Actions: Edit pencil button (blue hover) + Deactivate trash button (red hover, disabled if already inactive)

**Pagination Info (below card):**
- "Showing X of Y users"
- Previous / Page X of N / Next buttons

**Create/Edit User Modal:**
- Title: "Edit User Details" or "Create New User"
- Two-column: First Name + Last Name
- Email (full width)
- Phone Number
- User Role dropdown: Administrator, Office Staff, Technician
  - Values: admin, staff, technician
- Account Status toggle: "Allow user to log in and access system" + animated green toggle
- Cancel (outline) + Save/Update (primary with Save icon) buttons

**API calls (real):**
- `GET /api/users` — fetch paginated users list
- `PUT /api/users/:id` — update user
- `DELETE /api/users/:id` — deactivate user

---

## 10. API Reference

**Base URL:** `https://vaccumapi-production.up.railway.app/api`  
**Auth Header:** `Authorization: Bearer <token>` (on all protected routes)

| Method | Endpoint | Description |
|---|---|---|
| POST | `/auth/login` | Login with `{ email, password }` or `{ phone_number, password }` |
| GET | `/auth/me` | Get current user session |
| POST | `/auth/forgot-password` | Send reset token to email `{ email }` |
| POST | `/auth/reset-password` | Reset password `{ token, new_password, confirm_password }` |
| GET | `/users` | List all users (admin) |
| PUT | `/users/:id` | Update user (admin) |
| DELETE | `/users/:id` | Deactivate user (admin) |

### Response Structures

**Login success:**
```json
{
  "token": "eyJ...",
  "user": { "id": 1, "first_name": "...", "last_name": "...", "email": "...", "role": "admin", ... }
}
```
OR flat: `{ "token": "...", "id": 1, "first_name": "...", ... }` (handle both)

**GET /auth/me success:**
```json
{ "user": { ... } }
```

**Forgot password success:**
```json
{ "message": "...", "dev_only_reset_token": "TOKEN" }
```

**GET /users success:**
```json
{
  "success": true,
  "data": [ { "id": 1, "first_name": "...", "last_name": "...", "email": "...", "role": "...", "phone_number": "...", "is_active": true } ],
  "pagination": { "page": 1, "total_pages": 3, "total": 25 }
}
```

### Error Handling
- All API errors return `{ "message": "..." }` in the response body.
- Network errors should show a toast with "Network error. Please try again."
- 401 errors should clear the token and navigate to Login.

---

## 11. Role-Based Access Control

Implement a `PermissionService` or simple utility functions:

```dart
bool canEdit(String role) => role.toLowerCase() != 'technician';
bool isAdmin(String role) => role.toLowerCase() == 'admin';
```

### Screen-level access

| Screen | Minimum Role |
|---|---|
| Email Settings | admin only |
| User Management | admin only |
| All others | Any authenticated user |

### Feature-level access

| Feature | Restricted to |
|---|---|
| Add/Edit/Delete Technicians | Non-Technician |
| Add/Edit/Delete Clients | Non-Technician |
| Raise Jobs | Non-Technician |
| Approve/Reject Reports | Admin |
| Approve/Reject Quotations | Non-Technician |
| Create AMC Contracts | Non-Technician |
| Mark Attendance | Non-Technician |
| Submit Reports | All (any role) |

In Flutter: conditionally render action buttons and FABs based on role. Use GoRouter redirect for route-level guards.

---

## 12. Offline & Data Strategy

### Current state (React app)
The React app uses **mock data** for all entities except User Management (which hits the real API). The production app will eventually replace mock data with real API calls.

### Flutter approach:
- **Phase 1 (parity):** Mirror the React app exactly. Use the same `mockData.js` data hardcoded in Dart. Only User Management and Auth use real API calls.
- **Phase 2 (future):** Replace each entity's mock CRUD with real API endpoints as they become available.
- **Local state persistence:** Keep in-memory during session (no local DB needed for Phase 1). State resets on app restart (matching current React behavior).

### Dark mode
Persist dark mode preference using `shared_preferences`.

---

## 13. Animations & Transitions

### Page Transitions
Every screen entry: fade + slide-up (similar to Framer Motion `PageTransition`).
```dart
// Use GoRouter's custom transition builder:
transitionsBuilder: (context, animation, _, child) {
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween(begin: Offset(0, 0.04), end: Offset.zero).animate(animation),
      child: child,
    ),
  );
}
```
Duration: 250ms, ease-out curve.

### Card Hover
On mobile: `ScaleTransition` or `AnimatedContainer` on tap-down.  
On desktop/web: Wrap in `MouseRegion` to detect hover; animate `elevation` and y-offset.

### List Entry Stagger
Use staggered animation for grid/list items:
- Each item fades in + slides up
- Delay: `i * 50ms`
- Duration: 300ms

### Modal Entry
Scale from 0.9 → 1.0 + fade in. Spring animation (damping 25, stiffness 300).

### Stat Card Progress Bars
Animate width from 0 → value over 800ms with 300ms initial delay. Use `AnimationController` + `Tween`.

### Toggle Switches
Thumb position animated with spring physics (`AnimatedPositioned` or Riverpod-driven `AnimatedContainer`).

### Page Loader
- Outer ring: continuous 360° rotation (2s linear, infinite)
- Inner square: scale pulse + rotation + borderRadius oscillation
- Center dot: opacity pulse (1.5s, infinite)
- Three dots below text: sequential scale+opacity pulse with 200ms offset each

---

## 14. Platform Considerations

### Android & iOS (primary targets)

- **Bottom navigation:** Do NOT use `BottomNavigationBar` — the app uses a sidebar drawer pattern. On mobile, trigger drawer via hamburger in `AppBar`.
- **Status bar:** Set status bar color to match `AppBar` background.
- **Safe areas:** Respect `SafeArea` for notches/home indicators.
- **Image picker:** Use `image_picker` package; request permissions properly on both platforms.
- **Date pickers:** Use Material `showDatePicker`; style with blue theme.
- **Time pickers:** Use `showTimePicker` for attendance check-in/check-out.
- **Keyboard avoidance:** Wrap forms in `SingleChildScrollView` with `resizeToAvoidBottomInset: true`.

### Tablet (responsive layouts)

- `LayoutBuilder` / `MediaQuery` breakpoint: 1024 dp width
- Below 1024 dp: single-column, drawer-based navigation
- 1024 dp+: persistent sidebar + multi-column grids

### Web (if targeting Flutter Web)

- Sidebar is always visible on desktop browser
- Mouse hover states on cards (using `MouseRegion`)
- Scrollbar visibility

---

## 15. Folder Structure

```
lib/
├── main.dart
├── app.dart                    # MaterialApp.router, theme, providers
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── api_constants.dart
│   ├── router/
│   │   └── app_router.dart     # GoRouter config with auth guards
│   ├── network/
│   │   ├── dio_client.dart     # Dio instance with interceptors
│   │   └── api_exception.dart
│   └── utils/
│       ├── currency_format.dart  # ₹ formatting helpers
│       ├── date_format.dart
│       └── role_utils.dart       # canEdit(), isAdmin()
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── domain/
│   │   │   └── user_model.dart
│   │   ├── presentation/
│   │   │   ├── login_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   └── providers/
│   │       └── auth_provider.dart
│   │
│   ├── dashboard/
│   │   └── presentation/
│   │       └── dashboard_screen.dart
│   │
│   ├── technicians/
│   │   ├── domain/technician_model.dart
│   │   └── presentation/technicians_screen.dart
│   │
│   ├── clients/
│   │   ├── domain/client_model.dart
│   │   └── presentation/clients_screen.dart
│   │
│   ├── jobs/
│   │   ├── domain/job_model.dart
│   │   └── presentation/
│   │       ├── jobs_screen.dart
│   │       └── widgets/job_card.dart
│   │
│   ├── reports/
│   │   ├── domain/report_model.dart
│   │   └── presentation/reports_screen.dart
│   │
│   ├── quotations/
│   │   ├── domain/quotation_model.dart
│   │   └── presentation/quotations_screen.dart
│   │
│   ├── amc/
│   │   ├── domain/amc_model.dart
│   │   └── presentation/amc_screen.dart
│   │
│   ├── attendance/
│   │   ├── domain/attendance_model.dart
│   │   └── presentation/attendance_screen.dart
│   │
│   ├── activity/
│   │   └── presentation/activity_screen.dart
│   │
│   ├── profile/
│   │   └── presentation/profile_screen.dart
│   │
│   ├── settings/
│   │   └── presentation/settings_screen.dart
│   │
│   ├── email_settings/
│   │   └── presentation/email_settings_screen.dart
│   │
│   └── users/
│       ├── data/users_repository.dart
│       ├── domain/user_management_model.dart
│       ├── presentation/user_management_screen.dart
│       └── providers/users_provider.dart
│
├── shared/
│   ├── widgets/
│   │   ├── app_card.dart
│   │   ├── app_avatar.dart
│   │   ├── app_button.dart
│   │   ├── app_input.dart
│   │   ├── app_select.dart
│   │   ├── app_textarea.dart
│   │   ├── app_modal.dart
│   │   ├── app_badge.dart
│   │   ├── stat_card.dart
│   │   ├── section_header.dart
│   │   ├── empty_state.dart
│   │   ├── app_toast.dart
│   │   └── page_loader.dart
│   ├── layout/
│   │   ├── app_shell.dart        # Sidebar + TopBar scaffold
│   │   ├── sidebar.dart
│   │   └── top_bar.dart
│   ├── providers/
│   │   ├── app_data_provider.dart  # Technicians/Clients/Jobs/etc.
│   │   └── ui_providers.dart       # darkMode, searchQuery, sidebarOpen
│   └── data/
│       └── mock_data.dart          # Dart port of mockData.js
```

---

## 16. Recommended Packages

```yaml
dependencies:
  flutter_riverpod: ^2.5.0        # State management
  riverpod_annotation: ^2.3.0
  go_router: ^13.0.0              # Routing with auth guards
  dio: ^5.4.0                     # HTTP client
  flutter_secure_storage: ^9.0.0  # JWT token storage
  shared_preferences: ^2.2.0      # Dark mode preference
  fl_chart: ^0.68.0               # Bar, Line, Pie charts
  image_picker: ^1.1.0            # Photo upload for reports
  intl: ^0.19.0                   # Date/number formatting (₹ currency)
  cached_network_image: ^3.3.0    # Image caching (future use)
  shimmer: ^3.0.0                 # Loading skeleton placeholders

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
  freezed: ^2.5.0                 # Immutable models (optional but recommended)
  json_serializable: ^6.7.0
```

---

## Key Notes for Implementation

1. **Currency formatting:** Always display INR amounts using `₹` symbol. For large amounts, show in Lakh format (`₹X.XL`) on cards and dashboards. Use `NumberFormat` from `intl` package.

2. **ID formats:** Job IDs = `JOB-XXXX`, Report IDs = `RPT-XXXX`, Quotation IDs = `QT-XXXX`, AMC IDs = `AMC-XXXX`. When creating, use last 4 digits of epoch milliseconds.

3. **Date format:** Display as `YYYY-MM-DD` in inputs; in tables/cards use locale-aware format (e.g., `15 Jan 2024`). Use `intl` DateFormat.

4. **The `addActivity` function:** Every CRUD action must prepend an `ActivityLog` entry with: type, action string, current user's name, current timestamp in `dd/MM/yy, HH:mm` format.

5. **Phone number handling on Login:** Prepend `+91` if the identifier is numeric-only and doesn't already start with `+`.

6. **Technician filter in Job creation:** Only show `Active` technicians in the "Assign Technician" dropdown.

7. **Admin-only routes:** Wrap `/email` and `/users` with GoRouter redirect: if `!isAdmin(user.role)` → redirect to `/`.

8. **Sidebar filtering:** Admin-only nav items (Email Settings, Users) are hidden from the sidebar if the user is not admin.

9. **Search is global:** The search input in TopBar updates `searchQueryProvider`. The Activity History screen listens to this provider and switches between "Activity Feed" and "Search Results" views automatically.

10. **Image upload in Reports:** Images are stored as base64 data URIs (same as React implementation using `FileReader`). Use Dart's `dart:convert` base64 encoder after reading file bytes.

11. **Days Left calculation (AMC):** `daysLeft = endDate.difference(DateTime.now()).inDays`. If ≤ 0, show "Expired". If ≤ 60 and > 0, show in orange.

12. **Weekly overview dots (Attendance):** Generate last 7 days from today. For each technician × each day, look up attendance record and map to colored dot.