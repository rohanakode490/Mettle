import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';

part 'routine_repository.g.dart';

class RoutineWithExercises {
  final Routine routine;
  final List<Exercise> exercises;

  RoutineWithExercises({required this.routine, required this.exercises});
}

class RoutineRepository {
  final AppDatabase db;

  RoutineRepository(this.db);

  Stream<List<Routine>> watchRoutines() {
    return db.select(db.routines).watch();
  }

  Future<int> createRoutine(String name, List<int> exerciseIds) async {
    return db.transaction(() async {
      final routineId = await db.into(db.routines).insert(
            RoutinesCompanion.insert(name: name),
          );

      for (var i = 0; i < exerciseIds.length; i++) {
        await db.into(db.routineExercises).insert(
              RoutineExercisesCompanion.insert(
                routineId: routineId,
                exerciseId: exerciseIds[i],
                orderIndex: i,
              ),
            );
      }
      return routineId;
    });
  }

  Future<List<Exercise>> getAllExercises() {
    return db.select(db.exercises).get();
  }

  Future<void> deleteRoutine(int id) async {
    await (db.delete(db.routineExercises)..where((t) => t.routineId.equals(id))).go();
    await (db.delete(db.routines)..where((t) => t.id.equals(id))).go();
  }
}

@riverpod
RoutineRepository routineRepository(Ref ref) {
  return RoutineRepository(ref.watch(databaseProvider));
}
