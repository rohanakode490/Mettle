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

  group('WorkoutRepository', () {
    test('logSet and getTodaySets', () async {
      final exerciseName = 'Bench Press';
      final routineId = 'r1';
      final dayIndex = 1;

      await repository.logSet(
        exerciseName: exerciseName,
        weight: 60.0,
        reps: 10,
        routineId: routineId,
        dayIndex: dayIndex,
      );

      final todaySets = await repository.getTodaySets(routineId, dayIndex);
      expect(todaySets.length, 1);
      expect(todaySets.first.exerciseName, exerciseName);
      expect(todaySets.first.weightKg, 60.0);
      expect(todaySets.first.reps, 10);
    });

    test('getLastSet should return most recent set for exercise', () async {
      final exerciseName = 'Squat';
      
      // Older set
      await db.into(db.setLogs).insert(SetLogsCompanion.insert(
        id: '1',
        exerciseName: exerciseName,
        weightKg: 80.0,
        reps: 5,
        routineId: 'r1',
        dayIndex: 1,
        timestamp: Value(DateTime.now().subtract(const Duration(days: 1))),
      ));

      // Newer set
      await db.into(db.setLogs).insert(SetLogsCompanion.insert(
        id: '2',
        exerciseName: exerciseName,
        weightKg: 85.0,
        reps: 5,
        routineId: 'r1',
        dayIndex: 1,
        timestamp: Value(DateTime.now()),
      ));

      final lastSet = await repository.getLastSet(exerciseName);
      expect(lastSet, isNotNull);
      expect(lastSet!.weightKg, 85.0);
    });

    test('updateSetLog and deleteSetLog', () async {
      final id = 'test-id';
      await db.into(db.setLogs).insert(SetLogsCompanion.insert(
        id: id,
        exerciseName: 'Deadlift',
        weightKg: 100.0,
        reps: 5,
        routineId: 'r1',
        dayIndex: 1,
      ));

      await repository.updateSetLog(
        id: id,
        weight: 110.0,
        reps: 3,
        setType: 'work',
      );

      final updated = await (db.select(db.setLogs)..where((t) => t.id.equals(id))).getSingle();
      expect(updated.weightKg, 110.0);
      expect(updated.reps, 3);

      await repository.deleteSetLog(id);
      final list = await db.select(db.setLogs).get();
      expect(list, isEmpty);
    });
  });
}
