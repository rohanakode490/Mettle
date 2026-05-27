import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';
import 'package:uuid/uuid.dart';

class WorkoutRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  WorkoutRepository(this.db);

  Future<void> logSet({
    required String exerciseName,
    required double weight,
    required int reps,
    required String routineId,
    required int dayIndex,
    String setType = 'work',
  }) async {
    final now = DateTime.now();
    await db.into(db.setLogs).insert(
          SetLogsCompanion.insert(
            id: _uuid.v4(),
            exerciseName: exerciseName,
            weightKg: weight,
            reps: reps,
            routineId: routineId,
            dayIndex: dayIndex,
            timestamp: Value(now),
            setType: Value(setType),
            lastModified: Value(now),
            isSynced: const Value(false),
          ),
        );
  }

  Future<SetLog?> getLastSet(String exerciseName) async {
    return await (db.select(db.setLogs)
          ..where((t) => t.exerciseName.equals(exerciseName))
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<SetLog>> getPreviousSessionSets(String exerciseName) async {
    final lastSet = await getLastSet(exerciseName);
    if (lastSet == null) return [];

    final date = lastSet.timestamp;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await (db.select(db.setLogs)
          ..where((t) =>
              t.exerciseName.equals(exerciseName) &
              t.timestamp.isBiggerOrEqualValue(startOfDay) &
              t.timestamp.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc)]))
        .get();
  }

  Future<List<SetLog>> getTodaySets(String routineId, int dayIndex) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    return await (db.select(db.setLogs)
          ..where((t) => 
            t.routineId.equals(routineId) & 
            t.dayIndex.equals(dayIndex) & 
            t.timestamp.isBiggerOrEqualValue(startOfDay)))
        .get();
  }

  Stream<List<SetLog>> watchTodaySets(String routineId, int dayIndex) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    return (db.select(db.setLogs)
          ..where((t) => 
            t.routineId.equals(routineId) & 
            t.dayIndex.equals(dayIndex) & 
            t.timestamp.isBiggerOrEqualValue(startOfDay)))
        .watch();
  }

  Future<List<String>> getExerciseAutocompletePool() async {
    final query = db.selectOnly(db.setLogs, distinct: true)..addColumns([db.setLogs.exerciseName]);
    final rows = await query.get();
    return rows.map((r) => r.read(db.setLogs.exerciseName)!).toList();
  }

  Future<void> deleteSetLog(String id) async {
    await (db.delete(db.setLogs)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateSetLog({
    required String id,
    required double weight,
    required int reps,
    required String setType,
  }) async {
    final now = DateTime.now();
    await (db.update(db.setLogs)..where((t) => t.id.equals(id))).write(
      SetLogsCompanion(
        weightKg: Value(weight),
        reps: Value(reps),
        setType: Value(setType),
        lastModified: Value(now),
        isSynced: const Value(false),
      ),
    );
  }

  Stream<List<SetLog>> watchHistoricalSets() {
    return (db.select(db.setLogs)
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .watch();
  }
}

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(databaseProvider));
});

final todaySetsProvider = StreamProvider.family<List<SetLog>, String>((ref, arg) {
  final parts = arg.split('|');
  final routineId = parts[0];
  final dayIndex = int.parse(parts[1]);
  return ref.watch(workoutRepositoryProvider).watchTodaySets(routineId, dayIndex);
});

final historicalSetsProvider = StreamProvider<List<SetLog>>((ref) {
  return ref.watch(workoutRepositoryProvider).watchHistoricalSets();
});
