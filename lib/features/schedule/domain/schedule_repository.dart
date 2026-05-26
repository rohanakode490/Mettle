import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';

part 'schedule_repository.g.dart';

class ScheduleWithRoutine {
  final DayPlan dayPlan;
  final Routine routine;

  ScheduleWithRoutine({required this.dayPlan, required this.routine});
}

class ScheduleRepository {
  final AppDatabase db;

  ScheduleRepository(this.db);

  Stream<List<ScheduleWithRoutine>> watchWeeklySchedule(String routineId) {
    final query = db.select(db.dayPlans).join([
      innerJoin(db.routines, db.routines.id.equalsExp(db.dayPlans.routineId)),
    ])..where(db.dayPlans.routineId.equals(routineId));

    return query.watch().map((rows) {
      return rows.map((row) {
        return ScheduleWithRoutine(
          dayPlan: row.readTable(db.dayPlans),
          routine: row.readTable(db.routines),
        );
      }).toList();
    });
  }

  // This repository is mostly legacy now as RoutineRepository handles DayPlans
  // But we'll keep it for simple day-based queries if needed.
}

@riverpod
ScheduleRepository scheduleRepository(Ref ref) {
  return ScheduleRepository(ref.watch(databaseProvider));
}
