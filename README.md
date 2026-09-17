# NovaWallet Mobile — Send & Save

Take-home for the FirstBank Digital Factory **Frontend Engineer — Mobile (Flutter)** role.

Two journeys from the fictional NovaPay super-app: **sending money** from the
wallet, and **NovaSave** goals. There is no backend — the app ships a fake one —
and the interesting part is what happens when the network isn't there.

**Flutter 3.38.5 · Dart 3.10.4 · 52 tests passing · `flutter analyze` clean**

## Run it

```bash
flutter pub get
flutter run          # one command, no code generation, no backend to start
flutter test         # 52 unit + widget tests
```

The fake server seeds itself on first launch with ₦248,350.75.

---

## The problem worth solving

A queued transfer must **survive the app being killed** and must **never be sent
twice**. Everything below is arranged around that.

### Exactly once, honestly

A client cannot guarantee exactly-once delivery on its own. What this app does is
combine two halves that together produce the effect:

1. **The client promises _at least once_.** Tapping *Confirm and send* writes a row
   to a SQLite **outbox before any network call**. The row is only cleared once
   the server has answered. If the process dies mid-send the row is still there,
   still `in_flight`, and gets sent again.
2. **The server promises _no duplicates_.** Every attempt carries the same
   `idempotency_key`. The fake API records every key it has handled and replays
   the original outcome instead of moving money twice — re-checking the key
   *inside* the transaction, so two concurrent replays still process once.

Neither half is sufficient alone, and saying so is the point.

### The queue

`outbox`: `id, idempotency_key UNIQUE, type, payload, status, attempts, last_error, created_at`

`pending → in_flight → succeeded | failed`

`itemsToSend()` deliberately returns **both** `pending` and `in_flight` rows: a row
left `in_flight` means the app died without hearing back, so it must be retried
with the same key.

`SyncEngine.run()` is **single-flight** — a connectivity event arriving during a
pull-to-refresh joins the running pass rather than replaying the queue twice. On a
network failure it reverts the row to `pending` and **stops**; there is no retry
loop and no backoff timer. Triggers are: app start, connectivity regained,
pull-to-refresh, and the manual *Sync now* on Profile.

A business rejection (limit, insufficient funds) is **final** — marked `failed`
with a reason, never retried automatically.

### One key per attempt

The key is minted once, on entering the Confirm step, and shown to the user as the
transfer reference (`NP-7F3A-91C2`). Stepping back to Amount and forward again
keeps the same key — there is a test for exactly that, because a new key there
would silently become a second transfer.

---

## Architecture

```
lib/
  core/money/kobo.dart          integer-kobo value type
  core/theme/                   design tokens from the artboards
  data/local/app_database.dart  two SQLite databases: client and "server"
  data/local/outbox_store.dart  the queue
  data/remote/fake_novapay_api.dart  idempotent receiver
  data/sync/sync_engine.dart    single-flight replay
  data/providers.dart           the one place the data layer is constructed
  presentation/features/...     WalletHome, Send, NovaSave, Profile
  presentation/shared/          AppText, AppScaffold, AppButton, balance card
```

The client and the fake server are **separate database files** on purpose: the
client cannot read or repair the server's record of what it has already processed,
which keeps the boundary honest.

### State management — Riverpod 3

Chosen over Bloc for the amount of ceremony per piece of state, and used without
code generation so the whole thing is readable top to bottom.

- `sendFlowModelProvider` holds the in-progress transfer. It is **not** passed
  through the router's `extra`: `extra` is null after Android restarts a killed
  app or when a link is opened directly, and the cast on the far side would throw.
- `sendStepProvider` holds which of the three steps is showing. The Send flow is
  one route and one view, so the step is genuinely state.
- `novaPayServicesProvider` is a `FutureProvider` that opens both databases, seeds
  the server once, and builds the outbox, API and sync engine together. They are
  one unit; splitting them into separate providers would mean each awaiting the
  others for no benefit.
- `dataLayerConfigProvider` exists so tests can point at temp files with the ffi
  factory and zero latency.

### Money

`Kobo` wraps a whole `int`. No `double` touches an amount anywhere: formatting uses
integer division and manual thousands grouping, parsing is string → kobo and never
calls `double.parse`, and goal progress is `value * 100 ~/ total` clamped to 0–100.

---

## Constraints from the brief

| Constraint | Where |
|---|---|
| Integer kobo everywhere | `core/money/kobo.dart`, 19 tests incl. the `0.1 + 0.2` case |
| Queue survives restart, never sends twice | outbox + idempotency key + idempotent receiver; 9 outbox, 8 API, 8 sync tests |
| Lazy lists | `TransactionSliverList` uses `SliverList.builder` — deliberately *not* `ListView.builder` with `shrinkWrap`, which lays out every row anyway |
| Accessibility | `Semantics` on the Send controls, `MergeSemantics` per transaction row, status shown by icon **and** word, never colour alone |
| System font scale | `AppText` keeps line height as a ratio (`lineHeight / fontSize`), buttons use `minHeight` not fixed heights |
| No sensitive data in plain storage | `SharedPreferences` is not used anywhere in the app. No auth token is mocked, so nothing sensitive is stored at all; if one existed it would go in `flutter_secure_storage` (already a dependency) |

---

## Assumptions

- **Tier 1 limit of ₦50,000.00 per transfer** — assumed, not a real FirstBank figure.
- **Name enquiry is faked** from a small directory, because a real NIBSS lookup is
  an online call and the flow has to work offline.
- **Contributions** are funded from the wallet and go through the same queue.
- **Account numbers are stored in the outbox payload.** Under NDPA 2023 that is a
  real consideration; only the last four digits are ever displayed, and the next
  step would be SQLCipher for the client database.
- The server rejects above balance or above the daily limit, and those rejections
  are final.

## Trade-offs, and what is not built

Stated plainly, because the brief asks for judgment about priorities rather than a
rushed attempt at everything:

- **NovaSave create and contribute are not implemented.** The screens and the goal
  model exist; the contribution path through the queue does not. The queue already
  supports it (`AppDatabase.typeContribution`, and the API has `contributeToGoal`),
  so it is wiring rather than design.
- **No integration test yet.** The submit path — tap Confirm, write the row, run a
  pass — needs real sqflite I/O, which a widget test's zone never completes (I
  verified this directly). It belongs in `integration_test/` on a device, and the
  widget test stops at the last thing it can honestly prove.
- **`ShellRoute`, not `StatefulShellRoute`**, so the tabs share one navigation
  stack. Chosen for familiarity, knowing the cost.
- Balance on Home is still a literal rather than read from the server ledger.
- Stretch goals (sync notification, Hausa/Yoruba, golden tests, biometrics) are not
  attempted.

## Demonstrating the offline path

Airplane mode on an Android emulator is the real demo. **Profile → Simulate
offline** is the backup and exercises the same code path: turn it on, send a
transfer, see *"Pending — will send when back online"* on Home, kill the app,
reopen it, turn it off, and watch the queue drain exactly once.

## AI usage

See [AI_USAGE.md](AI_USAGE.md) — including the cases where it was wrong, which are
the interesting ones.
