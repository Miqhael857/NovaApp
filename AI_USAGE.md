# AI usage

## Tools

| Tool | Used for |
|---|---|
| Claude (Claude Code, in the terminal alongside Android Studio) | Design of the offline queue, the `Kobo` money type, the sync engine, test scaffolding, and reviewing my own code for layout and state bugs |
| Claude (design canvas) | Generating the NovaPay artboards and the spec sheet the Flutter theme was built from |

Everything in this repository was read, edited and in many places rewritten by me.
The sections below are real exchanges from building it, including the ones where
the model was wrong.

---

## Prompt 1 — making the router mine, not the model's

> "help format this, I want to use this way, so it won't be like I copied and pasted from claude directly"

I had pasted the `ShellRoute` pattern from my own earlier project and asked for it
to be adapted rather than replaced. What came back kept my structure — `ShellRoute`
with a `shellKey`, tabs using `parentNavigatorKey`, named routes — and fixed three
real errors in what I had pasted: a `Widget` where a `StatefulNavigationShell` was
expected, the Send flow nested inside the shell (which would have kept the bottom
bar visible during the flow), and unbalanced brackets.

The trade-off was named explicitly: `ShellRoute` does not keep a separate
navigation stack per tab, which `StatefulShellRoute.indexedStack` would. I took
that trade deliberately — I have to defend and edit this code live, and I know
this pattern.

## Prompt 2 — what "exactly once" actually means

> "the queue must replay each action exactly once, including after an app restart — how?"

The answer I kept is the one worth defending: **a client cannot promise exactly
once on its own.** What it can promise is *at least once* — a row stays in the
outbox until the server answers, so a crash mid-send means it is sent again. The
server supplies the other half by being an **idempotent receiver**: it stores
every `idempotency_key` it has handled and replays the original outcome instead of
processing twice. Exactly-once is the *effect* of those two halves, not a property
of either.

That shaped `lib/data/sync/sync_engine.dart` (single-flight, stops on network
loss, no retry loop) and `lib/data/remote/fake_novapay_api.dart` (re-checks the
key *inside* the transaction, so two concurrent replays still process once).

## Prompt 3 — reviewing my own screen

> "why is the home not starting at the top left and why is it like this"

I pasted a screenshot. Three separate causes came back, and all three were right:
an empty `AppBar` still reserving its height; `MainAxisAlignment.center` on a Row
packing the whole page into the middle; and a `Column` defaulting to
`MainAxisSize.max`, which stretched to full height and dragged the avatar to the
vertical centre. Also correct, and useful: `textAlign` did nothing there, because
a `Text` is only as wide as its own line.

---

## Where the AI was wrong

### 1. It invented a feature that is not in the brief

The generated design artboards included a **"Share receipt"** button on the
transfer-result screen, and I then built that button in Flutter to match the
design. Receipts appear nowhere in the take-home brief. The model had invented
scope and then treated its own invention as a requirement.

Caught by going back to the brief and checking. The button was removed. The
lesson I took: a design produced by the same tool that writes the code is not a
source of requirements.

### 2. It produced fake evidence for that answer

Worse than the invention was the check. Asked whether receipts were in the brief,
the model "extracted" the PDF text and reported a table showing **0 occurrences**
of *receipt*, *share*, *export* and *print* — presented as proof.

The extraction was garbage. It had pulled string literals out of every stream in
the PDF, including the embedded font programs, so the 22,636 "characters" it
searched were binary noise (`Adobe UCS`, `maxp`, `hmtx`), not the document's
words. Searching junk and finding nothing proves nothing. Spotlight later matched
"receipt" inside that same file.

Caught by looking at the extracted text instead of trusting the summary of it.
This is the one I would raise in an interview: the answer happened to be
defensible, but the evidence offered for it was worthless, and confident output
made it look settled.

### 3. It reported a completed transfer as still pending

The model wrote the Confirm handler as: enqueue the row, call `sync.run()`, then
show "sent" if `report.succeeded > 0`. `SyncEngine` is single-flight — a second
caller joins the pass already running. Since the app also runs a sync pass at
startup, a transfer confirmed while that pass was still in flight would join a
pass that had read the queue *before* the new row existed, report zero succeeded,
and show a transfer that had genuinely gone through as "Pending".

Fixed by asking the outbox row for its own status after the pass, rather than
trusting one pass's report.

### 4. Smaller ones

- **`.sp` / `.h` inside `AppText`**: scaling font size and line height separately
  turns a ratio into two independent numbers. The designed 20/14 = 1.43 became
  1.07 on a tall surface, and any screenutil getter throws
  `LateInitializationError` without a `ScreenUtilInit` ancestor, which broke all
  five `AppText` tests.
- **Route paths that disagreed with the constants**: the Send routes were nested
  under `/send/recipient` while `Routes.sendAmount` still said `/send/amount`, so
  `/send` rendered "Page Not Found" and the step indicator could never advance.
- **`IndexedStack` for the three Send steps**: it keeps all three in the widget
  tree, where `find.text` and screen readers still reach the hidden ones. Only the
  current step is built now.

---

## How I worked with it

I did not accept generated code into the repository unread. The pattern that
worked was: describe the constraint, get a proposal, argue with it, then write or
rewrite it in my own structure — which is why the file layout, the naming
(`SendResultState`, `sendResultProvider`, `SendStep`) and the widget composition
are mine, while several of the harder design decisions (outbox-first ordering,
the idempotent receiver, single-flight sync) came out of the conversation.
