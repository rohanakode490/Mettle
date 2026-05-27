import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';
import 'package:uuid/uuid.dart';

class RoutineWithPlans {
  final Routine routine;
  final List<DayPlan> plans;

  RoutineWithPlans({required this.routine, required this.plans});
}

class RoutineRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  RoutineRepository(this.db);

  Stream<List<Routine>> watchRoutines() {
    return db.select(db.routines).watch();
  }

  Future<List<Routine>> getAllRoutines() {
    return db.select(db.routines).get();
  }

  Future<void> saveRoutine(String name, Map<int, List<ExercisePlan>> weeklyExercises) async {
    await db.transaction(() async {
      final routineId = _uuid.v4();
      final now = DateTime.now();
      await db.into(db.routines).insert(
            RoutinesCompanion.insert(
              id: routineId,
              name: name,
              lastModified: Value(now),
              isSynced: const Value(false),
            ),
          );

      for (int i = 0; i < 7; i++) {
        final exercises = weeklyExercises[i] ?? [];
        await db.into(db.dayPlans).insert(
              DayPlansCompanion.insert(
                id: _uuid.v4(),
                routineId: routineId,
                dayIndex: i,
                isRest: Value(exercises.isEmpty),
                exercisePlans: exercises,
                lastModified: Value(now),
                isSynced: const Value(false),
              ),
            );
      }
    });
  }

  Future<void> updateRoutine(String id, String name, Map<int, List<ExercisePlan>> weeklyExercises) async {
    await db.transaction(() async {
      final now = DateTime.now();
      await (db.update(db.routines)..where((t) => t.id.equals(id))).write(
        RoutinesCompanion(
          name: Value(name),
          lastModified: Value(now),
          isSynced: const Value(false),
        ),
      );

      for (int i = 0; i < 7; i++) {
        final exercises = weeklyExercises[i] ?? [];
        await (db.update(db.dayPlans)
              ..where((t) => t.routineId.equals(id) & t.dayIndex.equals(i)))
            .write(
          DayPlansCompanion(
            isRest: Value(exercises.isEmpty),
            exercisePlans: Value(exercises),
            lastModified: Value(now),
            isSynced: const Value(false),
          ),
        );
      }
    });
  }

  Future<RoutineWithPlans> getRoutineWithPlans(String id) async {
    final routine = await (db.select(db.routines)..where((t) => t.id.equals(id))).getSingle();
    final plans = await (db.select(db.dayPlans)
          ..where((t) => t.routineId.equals(id))
          ..orderBy([(t) => OrderingTerm(expression: t.dayIndex)]))
        .get();
    return RoutineWithPlans(routine: routine, plans: plans);
  }

  Future<void> deleteRoutine(String id) async {
    await db.transaction(() async {
      await (db.delete(db.dayPlans)..where((t) => t.routineId.equals(id))).go();
      await (db.delete(db.routines)..where((t) => t.id.equals(id))).go();
    });
  }
}

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return RoutineRepository(ref.watch(databaseProvider));
});
