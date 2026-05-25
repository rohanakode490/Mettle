import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';

part 'workout_repository.g.dart';

class WorkoutRepository {
  final AppDatabase db;

  WorkoutRepository(this.db);

  Future<int> startWorkout(int? routineId) async {
    return await db.into(db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            routineId: Value(routineId),
            startTime: Value(DateTime.now()),
          ),
        );
  }

  Future<void> finishWorkout(int sessionId, String? note) async {
    await (db.update(db.workoutSessions)..where((t) => t.id.equals(sessionId))).write(
      WorkoutSessionsCompanion(
        endTime: Value(DateTime.now()),
        note: Value(note),
      ),
    );
  }

  Future<void> logSet({
    required int sessionId,
    required int exerciseId,
    required double weight,
    required int reps,
    required int orderIndex,
  }) async {
    await db.into(db.setLogs).insert(
          SetLogsCompanion.insert(
            workoutSessionId: sessionId,
            exerciseId: exerciseId,
            weight: weight,
            reps: reps,
            orderIndex: orderIndex,
          ),
        );
  }

  Future<SetLog?> getPreviousSet({
    required int exerciseId,
    required int orderIndex,
    required int currentSessionId,
  }) async {
    final query = db.select(db.setLogs)
      ..where((t) => t.exerciseId.equals(exerciseId))
      ..where((t) => t.orderIndex.equals(orderIndex))
      ..where((t) => t.workoutSessionId.isNotValue(currentSessionId))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
      ..limit(1);

    return await query.getSingleOrNull();
  }

  Future<List<Exercise>> getExercisesForRoutine(int routineId) async {
    final query = db.select(db.routineExercises).join([
      innerJoin(db.exercises, db.exercises.id.equalsExp(db.routineExercises.exerciseId)),
    ])..where(db.routineExercises.routineId.equals(routineId))
      ..orderBy([OrderingTerm(expression: db.routineExercises.orderIndex)]);

    final rows = await query.get();
    return rows.map((row) => row.readTable(db.exercises)).toList();
  }
}

@riverpod
WorkoutRepository workoutRepository(Ref ref) {
  return WorkoutRepository(ref.watch(databaseProvider));
}
