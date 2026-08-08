# RYSE CRM — Mobile

A full-featured, AI-driven sales CRM mobile app built with **Flutter**, designed
in the spirit of the Salesforce mobile experience: record-centric navigation,
a sales Path, Kanban pipeline, and an Einstein-style AI copilot.

<p>
  <em>Android · iOS · 100% offline demo (no backend required)</em>
</p>

## 📸 Screenshots

Dark, RYSE-branded UI (near-black + brand purple, the "ryse" triangle mark).

| Login | Dashboard | Pipeline (Kanban) | Leads |
|---|---|---|---|
| ![Login](docs/screenshots/01_login.png) | ![Dashboard](docs/screenshots/02_dashboard.png) | ![Pipeline](docs/screenshots/03_pipeline.png) | ![Leads](docs/screenshots/04_leads.png) |

| Opportunity (Sales Path) | Lead detail | RYSE AI | Tasks |
|---|---|---|---|
| ![Opportunity](docs/screenshots/05_opportunity.png) | ![Lead](docs/screenshots/06_lead_detail.png) | ![Assistant](docs/screenshots/07_assistant.png) | ![Tasks](docs/screenshots/08_tasks.png) |

| Reports & Analytics | Calendar | Menu |
|---|---|---|
| ![Reports](docs/screenshots/09_reports.png) | ![Calendar](docs/screenshots/10_calendar.png) | ![Menu](docs/screenshots/11_menu.png) |

_Regenerate any time: `flutter test test/screenshots/screenshots_test.dart --update-goldens`_

## ✨ Features

### Authentication
- Salesforce-style login screen with email/password validation, show/hide
  password, "remember me", and friendly error states
- Session persistence — reopening the app skips login until you log out
- One-tap demo account fill on the login page

### Home Dashboard
- Personal greeting + date header
- KPI cards: open pipeline, won this quarter, tasks due today, hot leads
- **RYSE AI Insights** carousel: deal-at-risk alerts, most-likely-to-close,
  top-scored lead, overdue follow-ups
- Pipeline-by-stage bar chart (fl_chart)
- Today's tasks with one-tap complete, and a recent activity feed

### Records (full CRUD)
| Object | Highlights |
|---|---|
| **Leads** | Status & rating pills, AI score (0–100), filters, **Salesforce-style conversion** → contact + account + opportunity |
| **Contacts** | Account linkage, related opportunities & tasks |
| **Accounts** | Company profile, open-pipeline rollup, related contacts/deals, quick-create contact & deal |
| **Opportunities** | **Chevron sales Path** with *Mark Stage Complete*, forecast fields (probability, expected revenue), close won/lost flows |
| **Tasks** | Overdue/Today/Upcoming grouping, priorities, related-record linkage, complete/reopen |

### Pipeline (Kanban)
- Column per stage with deal counts and totals
- **Long-press & drag deals between stages**, or use the stage picker sheet
- Summary bar: total, weighted total, open deal count

### RYSE AI Assistant
- Chat copilot answering questions about your live CRM data:
  pipeline summary, deals at risk, daily plan, lead ranking, forecast
- Suggestion chips, typing indicator, deterministic on-device engine
  (swap in a real LLM endpoint in `assistant_engine.dart`)

### More
- **Global search** across every object, grouped by type
- **Notifications** center with unread badges
- Record activity timelines + log call/email/meeting/note from any record
- Profile & logout; reset demo data from the Menu tab

## 🔌 Backend connectivity (techbanq_crm)

The app runs in **two modes**, chosen on the login screen:

- **Demo** — fully offline, seeded sample data (no backend needed).
- **Live Server** — connects to the [`techbanq_crm`](https://github.com/mohsinqureshii/techbanq_crm)
  tRPC backend. Enter the server URL, sign in with real credentials, and every
  screen reads and writes live data.

The client speaks the backend's tRPC/superjson protocol directly over HTTP with
cookie-based sessions (`crm_access_token` / `crm_refresh_token`), persisted so
the app stays signed in across restarts.

**Wired endpoints** (`lib/data/api/ryse_api.dart`):

| Area | Procedures |
|---|---|
| Auth | `auth.login`, `auth.logout`, `auth.me` |
| Leads | `leads.list/create/update/delete/convert` |
| Contacts | `contacts.list/create/update/delete` |
| Accounts | `accounts.list/create/update/delete` |
| Opportunities | `opportunities.list/create/update/moveStage/close/delete` |
| Pipeline | `pipeline.getStages` |
| Activities & Tasks | `activities.myTasks/list/create/update/complete/delete` |
| Dashboard | `dashboard.overview`, `dashboard.activityFeed` |
| Notifications | `notifications.list/unreadCount/markRead/markAllRead` |
| Search | `search.global` |

Data flows through one hub, `CrmStore`, which transparently switches between
the demo seed and the live API — so all 40+ screens work unchanged in either
mode. Backend records (integer keys) are mapped to the app's models in
`lib/data/api/remote_mappers.dart`.

### Running the backend locally

```bash
# in the techbanq_crm repo
createdb techbanq_crm
export DATABASE_URL=postgres://user:pass@localhost:5432/techbanq_crm
export JWT_SECRET=$(openssl rand -base64 48)
pnpm install
pnpm db:migrate && pnpm db:seed
node scripts/create-admin.mjs you@example.com 'your-password'
pnpm dev            # serves tRPC at http://localhost:3000/api/trpc
```

Then in the app: **Live Server** → URL `http://10.0.2.2:3000` (Android emulator)
or `http://localhost:3000` (iOS sim/desktop) → sign in with the admin you
created.

### Integration test

`test/backend_integration_test.dart` exercises the Dart client end-to-end
against a running backend. It is skipped by default and runs only when
credentials are supplied:

```bash
flutter test test/backend_integration_test.dart \
  --dart-define=RYSE_API_URL=http://localhost:3000 \
  --dart-define=RYSE_TEST_EMAIL=you@example.com \
  --dart-define=RYSE_TEST_PASSWORD='your-password'
```

## 🏗 Architecture

```
lib/
├── main.dart               # Providers + app bootstrap
├── app.dart                # Root gate: splash → login → shell
├── core/
│   ├── theme/              # SLDS-inspired design tokens & Material theme
│   ├── utils/              # Formatters (currency, relative dates…)
│   └── widgets/            # Shared UI (record icons, KPI cards, pills…)
├── data/
│   ├── api/                # tRPC client, typed RyseApi, backend↔model mappers
│   ├── models/             # Lead, Contact, Account, Opportunity, Task…
│   ├── crm_store.dart      # Central store: demo + live backend, CRUD, metrics
│   ├── demo_data.dart      # Seed dataset (dates relative to today)
│   └── services/           # AuthProvider (demo + server login, session)
└── features/
    ├── auth/  home/  leads/  contacts/  accounts/
    ├── opportunities/      # List, Kanban, detail w/ sales Path
    ├── tasks/  assistant/  search/  notifications/
    ├── menu/  settings/  shared/  shell/
```

- **State**: `provider` (`ChangeNotifier`) — `AuthProvider` + `CrmStore`
- **Persistence**: `shared_preferences` JSON snapshots (swap for a REST/GraphQL
  sync layer in production — all mutations flow through `CrmStore`)
- **Charts**: `fl_chart`

## 🚀 Getting Started

```bash
flutter pub get
flutter run
```

### Demo credentials

| Email | Password |
|---|---|
| `demo@ryse.app` | `RyseDemo1` |
| `maq@techbanq.net` | `RyseDemo1` |

(Or just tap the **demo access** card on the login screen.)

### Tests & analysis

```bash
flutter analyze   # 0 issues
flutter test      # 22 tests: auth, store CRUD, conversion, search, login flow
```

## 🎨 Design language

The real RYSE brand — a dark, focused workspace:
- **Charcoal-black surfaces** (`#0A0D14` scaffold, `#141821` cards) with the
  **RYSE purple accent** (`#8B5CF6` / `#7C3AED`)
- The actual **RYSE logo**: the purple apex-left triangle mark + lowercase
  "ryse" wordmark (see `lib/core/widgets/ryse_logo.dart`)
- Vibrant record-type colors that pop on dark (leads rose, contacts violet,
  accounts blue, opportunities amber, tasks green)
- Chevron sales Path, record detail tabs (Details / Related / Activity),
  bottom navigation with a global “+” create sheet
- Purple → indigo gradient for everything AI

## 📱 Platforms

- Android (`com.ryse.ryse_crm`)
- iOS

---

Built with Flutter 3.32 · Dart 3.8
