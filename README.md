# RYSE CRM — Mobile

A full-featured, AI-driven sales CRM mobile app built with **Flutter**, designed
in the spirit of the Salesforce mobile experience: record-centric navigation,
a sales Path, Kanban pipeline, and an Einstein-style AI copilot.

<p>
  <em>Android · iOS · 100% offline demo (no backend required)</em>
</p>

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
│   ├── models/             # Lead, Contact, Account, Opportunity, Task…
│   ├── crm_store.dart      # Central store: CRUD, search, metrics, persistence
│   ├── demo_data.dart      # Seed dataset (dates relative to today)
│   └── services/           # AuthProvider (login + session)
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

Modeled on the Salesforce Lightning Design System:
- Action blue `#0176D3` on deep navy `#032D60`
- SLDS object colors (leads coral, contacts violet, accounts periwinkle,
  opportunities amber)
- Chevron sales Path, record detail tabs (Details / Related / Activity),
  bottom navigation with a global “+” create sheet
- Einstein-style purple gradient for everything AI

## 📱 Platforms

- Android (`com.ryse.ryse_crm`)
- iOS

---

Built with Flutter 3.32 · Dart 3.8
