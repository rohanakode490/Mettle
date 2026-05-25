import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';
import 'package:drift/drift.dart';

part 'exercise_repository.g.dart';

class ExerciseRepository {
  final AppDatabase db;

  ExerciseRepository(this.db);

  Stream<List<Exercise>> watchExercises() {
    return db.select(db.exercises).watch();
  }

  Future<List<Exercise>> getAllExercises() {
    return db.select(db.exercises).get();
  }

  Future<List<Exercise>> getExercisesByMuscleGroup(String muscleGroup) {
    return (db.select(db.exercises)..where((t) => t.muscleGroup.equals(muscleGroup))).get();
  }

  Future<int> addExercise(String name, String? muscleGroup) {
    return db.into(db.exercises).insert(
      ExercisesCompanion.insert(
        name: name,
        muscleGroup: Value(muscleGroup),
      ),
    );
  }
}

@riverpod
ExerciseRepository exerciseRepository(Ref ref) {
  return ExerciseRepository(ref.watch(databaseProvider));
}

@riverpod
Stream<List<Exercise>> exercisesStream(Ref ref) {
  return ref.watch(exerciseRepositoryProvider).watchExercises();
}
