# CareCircle

An iPhone-first coordination app for adult children managing aging parents.

## Overview

CareCircle replaces the chaos of scattered notes, texts, photos, and spreadsheets with a unified operating layer for:
- **Appointments** - Track medical visits with prep checklists and notes
- **Tasks** - Coordinate who's responsible for what
- **Documents** - Store and organize important files in one secure vault
- **Family Collaboration** - Assign roles and keep everyone aligned
- **Shared Finances** - Track contributions and expenses transparently

## Project Status

**Phase 1 (MVP)** - Currently in development

### Completed
✅ Full Swift Data model with 8 core entities  
✅ 5-tab navigation structure  
✅ Today dashboard with next appointment, critical tasks, and recent updates  
✅ Finances tab with shared expense tracking  
✅ Calendar view for appointments  
✅ Vault for document organization  
✅ Family view for member management and task assignment  
✅ Basic CRUD operations for all entities  
✅ Airwallex-ready data model (fields reserved for future integration)

### Next Steps
- [ ] Appointment detail view with checklist management
- [ ] Document scanning with VisionKit
- [ ] Emergency packet PDF generator
- [ ] Photo/voice note capture for appointments
- [ ] Task filtering and sorting
- [ ] Onboarding flow
- [ ] Sample data generator for testing

## Architecture

### Data Model (Swift Data)

```
ParentProfile (root entity)
├── Appointments
├── Tasks
├── Documents
├── FamilyMembers
│   └── ExpenseAccount (1:1)
├── Expenses
└── UpdateFeedItems
```

### Key Design Decisions

1. **Swift Data for persistence** - Native, type-safe, and works offline
2. **Single parent profile for MVP** - Simplifies scope while proving value
3. **Manual expense tracking first** - Validates financial feature before Airwallex integration
4. **Reserved fields for Airwallex** - `airwallexUserID`, `airwallexAccountID`, `airwallexTransactionID` ready for Phase 2
5. **Liquid Glass design language** - Uses `.ultraThinMaterial` for calm, modern feel

## Installation

1. Open Xcode 15.0 or later
2. Create a new iOS App project named "CareCircle"
3. Copy all files into your project maintaining the folder structure:
   - `CareCircleApp.swift` → Root
   - `ContentView.swift` → Root
   - `Models/*.swift` → Models group
   - `Views/*.swift` → Views group
4. Ensure Swift Data is available (iOS 17.0+)
5. Build and run on simulator or device

## Usage

### First Launch

The app will show an empty state on the Today tab. Tap **"Create Profile"** to generate sample data:
- One parent profile (Mom Alvarez)
- One upcoming appointment
- Three critical tasks
- Two recent updates

### Adding Data

- **Appointments**: Calendar tab → + button
- **Documents**: Vault tab → + menu → Add Document or Scan Document
- **Family Members**: Family tab → + button (creates expense account automatically)
- **Expenses**: Finances tab → + button on Recent Expenses card

### Finances Feature

Each family member gets an `ExpenseAccount` that tracks:
- Current balance
- Total contributed
- Total spent

Expenses can be assigned to family members and categorized for reporting.

## Future Integrations

### Phase 2: Airwallex

When ready to integrate Airwallex:

1. Set up Airwallex backend API
2. Implement KYC flow for primary caregiver
3. Create Airwallex accounts and map to `airwallexAccountID` fields
4. Enable funding flows (bank transfer, card)
5. Issue virtual cards for shared home account
6. Sync transactions to `Expense` records with `airwallexTransactionID`

### Phase 3: AI Features

- Appointment note summarization
- Task extraction from notes
- Document OCR and categorization
- Weekly recap generation

## Design Principles

- **Calm, not gamified** - Serious and trustworthy tone
- **Fast capture** - Minimal friction to add information
- **Offline-first** - Core features work without network
- **Privacy-focused** - All data stored locally until collaboration requires sync
- **AI is supportive** - Never authoritative or diagnostic

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## License

Proprietary - All rights reserved

---

**Last updated**: March 17, 2026  
**Working owner**: Vernon + Codex
