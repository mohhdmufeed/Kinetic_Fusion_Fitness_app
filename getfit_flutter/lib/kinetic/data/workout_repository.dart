import '../domain/models.dart';
import 'session_repository.dart';

class WorkoutRepository {
  final SessionRepository _sessionRepository;

  WorkoutRepository(this._sessionRepository);

  Future<void> createWorkout(WorkoutSession session) async {
    await _sessionRepository.createSession(session);
  }

  Future<WorkoutSession?> getWorkout(String id) async {
    return _sessionRepository.getSession(id);
  }

  Future<List<WorkoutSession>> getWorkouts(String userId) async {
    return _sessionRepository.getSessions(userId);
  }
}
