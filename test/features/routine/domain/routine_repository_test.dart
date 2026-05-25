import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/features/routine/domain/routine_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;
  late RoutineRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = RoutineRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('RoutineRepository', () {
    test('createRoutine should create a routine and its exercise associations', () async {
      // 1. Setup: Add exercises
      final ex1Id = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(name: 'Bench Press'),
          );
      final ex2Id = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(name: 'Squat'),
          );

      // 2. Action: Create routine
      final routineId = await repository.createRoutine('Push/Pull', [ex1Id, ex2Id]);

      // 3. Assert: Routine exists
      final routine = await (db.select(db.routines)..where((t) => t.id.equals(routineId))).getSingle();
      expect(routine.name, 'Push/Pull');

      // 4. Assert: Exercise associations exist
      final associations = await (db.select(db.routineExercises)..where((t) => t.routineId.equals(routineId))).get();
      expect(associations.length, 2);
      expect(associations[0].exerciseId, ex1Id);
      expect(associations[0].orderIndex, 0);
      expect(associations[1].exerciseId, ex2Id);
      expect(associations[1].orderIndex, 1);
    });

    test('deleteRoutine should remove the routine and its associations', () async {
      final exId = await db.into(db.exercises).insert(ExercisesCompanion.insert(name: 'Bench'));
      final routineId = await repository.createRoutine('Test', [exId]);

      await repository.deleteRoutine(routineId);

      final routines = await db.select(db.routines).get();
      final associations = await db.select(db.routineExercises).get();

      expect(routines, isEmpty);
      expect(associations, isEmpty);
    });
  });
}
