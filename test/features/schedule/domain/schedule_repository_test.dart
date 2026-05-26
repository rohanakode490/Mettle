import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/features/schedule/domain/schedule_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;
  late ScheduleRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ScheduleRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ScheduleRepository', () {
    test('watchWeeklySchedule should emit joined plans for a routine', () async {
      final routineId = 'r1';
      await db.into(db.routines).insert(
            RoutinesCompanion.insert(id: routineId, name: 'Leg Day'),
          );

      await db.into(db.dayPlans).insert(
            DayPlansCompanion.insert(
              id: 'dp1',
              routineId: routineId,
              dayIndex: 1,
              isRest: const Value(false),
              exercisePlans: [ExercisePlan(id: 'test-id', name: 'Squat')],
            ),
          );

      final schedule = await repository.watchWeeklySchedule(routineId).first;

      expect(schedule.length, 1);
      expect(schedule.first.routine.name, 'Leg Day');
      expect(schedule.first.dayPlan.dayIndex, 1);
      expect(schedule.first.dayPlan.exercisePlans.first.name, 'Squat');
    });
  });
}
