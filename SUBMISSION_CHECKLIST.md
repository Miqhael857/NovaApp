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
| D1 | Git repo on GitHub | **Blocked** — committed locally, no remote (B2, B3) |
| D2 | `README.md` | **Done** — architecture, state management, offline/sync design, trade-offs, assumptions, how to run |
| D3 | `AI_USAGE.md` | **Done** — 3 real prompts, 3 cases where the model was wrong including one fabricated-evidence case |
| D4 | Widget tests for Send **and** NovaSave contribution | **Done** — Send flow covered to the Confirm step; 5 contribution tests covering what the sheet shows, the integer progress maths, and every case where it refuses to submit |
| D5 | Integration test: offline queue then sync | **Done** — `integration_test/offline_sync_test.dart`: queue offline → kill the app → relaunch on the same database files → reconnect → one ledger entry, one debit. **Passes on the iOS simulator** |
| D6 | Runs with one command | **Done** — `flutter run`, no codegen, no backend |
| D7 | PowerPoint with the repo link | **Done bar placeholders** (B1, B2) |

## 3. Functional requirements

| # | Requirement | State |
|---|---|---|
| F1 | Wallet home: ₦ from kobo, lazy list, pull-to-refresh | **Done** — `SliverList.builder`, `RefreshIndicator` wired to the sync engine |
| F2 | Send Money, idempotency key per attempt | **Done** — key minted once entering Confirm, shown as the reference |
| F3 | NovaSave: create a goal, contribute, progress | **Done** — goals list with integer progress, goal detail, a contribute sheet that queues through the same outbox, and a create-goal screen (name, target, date, with the monthly figure computed in integer kobo). Not yet verified on a device |
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

*Analyze clean, all 65 tests passing, plus the integration test passing on the iOS simulator.*

- Send validates against the constant `kAvailableBalance`, not the live available
  balance Home now shows. The two can disagree; wiring Send to
  `availableBalanceProvider` is the next change.
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

1. B1/B2/B3 — get the repo up and the deck finalised. Nothing else matters if
   there is no submission.
2. Restore the Profile route (~5 min) so the third tab cannot crash.
3. Rehearse the airplane-mode demo on the **Android** emulator — the iOS
   simulator has no real airplane mode, so the live demo on the 22nd needs it.

The brief says it would *"rather see good judgment about what to prioritize than
a rushed attempt at everything"*, so anything left undone should stay documented
in the README rather than half-built.
