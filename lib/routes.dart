/// Every route path in the app. Navigate with these instead of raw strings so a
/// path change happens in one place.
abstract final class Routes {
  // Bottom-navigation tabs.
  static const home = '/home';
  static const save = '/save';
  static const profile = '/profile';

  // NovaSave pages shown above the tabs.
  static const goaldetail = '/detail';
  static const newGoal = '/save/new';
  static String goal(String goalId) => '/save/$goalId';

  // Send Money flow.
  static const send = '/send';
  static const sendAmount = '/send/amount';
  static const sendConfirm = '/send/confirm';
  static const sendRecipient = '/send/recipient';

  /// Top-level on purpose: reached with `go`, which replaces the stack so Back
  /// can never return to the Confirm screen.
  static const sendResult = '/send-result';

  static String activity(String id) => '/activity/$id';
}

/// Route names, for `context.goNamed(...)` / `context.pushNamed(...)`.
abstract final class RouteNames {
  static const home = 'HomeView';
  static const save = 'GoalsView';
  static const profile = 'ProfileView';

  static const newGoal = 'CreateGoalView';
  static const goal = 'GoalDetailView';

  static const sendAmount = 'SendAmountView';
  static const sendRecipient = 'SendRecipientView';
  static const sendConfirm = 'SendConfirmView';
  static const sendResult = 'SendResultView';

  static const activity = 'ActivityDetailView';
}
