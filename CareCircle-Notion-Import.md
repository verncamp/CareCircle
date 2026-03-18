# CareCircle Product Plan

Last updated: March 16, 2026

## Product thesis

Build an iPhone-first coordination app for adult children managing aging parents. The product replaces the current mess of Notes, texts, photos, spreadsheets, and memory with one shared operating layer for appointments, documents, tasks, and emergency readiness.

## Strategic angle

This project is based on a Camillo-style market lens: visible pain, widespread workarounds, no beloved winner, and strong emotional urgency. The wedge is not "healthcare" in general. The wedge is long-distance family caregiving administration.

- Primary user: adult child, usually 35-55, coordinating care for one aging parent.
- Secondary users: siblings, aides, family friends, or one trusted helper.
- Core pain: fragmented information and unclear ownership create dropped tasks, repeated work, and stress during appointments or emergencies.
- Why iOS first: family organizers and higher-intent payers are common on iPhone, and the product benefits from polished native UI, document scanning, and offline reliability.

## Jobs to be done

1. Know what matters today without digging through messages.
2. Keep family members aligned on who owns what.
3. Store the right documents where they can be found fast.
4. Turn appointment notes into follow-up tasks and records.
5. Generate an emergency packet instantly.

## Product principles

- Calm, serious, and trustworthy. This is not a gamified wellness app.
- AI is supportive, not authoritative. No diagnosis or medical advice.
- Core workflows work without AI.
- Fast capture beats deep setup.
- One parent profile first. Multi-parent support can come later.

## MVP scope

| Area | Included in v1 | Deferred |
| --- | --- | --- |
| Home | Today dashboard, urgent tasks, recent updates, next appointment | Widgets, watch companion, passive monitoring |
| Appointments | Appointment details, prep checklist, notes, AI summary to tasks | Provider integrations, telehealth |
| Documents | Vault, scan, categorize, pin key items, search | OCR-heavy automation pipelines, insurer portals |
| Collaboration | Family roles, task assignment, update feed | Full chat, external caregiver marketplace |
| Emergency readiness | Emergency packet PDF with share/export | Hospital integrations, live fax workflows |

## Information architecture

- Today
- Calendar
- Vault
- Family
- More

## Wireframe notes

### Today

```text
Mom Alvarez
Stable today                               [Emergency]
Tue, Mar 16

Next up
10:30 AM Cardiology follow-up
Bring insurance + med list
                                              [Open]

Critical tasks
[ ] Refill blood pressure meds
[ ] Upload discharge summary
[ ] Confirm ride for Thursday
                                           [See all]

Recent updates
Sarah: "Vitals looked normal."
You: "Scanned lab results."
                                           [+ Update]
```

### Appointment detail

```text
Cardiology Follow-up
Thu, Mar 18   10:30 AM
Clinic: St. Mary's

Checklist
[x] Insurance card
[x] Medication list
[ ] Bring last lab report

Notes
"Shortness of breath improved..."
                     [Record] [Type] [Scan]

AI Summary
- Schedule echo in 2 weeks
- Monitor dizziness
- New dosage starts tonight
                          [Save as tasks]
```

### Vault

```text
Vault
[Search documents...]

Pinned
Insurance card
Medication list
Power of attorney

Recent
Lab Results - Mar 2026
Hospital Discharge Summary
Vaccination Record
                                 [+ Scan Doc]
```

### Family

```text
Family Circle
4 members

Sarah        Transportation
You          Medical admin
Daniel       Bills + insurance
Aide         Daily check-ins

Open tasks
Refill meds           Assigned to You
Appeal insurance      Assigned to Daniel
Schedule PT           Unassigned
                                  [+ Assign]
```

## AI strategy

Use AI selectively. It should reduce clerical burden, not become the reason the product exists.

- Use AI for: note summarization, OCR cleanup, task extraction, weekly recap, and document labeling suggestions.
- Do not use AI for: diagnosis, treatment recommendations, medication safety claims, or emergency advice.
- Implementation direction: build the core app in SwiftUI, keep AI behind a small backend, and avoid making Apple Foundation Models a hard dependency.

## Design direction

- Native iOS feel with Liquid Glass treatment where it supports clarity.
- Large translucent cards, restrained motion, strong status hierarchy.
- A persistent Emergency affordance in top-level screens.
- One accent system for calm, warning, and urgent states.

## Monetization hypothesis

- Free tier: one parent profile, limited document storage, basic tasking.
- Paid family plan: shared collaborators, AI summaries, emergency packet export, expanded storage, PDF history.
- Potential later B2B2C wedge: elder law, care coordinators, discharge planners, or concierge medicine groups.

## Open questions

1. What exact caregiver segment is most willing to pay: siblings coordinating remotely, solo adult daughters, or concierge-heavy households?
2. Is document organization or appointment follow-up the sharper entry point?
3. How much of the MVP should be offline-first?
4. What legal/privacy posture is needed before recruiting early testers?
5. Which naming direction is strongest: CareCircle, ParentOps, KinLedger, or something less clinical?

## 30-day execution plan

| Week | Objective | Output |
| --- | --- | --- |
| 1 | Validate the wedge with interviews and review mining | 10-15 caregiver interviews, pain map, language patterns |
| 2 | Build high-fidelity flows and data model | UI flows, object model, MVP scope lock |
| 3 | Implement iOS prototype in SwiftUI | Tappable prototype or working local build |
| 4 | Test with target users and tighten the positioning | Feedback report, revised onboarding, pricing assumptions |

## Immediate next tasks

1. Decide the final naming placeholder for the project file set.
2. Write the user interview guide for caregiver discovery calls.
3. Create high-fidelity wireframes for Today, Appointment Detail, Vault, Family, and Emergency Packet.
4. Define the first-pass data model in Swift.
5. Choose the AI approach: OpenAI API through backend versus no AI in the first build.

## Context for the next session

The current recommendation is to pursue the caregiving coordination wedge rather than a broad health or senior app. The product should launch as a calm operational layer for adult children managing aging parents, with AI limited to clerical assistance. The next high-value step is customer discovery, followed by high-fidelity wireframes and a SwiftUI prototype.
