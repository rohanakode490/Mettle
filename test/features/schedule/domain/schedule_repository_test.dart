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
    test('getTodayRoutine should return the routine for today', () async {
      // 1. Setup: Add a routine
      final routineId = await db.into(db.routines).insert(
            RoutinesCompanion.insert(name: 'Leg Day'),
          );

      // 2. Setup: Schedule it for today
      final today = DateTime.now().weekday;
      await repository.setSchedule(today, routineId);

      // 3. Action: Fetch today's routine
      final routine = await repository.getTodayRoutine();

      // 4. Assert
      expect(routine, isNotNull);
      expect(routine!.name, 'Leg Day');
      expect(routine.id, routineId);
    });

    test('watchWeeklySchedule should emit all scheduled routines', () async {
      final routine1Id = await db.into(db.routines).insert(
            RoutinesCompanion.insert(name: 'Upper Body'),
          );
      final routine2Id = await db.into(db.routines).insert(
            RoutinesCompanion.insert(name: 'Lower Body'),
          );

      await repository.setSchedule(1, routine1Id); // Monday
      await repository.setSchedule(3, routine2Id); // Wednesday

      final schedule = await repository.watchWeeklySchedule().first;

      expect(schedule.length, 2);
      expect(schedule.any((s) => s.routine.name == 'Upper Body' && s.schedule.dayOfWeek == 1), isTrue);
      expect(schedule.any((s) => s.routine.name == 'Lower Body' && s.schedule.dayOfWeek == 3), isTrue);
    });
  });
}
