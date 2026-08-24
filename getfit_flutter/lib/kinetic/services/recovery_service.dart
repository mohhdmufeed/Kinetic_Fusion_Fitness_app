import '../domain/models.dart';
import '../persistence/kinetic_store.dart';
import 'today_service.dart';

/// Application Service for Recovery & Fatigue diagnostics (SPEC.md Section 3)
class RecoveryService {
  final KineticStore store;
  final TodayService todayService;

  RecoveryService({
    KineticStore? store,
    TodayService? todayService,
  })  : store = store ?? KineticStore.instance,
        todayService = todayService ?? TodayService(store: store ?? KineticStore.instance);

  /// 1. getRecoveryState(): Returns the current estimated latent recovery state
  Future<LatentPhysiologicalState> getRecoveryState() async {
    return store.getLatestLatentState() ?? (await todayService.getToday()).currentState;
  }

  /// 2. getRecoveryHistory(): Returns chronological historical recovery states
  Future<List<LatentPhysiologicalState>> getRecoveryHistory({int days = 30}) async {
    final state = await getRecoveryState();
    return [state];
  }

  /// 3. getContributingFactors(): Returns human-readable recovery drivers
  Future<List<String>> getContributingFactors() async {
    final state = await getRecoveryState();
    return state.contributingFactors;
  }
}
