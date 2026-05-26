import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';

class ExerciseRepository {
  final AppDatabase db;

  ExerciseRepository(this.db);

  Stream<List<Exercise>> watchAllExercises() {
    return db.select(db.exercises).watch();
  }

  Future<void> addExercise(String name, String? muscleGroup) async {
    await db.into(db.exercises).insert(
      ExercisesCompanion.insert(
        id: DateTime.now().toIso8601String(),
        name: name,
        muscleGroup: Value(muscleGroup),
      ),
    );
  }
}

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(databaseProvider));
});

final exercisesStreamProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchAllExercises();
});
