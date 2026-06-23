# CareCircle

An iPhone-first coordination app for adult children managing aging parents.

## Overview

CareCircle replaces the chaos of scattered notes, texts, photos, and spreadsheets with a unified operating layer for:
- **Appointments** - Track medical visits with prep checklists, notes, and AI summaries
- **Tasks** - Coordinate who's responsible for what with priority levels and due dates
- **Documents** - Store, scan, and organize important files in one secure vault
- **Family Collaboration** - Assign roles, post updates, and keep everyone aligned
- **Shared Finances** - Track contributions and expenses transparently
- **Emergency Readiness** - Generate a shareable PDF packet with critical care info and packet-ready document references
- **Health Monitoring** - Apple Health vitals read from the current iPhone
- **On-Device AI** - Briefings, note summaries, and task extraction, with an off-by-default cloud fallback for unsupported devices

## Project Status

**Phase 1 (MVP)** - Complete

### Completed
- Full SwiftData model with 8 core entities and cascade deletion
- 6-tab navigation (Today, Calendar, Vault, Family, Finances, Settings)
- Adaptive layout: iPhone tabs + iPad sidebar
- Today dashboard with parent card, next appointment, critical tasks, activity feed
- Calendar with upcoming/past appointments, grouped by date, search
- Appointment detail with interactive checklist, notes, AI summarization, task extraction
- Document vault with scan (VisionKit), file import, category/domain filters, packet metadata, and PDF preview
- Family view with roles, task assignment, filtered task views, member detail
- Finances with shared expense tracking, contribution accounts, category breakdown
- Emergency packet PDF generator with share/export and critical document references
- On-device AI (Apple FoundationModels) for daily briefings, note summaries, task extraction, document categorization; optional cloud note-summary fallback for devices that cannot run Apple Intelligence
- HealthKit integration with heart rate, blood oxygen, steps, blood pressure, HRV, and 7-day chart
- Local notifications for appointments (1hr before) and tasks (8 AM on due date)
- OCR text extraction from scanned documents (Vision framework)
- Activity feed with automatic logging for all care actions
- 4-step onboarding flow (account, region, parent info, confirmation)
- US/Canada regional document templates for health coverage, insurance, tax, banking, and ID records
- Demo mode with rich sample data
- Welcome screen with Get Started / Try Demo paths
- Settings with local storage, notification management, about page
- Unit test coverage for models, onboarding, regional documents, notifications, and emergency packets
- UI test suite for navigation and core flows

### Next Steps
- [x] App icon design
- [ ] Device testing and polish
- [ ] TestFlight beta distribution
- [ ] Widget for Today dashboard
- [ ] Apple Watch companion
- [ ] Multi-parent profile support

## Architecture

### Tech Stack
- **UI**: SwiftUI with Liquid Glass design language
- **Persistence**: SwiftData with local on-device storage
- **AI**: Apple FoundationModels on device, with an off-by-default summary fallback endpoint for ineligible devices
- **Health**: HealthKit (read-only)
- **Scanning**: VisionKit (document camera) + Vision (OCR)
- **Notifications**: UNUserNotificationCenter (local)
- **PDF**: Core Graphics (emergency packet generation)

### Data Model (SwiftData)

```
ParentProfile (root entity)
├── Appointments (cascade delete)
│   └── ChecklistItems (codable, embedded)
├── Tasks (cascade delete)
├── Documents (cascade delete)
├── FamilyMembers (cascade delete)
│   ├── ExpenseAccount (1:1)
│   └── AssignedTasks (nullify on delete)
├── Expenses (cascade delete)
└── UpdateFeedItems (cascade delete)
```

### Key Design Decisions

1. **SwiftData for persistence** - Native, type-safe, works offline, local-first
2. **Single parent profile for MVP** - Simplifies scope while proving value
3. **On-device-first AI** - Apple FoundationModels keeps core AI local, with any cloud summary path opt-in and disabled by default
4. **Liquid Glass design** - `.ultraThinMaterial` cards for calm, modern feel
5. **Explicit relationship inverses** - Ensures reliable cascade deletion
6. **`asyncRun()` helper** - Disambiguates Swift concurrency `Task` from the SwiftData `Task` model

### Project Structure

```
CareCircle/
├── CareCircleApp.swift          # Entry point, ModelContainer setup
├── ContentView.swift            # AppRouter, MainContentView, tabs/sidebar
├── Models/                      # 9 SwiftData models
├── Views/                       # 17 view files
├── Helpers/                     # 10 utility files
├── Assets.xcassets/             # App icon, accent color
├── CareCircleTests/             # 7 unit test files (41 tests)
├── CareCircleUITests/           # 2 UI test files
└── project.yml                  # XcodeGen project definition
```

## Code Signing

**Personal Team (free):** Debug builds use empty entitlements so Xcode can sign with a Personal Team. HealthKit and local notifications still work.

**Paid Apple Developer ($99/year):** Required for HealthKit and TestFlight. Register `com.vernoncampbell.carecircle` with the required capabilities and use Automatic Signing.

## Installation

### With XcodeGen (recommended)
1. Install XcodeGen: `brew install xcodegen`
2. Clone the repo
3. Run `xcodegen generate` in the project root
4. Open `CareCircle.xcodeproj`
5. Build and run on simulator or device

### Manual
1. Open the existing `CareCircle.xcodeproj` in Xcode 26+
2. Build and run

## Usage

### First Launch
The app shows a Welcome screen with two paths:
- **Get Started** - 4-step onboarding to create your care circle
- **Try the Demo** - Pre-loaded sample data to explore features

### Navigation
- **Today** - Dashboard with parent status, next appointment, critical tasks, activity feed
- **Calendar** - Upcoming and past appointments with search
- **Vault** - Document storage with scan, import, pin, category/domain filters, expiry tracking, and packet metadata
- **Family** - Member management, task assignment, and coordination
- **Finances** - Expense tracking, contributions, and category breakdown
- **Settings** - Account, local storage, notifications, about

### Emergency
Tap the red emergency button on the Today screen for quick access to:
- Call 911
- Call emergency contact
- Generate and share an emergency info PDF

## Requirements

- iOS 26.0+
- Xcode 26.0+
- Swift 5.9+

## License

Proprietary - All rights reserved

---

**Last updated**: April 7, 2026
**Working owner**: Vernon
