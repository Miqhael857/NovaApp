# Submission checklist — NovaWallet Send & Save

**Deadline: 2:00 PM, Thursday 17 September 2026.** The PowerPoint is what gets
submitted; the repo link lives inside it.

This file is working notes, not part of the deliverable. Delete it before the
final push if you'd rather a reviewer didn't see it.

---

## 1. Blocked on you — I cannot do these

| # | What | Why it needs you |
|---|---|---|
| B1 | **Your full name** | The email says *"Save your work with your name."* The deck is currently `NovaWallet_Send_and_Save_[YOUR_FULL_NAME].pptx`, and slide 1 has the same placeholder. Send it and I regenerate in seconds. |
| B2 | **GitHub repo URL** | There is no git remote and `gh` is not installed, so I cannot create the repo. Create it on github.com (private is fine — grant access to the invite emails) and paste me the URL. |
| B3 | **Permission to push** | Pushing is outward-facing. I will add the remote but will not push until you say go. |
| B4 | **Deck review** | Read the 10 slides and the speaker notes. They are my words in your voice — change anything that doesn't sound like you before you present it on the 22nd. |

## 2. Deliverables from the brief

| # | Deliverable | State |
|---|---|---|
| D1 | Git repo on GitHub | **Blocked** — 6 local commits, no remote (B2, B3) |
| D2 | `README.md` | **Done** — architecture, state management, offline/sync design, trade-offs, assumptions, how to run |
| D3 | `AI_USAGE.md` | **Done** — 3 real prompts, 3 cases where the model was wrong including one fabricated-evidence case |
| D4 | Widget tests for Send **and** NovaSave contribution | **Partial** — Send flow covered to the Confirm step; contribution tests not written |
| D5 | Integration test: offline queue then sync | **Not done** — needs `integration_test/` and a device |
| D6 | Runs with one command | **Done** — `flutter run`, no codegen, no backend |
| D7 | PowerPoint with the repo link | **Done bar placeholders** (B1, B2) |

## 3. Functional requirements

| # | Requirement | State |
|---|---|---|
| F1 | Wallet home: ₦ from kobo, lazy list, pull-to-refresh | **Done** — `SliverList.builder`, `RefreshIndicator` wired to the sync engine |
| F2 | Send Money, idempotency key per attempt | **Done** — key minted once entering Confirm, shown as the reference |
| F3 | NovaSave: create a goal, contribute, progress | **In progress** — goal store + seeded goals + goals list + contribute sheet written and compiling; **create-goal is still a placeholder**; none of it verified on a device yet |
| F4 | Offline: queued, shown as "Pending — will send when back online" | **Done** — Home strip, goal detail strip, result screen |
| F5 | Sync on reconnect, exactly once | **Done** — outbox + idempotent receiver, 25 tests |

## 4. Hard constraints

| # | Constraint | State |
|---|---|---|
| C1 | Integer kobo, no float drift | **Done** — `Kobo`, 19 tests |
| C2 | Queue survives restart, never double-sends | **Done** — `in_flight` rows replay with the same key |
| C3 | Semantics + system font scale | **Mostly** — Send controls, transaction rows, goal cards, status by icon+word. Not audited with TalkBack |
| C4 | Lazy lists | **Done** — `SliverList.builder`, deliberately not `shrinkWrap` |
| C5 | No sensitive data in plain SharedPreferences | **Done by omission** — SharedPreferences is unused; no token is mocked. `flutter_secure_storage` is a dependency but unused |

## 5. Known issues right now

- **2 router tests failing** (`starts on Home and switches tabs`, `goal detail reads the goal id`). Both call `pumpAndSettle` on screens that now show a `CircularProgressIndicator` while the data layer loads — an indeterminate spinner never settles. Fix is a non-animating placeholder, not a test hack.
- **Profile route is commented out** in `app_router.dart` while the shell still renders a Profile destination. Tapping that tab would fail.
- **Uncommitted work**: `goal_store.dart`, `contribute_provider.dart`, both NovaSave views, plus your router/routes edits.
- Home's balance is still a literal (`Kobo.fromNaira(20000)`), not read from the ledger.
- `GoalDetailiew` is missing a "V" — cosmetic, but a reviewer reads class names.

## 6. Verify before submitting

```bash
flutter analyze          # expect: No issues found
flutter test             # expect: all pass
flutter run              # sanity check on a device
```

Then the demo rehearsal, on the **Android** emulator (iOS Simulator has no real
airplane mode):

1. Airplane mode on → Send ₦5,000 → "Pending — will send when back online"
2. Kill the app → reopen → still pending
3. Airplane mode off → syncs once, balance debited once
4. Backup if the emulator misbehaves: **Profile → Simulate offline**

## 7. Order of work if time is short

1. Fix the 2 failing tests and the Profile route (~15 min)
2. Commit, then B1/B2/B3 — get the repo up and the deck finalised
3. Create-goal screen, then a contribution widget test
4. Integration test — last, because the README already documents its absence honestly

The brief says it would *"rather see good judgment about what to prioritize than
a rushed attempt at everything"*, so anything left undone should stay documented
in the README rather than half-built.
