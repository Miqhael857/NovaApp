import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/data/local/app_database.dart';
import 'package:novawallet/data/local/goal_store.dart';
import 'package:novawallet/data/local/outbox_store.dart';
import 'package:novawallet/data/remote/fake_novapay_api.dart';
import 'package:novawallet/data/sync/sync_engine.dart';

/// Debug switch that forces the app offline.
///
/// The live demo on 22 Sept uses real airplane mode, but an emulator that
/// refuses to drop its connection would take the demo with it. This is the
/// backup, and it also makes the offline path testable without touching the
/// device's radio.
class OfflineOverride extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  // ignore: use_setters_to_change_properties
  void setOffline(bool value) => state = value;
}

final offlineOverrideProvider = NotifierProvider<OfflineOverride, bool>(
  OfflineOverride.new,
);

/// Where the data layer stores itself, and how slow the fake server is.
///
/// Defaults are what the real app uses: the platform's database directory and a
/// realistic 300ms round trip. Tests override this to get temp files, the ffi
/// database factory (there is no sqflite plugin in a widget test) and no
/// latency.
class DataLayerConfig {
  const DataLayerConfig({
    this.factory,
    this.clientPath,
    this.serverPath,
    this.latency = const Duration(milliseconds: 300),
  });

  final DatabaseFactory? factory;
  final String? clientPath;
  final String? serverPath;
  final Duration latency;
}

final dataLayerConfigProvider = Provider<DataLayerConfig>(
  (ref) => const DataLayerConfig(),
);

/// The data layer, opened once and shared.
///
/// These are built together rather than as separate providers because they are
/// genuinely one unit: the API needs the server database, the outbox needs the
/// client database, and the sync engine needs both of those. Splitting them
/// would mean each provider awaiting the others' futures for no benefit.
class NovaPayServices {
  const NovaPayServices({
    required this.clientDb,
    required this.serverDb,
    required this.outbox,
    required this.goals,
    required this.api,
    required this.sync,
  });

  final Database clientDb;
  final Database serverDb;
  final OutboxStore outbox;
  final GoalStore goals;
  final FakeNovaPayApi api;
  final SyncEngine sync;
}

/// Opening the databases is async, so this is the one async seam in the app.
/// Screens read it as an [AsyncValue] and show their own loading state.
final novaPayServicesProvider = FutureProvider<NovaPayServices>((ref) async {
  final config = ref.watch(dataLayerConfigProvider);

  final clientDb = await AppDatabase.openClient(
    factory: config.factory,
    path: config.clientPath,
  );
  final serverDb = await AppDatabase.openServer(
    factory: config.factory,
    path: config.serverPath,
  );

  // Seed only on a first run. Re-seeding every launch would reset the server
  // balance, which would quietly destroy the point of the restart demo: that a
  // queued transfer debits the balance exactly once after a reconnect.
  final hasAccount = (await serverDb.query('account', limit: 1)).isNotEmpty;
  if (!hasAccount) {
    // Matches the design's opening balance of NGN 248,350.75.
    await FakeNovaPayApi.seedAccount(serverDb, balance: const Kobo(24835075));
  }

  // Connectivity is read through a mutable flag rather than awaited per call,
  // because the API asks "are we online?" synchronously, twice per request.
  var connected = true;
  try {
    final initial = await Connectivity().checkConnectivity();
    connected = initial.any((r) => r != ConnectivityResult.none);
  } catch (_) {
    // No connectivity plugin available (widget tests, unusual hosts). Assume
    // online: believing we are offline forever would queue every action and
    // never send any of them. The API's own failures are the real signal.
    connected = true;
  }

  final api = FakeNovaPayApi(
    serverDb,
    isOnline: () => connected && !ref.read(offlineOverrideProvider),
    latency: config.latency,
  );
  final outbox = OutboxStore(clientDb);

  // The goals the design shows, so a first run has something real to display.
  final goals = GoalStore(clientDb);
  await goals.seedIfEmpty();
  final sync = SyncEngine(outbox: outbox, api: api);

  // Replay the queue when the connection comes back. SyncEngine is
  // single-flight, so a burst of connectivity events joins one pass instead of
  // sending anything twice.
  StreamSubscription<List<ConnectivityResult>>? subscription;
  try {
    subscription = Connectivity().onConnectivityChanged.listen((results) {
      final nowConnected = results.any((r) => r != ConnectivityResult.none);
      final regained = !connected && nowConnected;
      connected = nowConnected;
      if (regained) unawaited(sync.run());
    });
  } catch (_) {
    // Same as above: without the plugin we simply never hear about changes.
  }

  // Flipping the debug switch back to online is a reconnect too.
  ref.listen<bool>(offlineOverrideProvider, (previous, next) {
    if (previous == true && next == false) unawaited(sync.run());
  });

  ref.onDispose(() {
    // Not awaited: a sync pass may still be in flight, and blocking disposal on
    // a database close can wedge the whole container.
    unawaited(subscription?.cancel() ?? Future<void>.value());
    unawaited(clientDb.close().catchError((_) {}));
    unawaited(serverDb.close().catchError((_) {}));
  });

  // Anything left over from a previous run goes out now.
  unawaited(sync.run());

  return NovaPayServices(
    clientDb: clientDb,
    serverDb: serverDb,
    outbox: outbox,
    goals: goals,
    api: api,
    sync: sync,
  );
});

/// Every NovaSave goal, with what the phone believes is saved so far.
final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  final services = await ref.watch(novaPayServicesProvider.future);
  return services.goals.all();
});

/// Total saved across every goal, summed in kobo.
final totalSavedProvider = FutureProvider<Kobo>((ref) async {
  final services = await ref.watch(novaPayServicesProvider.future);
  return services.goals.totalSaved();
});

/// Everything currently in the outbox, newest first. Home reads this to show
/// "Pending - will send when back online".
final outboxItemsProvider = FutureProvider<List<OutboxItem>>((ref) async {
  final services = await ref.watch(novaPayServicesProvider.future);
  return services.outbox.all();
});

/// The wallet balance as the server holds it.
///
/// Read from the fake server's ledger rather than kept on the client, so a
/// transfer that settles is reflected here and nowhere else has to be told.
final walletBalanceProvider = FutureProvider<Kobo>((ref) async {
  final services = await ref.watch(novaPayServicesProvider.future);
  return FakeNovaPayApi.balanceOf(services.serverDb);
});

/// Money the user has already committed that has not reached the server yet.
///
/// Summed in kobo from the queue itself, so it cannot drift from what will
/// actually be sent.
final pendingOutgoingProvider = Provider<Kobo>((ref) {
  final items = ref
      .watch(outboxItemsProvider)
      .maybeWhen(data: (list) => list, orElse: () => const <OutboxItem>[]);

  var total = Kobo.zero;
  for (final item in items.where((i) => i.needsSending)) {
    total += Kobo((item.payload['amountKobo'] as num?)?.toInt() ?? 0);
  }
  return total;
});

/// Balance minus everything queued — what the user can actually spend.
///
/// Assumption 3 in the README: validating against the raw balance would let
/// someone queue the same naira twice while offline and only discover the
/// problem when the second one was rejected on reconnect.
final availableBalanceProvider = Provider<Kobo>((ref) {
  final balance = ref
      .watch(walletBalanceProvider)
      .maybeWhen(data: (value) => value, orElse: () => Kobo.zero);
  final available = balance - ref.watch(pendingOutgoingProvider);
  return available.isNegative ? Kobo.zero : available;
});
