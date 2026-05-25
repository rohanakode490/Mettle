import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/features/workout/domain/workout_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;
  late WorkoutRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('WorkoutRepository - getPreviousSet', () {
    test('should return the most recent set for same exercise and order index', () async {
      // 1. Setup: Add an exercise
      final exerciseId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(name: 'Bench Press', muscleGroup: const Value('Chest')),
          );

      // 2. Setup: Create two past sessions
      final session1Id = await repository.startWorkout(null);
      await db.into(db.setLogs).insert(SetLogsCompanion.insert(
        workoutSessionId: session1Id,
        exerciseId: exerciseId,
        weight: 60.0,
        reps: 10,
        orderIndex: 0,
        createdAt: Value(DateTime.now().subtract(const Duration(minutes: 10))),
      ));
      await repository.finishWorkout(session1Id, null);

      final session2Id = await repository.startWorkout(null);
      await db.into(db.setLogs).insert(SetLogsCompanion.insert(
        workoutSessionId: session2Id,
        exerciseId: exerciseId,
        weight: 65.0,
        reps: 8,
        orderIndex: 0,
        createdAt: Value(DateTime.now().subtract(const Duration(minutes: 5))),
      ));
      await repository.finishWorkout(session2Id, null);

      // 3. Current Session
      final currentSessionId = await repository.startWorkout(null);

      // 4. Action: Fetch previous set for "Bench Press" at index 0
      final previousSet = await repository.getPreviousSet(
        exerciseId: exerciseId,
        orderIndex: 0,
        currentSessionId: currentSessionId,
      );

      // 5. Assert: Should be from session 2 (65kg x 8)
      expect(previousSet, isNotNull);
      expect(previousSet!.weight, 65.0);
      expect(previousSet!.reps, 8);
      expect(previousSet!.workoutSessionId, session2Id);
    });

    test('should return null if no previous sets exist', () async {
      final exerciseId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(name: 'Squat', muscleGroup: const Value('Legs')),
          );
      final currentSessionId = await repository.startWorkout(null);

      final previousSet = await repository.getPreviousSet(
        exerciseId: exerciseId,
        orderIndex: 0,
        currentSessionId: currentSessionId,
      );

      expect(previousSet, isNull);
    });
  });
}
