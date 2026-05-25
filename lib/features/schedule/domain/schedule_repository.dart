import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';

part 'schedule_repository.g.dart';

class ScheduleWithRoutine {
  final Schedule schedule;
  final Routine routine;

  ScheduleWithRoutine({required this.schedule, required this.routine});
}

class ScheduleRepository {
  final AppDatabase db;

  ScheduleRepository(this.db);

  Stream<List<ScheduleWithRoutine>> watchWeeklySchedule() {
    final query = db.select(db.schedules).join([
      innerJoin(db.routines, db.routines.id.equalsExp(db.schedules.routineId)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ScheduleWithRoutine(
          schedule: row.readTable(db.schedules),
          routine: row.readTable(db.routines),
        );
      }).toList();
    });
  }

  Future<void> setSchedule(int dayOfWeek, int routineId) async {
    await db.into(db.schedules).insertOnConflictUpdate(
          SchedulesCompanion.insert(
            dayOfWeek: dayOfWeek,
            routineId: routineId,
          ),
        );
  }

  Future<Routine?> getTodayRoutine() async {
    final today = DateTime.now().weekday;
    final query = db.select(db.schedules).join([
      innerJoin(db.routines, db.routines.id.equalsExp(db.schedules.routineId)),
    ])..where(db.schedules.dayOfWeek.equals(today));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return row.readTable(db.routines);
  }
}

@riverpod
ScheduleRepository scheduleRepository(Ref ref) {
  return ScheduleRepository(ref.watch(databaseProvider));
}
