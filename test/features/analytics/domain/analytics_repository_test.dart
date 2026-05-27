import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/features/analytics/domain/analytics_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;
  late AnalyticsRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = AnalyticsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AnalyticsRepository', () {
    final exerciseName = 'Bench Press';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    setUp(() async {
      // Insert some test data
      // Yesterday: 2 sets (60kg x 10, 65kg x 8)
      await db.into(db.setLogs).insert(SetLogsCompanion.insert(
        id: '1',
        exerciseName: exerciseName,
        weightKg: 60.0,
        reps: 10,
        routineId: 'r1',
        dayIndex: 1,
        timestamp: Value(yesterday.add(const Duration(hours: 10))),
      ));
      await db.into(db.setLogs).insert(SetLogsCompanion.insert(
        id: '2',
        exerciseName: exerciseName,
        weightKg: 65.0,
        reps: 8,
        routineId: 'r1',
        dayIndex: 1,
        timestamp: Value(yesterday.add(const Duration(hours: 11))),
      ));

      // Today: 2 sets (70kg x 5, 75kg x 3)
      await db.into(db.setLogs).insert(SetLogsCompanion.insert(
        id: '3',
        exerciseName: exerciseName,
        weightKg: 70.0,
        reps: 5,
        routineId: 'r1',
        dayIndex: 1,
        timestamp: Value(today.add(const Duration(hours: 10))),
      ));
      await db.into(db.setLogs).insert(SetLogsCompanion.insert(
        id: '4',
        exerciseName: exerciseName,
        weightKg: 75.0,
        reps: 3,
        routineId: 'r1',
        dayIndex: 1,
        timestamp: Value(today.add(const Duration(hours: 11))),
      ));
    });

    test('getMaxWeightHistory should return max weight per day', () async {
      final history = await repository.getMaxWeightHistory(exerciseName);
      
      expect(history.length, 2);
      expect(history[0].value, 65.0); // Yesterday max
      expect(history[1].value, 75.0); // Today max
    });

    test('getVolumeHistory should return total volume per day', () async {
      final history = await repository.getVolumeHistory(exerciseName);
      
      expect(history.length, 2);
      // Yesterday volume: (60 * 10) + (65 * 8) = 600 + 520 = 1120
      expect(history[0].value, 1120.0);
      // Today volume: (70 * 5) + (75 * 3) = 350 + 225 = 575
      expect(history[1].value, 575.0);
    });

    test('getOneRepMaxHistory should return max estimated 1RM per day', () async {
      final history = await repository.getOneRepMaxHistory(exerciseName);
      
      expect(history.length, 2);
      // Epley: Weight * (1 + Reps / 30)
      // Yesterday:
      // set 1: 60 * (1 + 10/30) = 60 * 1.333 = 80
      // set 2: 65 * (1 + 8/30) = 65 * 1.266 = 82.33
      expect(history[0].value, closeTo(82.33, 0.01));

      // Today:
      // set 1: 70 * (1 + 5/30) = 70 * 1.166 = 81.66
      // set 2: 75 * (1 + 3/30) = 75 * 1.1 = 82.5
      expect(history[1].value, 82.5);
    });
   group('Epley Edge Case', () {
      test('1RM for 1 rep should equal weight', () async {
        await db.into(db.setLogs).insert(SetLogsCompanion.insert(
          id: '5',
          exerciseName: 'Deadlift',
          weightKg: 100.0,
          reps: 1,
          routineId: 'r1',
          dayIndex: 1,
          timestamp: Value(today),
        ));
        
        final history = await repository.getOneRepMaxHistory('Deadlift');
        expect(history.first.value, 100.0);
      });
    });
  });
}
