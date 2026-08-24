import '../domain/models.dart';
import '../intelligence/training_engine.dart';
import '../persistence/kinetic_store.dart';

/// Complete View Model for rendering the Active Workout Screen (SPEC.md Section 30)
class WorkoutViewModel {
  final WorkoutSession session;
  final int currentPrescriptionIndex;
  final ExercisePrescription? currentPrescription;
  final int nextSetNumber;
  final double prescribedLoadKg;
  final int prescribedReps;
  final double prescribedTargetRPE;
  final List<ExerciseSet> completedSets;
  final AutoregulationAdjustment? lastAutoregulationAdjustment;
  final String? lastAutoregulationReason;
  final double totalVolumeKg;
  final double progressPercent; // 0.0 to 1.0
  final bool isCompleted;

  const WorkoutViewModel({
    required this.session,
    required this.currentPrescriptionIndex,
    this.currentPrescription,
    required this.nextSetNumber,
    required this.prescribedLoadKg,
    required this.prescribedReps,
    required this.prescribedTargetRPE,
    required this.completedSets,
    this.lastAutoregulationAdjustment,
    this.lastAutoregulationReason,
    required this.totalVolumeKg,
    required this.progressPercent,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': session.id,
        'status': session.status,
        'currentPrescriptionIndex': currentPrescriptionIndex,
        'currentExercise': currentPrescription?.exerciseName,
        'nextSetNumber': nextSetNumber,
        'prescribedLoadKg': prescribedLoadKg,
        'prescribedReps': prescribedReps,
        'prescribedTargetRPE': prescribedTargetRPE,
        'completedSetsCount': completedSets.length,
        'totalVolumeKg': totalVolumeKg,
        'progressPercent': progressPercent,
        'isCompleted': isCompleted,
        'lastAutoregulationReason': lastAutoregulationReason,
      };
}

/// Application Service for interactive workout execution, logging, and autoregulation (SPEC.md Section 3 & 28)
class TrainingService {
  final KineticStore store;

  TrainingService({KineticStore? store}) : store = store ?? KineticStore.instance;

  /// 1. getCurrentWorkout(): Retrieves current active or upcoming planned session
  Future<WorkoutSession?> getCurrentWorkout() async {
    return store.getActiveSession() ?? store.getSessions().where((s) => s.status == 'planned').lastOrNull;
  }

  /// 2. startSession(): Starts an active workout session
  Future<WorkoutViewModel> startSession(WorkoutSession session) async {
    final active = session.status == 'in_progress'
        ? session
        : WorkoutSession(
            id: session.id,
            userId: session.userId,
            startTime: DateTime.now(),
            goal: session.goal,
            focus: session.focus,
            prescriptions: session.prescriptions,
            completedSets: session.completedSets,
            status: 'in_progress',
          );

    store.saveSession(active);
    store.recordEvent(KineticEvent(
      id: 'evt_start_${active.id}',
      userId: active.userId,
      eventType: 'WorkoutStarted',
      timestamp: DateTime.now(),
      payload: {'sessionId': active.id, 'goal': active.goal.name},
    ));

    return _buildViewModel(active);
  }

  /// 3. logSet(): Logs a completed set and automatically executes real-time autoregulation for subsequent sets
  Future<WorkoutViewModel> logSet({
    required String sessionId,
    required String exerciseId,
    required double actualLoadKg,
    required int actualReps,
    required double actualRPE,
    int restSeconds = 90,
  }) async {
    final sessions = store.getSessions();
    final session = sessions.firstWhere((s) => s.id == sessionId);

    final currentExercisePrescription = session.prescriptions.firstWhere(
      (p) => p.exerciseId == exerciseId,
      orElse: () => session.prescriptions.first,
    );

    final setNumber = session.completedSets.where((s) => s.exerciseId == exerciseId).length + 1;

    final completedSet = ExerciseSet(
      setNumber: setNumber,
      exerciseId: exerciseId,
      prescribedLoadKg: currentExercisePrescription.targetLoadKg,
      actualLoadKg: actualLoadKg,
      prescribedReps: currentExercisePrescription.targetReps,
      actualReps: actualReps,
      targetRPE: currentExercisePrescription.targetRPE,
      actualRPE: actualRPE,
      restSeconds: restSeconds,
      timestamp: DateTime.now(),
      isCompleted: true,
    );

    final updatedSets = List<ExerciseSet>.from(session.completedSets)..add(completedSet);

    // Compute dynamic autoregulation for next set if there are remaining sets for this exercise
    AutoregulationAdjustment? adjustment;
    String? autoregulationReason;

    if (setNumber < currentExercisePrescription.targetSets) {
      adjustment = KineticTrainingEngine.autoregulateNextSet(
        prescription: currentExercisePrescription,
        previousSet: completedSet,
        nextSetNumber: setNumber + 1,
      );
      autoregulationReason = adjustment.reasonCode;
    }

    final updatedSession = WorkoutSession(
      id: session.id,
      userId: session.userId,
      startTime: session.startTime,
      goal: session.goal,
      focus: session.focus,
      prescriptions: session.prescriptions,
      completedSets: updatedSets,
      status: 'in_progress',
    );

    store.saveSession(updatedSession);
    store.recordEvent(KineticEvent(
      id: 'evt_set_${sessionId}_$setNumber',
      userId: session.userId,
      eventType: 'SetCompleted',
      timestamp: DateTime.now(),
      payload: {
        'sessionId': sessionId,
        'exerciseId': exerciseId,
        'setNumber': setNumber,
        'loadKg': actualLoadKg,
        'reps': actualReps,
        'rpe': actualRPE,
        'autoregulationReason': autoregulationReason,
      },
    ));

    return _buildViewModel(
      updatedSession,
      lastAdjustment: adjustment,
      lastReason: autoregulationReason,
    );
  }

  /// 4. getNextSet(): Retrieves prescription targets for the upcoming set
  Future<ExercisePrescription?> getNextSet(String sessionId) async {
    final session = store.getSessions().firstWhere((s) => s.id == sessionId);
    final vm = _buildViewModel(session);
    return vm.currentPrescription;
  }

  /// 5. completeSession(): Finalizes workout session and calculates volume and training load
  Future<WorkoutSession> completeSession(String sessionId, {double finalAverageRPE = 8.0}) async {
    final session = store.getSessions().firstWhere((s) => s.id == sessionId);

    double totalTonnage = 0.0;
    for (final s in session.completedSets) {
      totalTonnage += s.actualLoadKg * s.actualReps;
    }

    final completedSession = WorkoutSession(
      id: session.id,
      userId: session.userId,
      startTime: session.startTime,
      endTime: DateTime.now(),
      goal: session.goal,
      focus: session.focus,
      prescriptions: session.prescriptions,
      completedSets: session.completedSets,
      averageRPE: finalAverageRPE,
      trainingLoad: totalTonnage * 0.1,
      status: 'completed',
    );

    store.saveSession(completedSession);
    store.recordEvent(KineticEvent(
      id: 'evt_complete_$sessionId',
      userId: session.userId,
      eventType: 'WorkoutCompleted',
      timestamp: DateTime.now(),
      payload: {
        'sessionId': sessionId,
        'totalVolumeKg': totalTonnage,
        'finalRPE': finalAverageRPE,
        'setsCompleted': completedSession.completedSets.length,
      },
    ));

    return completedSession;
  }

  /// 6. discardSession(): Discards an active workout session
  Future<void> discardSession(String sessionId) async {
    final session = store.getSessions().firstWhere((s) => s.id == sessionId);
    final discarded = WorkoutSession(
      id: session.id,
      userId: session.userId,
      startTime: session.startTime,
      endTime: DateTime.now(),
      goal: session.goal,
      focus: session.focus,
      prescriptions: session.prescriptions,
      completedSets: session.completedSets,
      status: 'discarded',
    );
    store.saveSession(discarded);
  }

  /// Public accessor to assemble the WorkoutViewModel contract
  WorkoutViewModel buildViewModel(
    WorkoutSession session, {
    AutoregulationAdjustment? lastAdjustment,
    String? lastReason,
  }) =>
      _buildViewModel(session, lastAdjustment: lastAdjustment, lastReason: lastReason);

  /// Internal helper to assemble the WorkoutViewModel contract
  WorkoutViewModel _buildViewModel(
    WorkoutSession session, {
    AutoregulationAdjustment? lastAdjustment,
    String? lastReason,
  }) {
    double totalTonnage = 0.0;
    for (final s in session.completedSets) {
      totalTonnage += s.actualLoadKg * s.actualReps;
    }

    int currentPrescriptionIdx = 0;
    ExercisePrescription? activePrescription;
    int nextSetNumber = 1;
    double targetLoad = 60.0;
    int targetReps = 8;
    double targetRPE = 8.0;

    for (int i = 0; i < session.prescriptions.length; i++) {
      final p = session.prescriptions[i];
      final setsForExercise = session.completedSets.where((s) => s.exerciseId == p.exerciseId).length;
      if (setsForExercise < p.targetSets) {
        currentPrescriptionIdx = i;
        activePrescription = p;
        nextSetNumber = setsForExercise + 1;
        targetLoad = lastAdjustment?.adjustedLoadKg ?? p.targetLoadKg;
        targetReps = lastAdjustment?.adjustedReps ?? p.targetReps;
        targetRPE = lastAdjustment?.adjustedTargetRPE ?? p.targetRPE;
        break;
      }
    }

    final totalTargetSets = session.prescriptions.fold<int>(0, (sum, p) => sum + p.targetSets);
    final progress = totalTargetSets > 0 ? (session.completedSets.length / totalTargetSets).clamp(0.0, 1.0) : 0.0;

    return WorkoutViewModel(
      session: session,
      currentPrescriptionIndex: currentPrescriptionIdx,
      currentPrescription: activePrescription,
      nextSetNumber: nextSetNumber,
      prescribedLoadKg: targetLoad,
      prescribedReps: targetReps,
      prescribedTargetRPE: targetRPE,
      completedSets: session.completedSets,
      lastAutoregulationAdjustment: lastAdjustment,
      lastAutoregulationReason: lastReason,
      totalVolumeKg: totalTonnage,
      progressPercent: progress,
      isCompleted: session.status == 'completed' || (totalTargetSets > 0 && session.completedSets.length >= totalTargetSets),
    );
  }
}
