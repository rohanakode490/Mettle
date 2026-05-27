import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';

class SyncRepository {
  final AppDatabase db;
  final sb.SupabaseClient supabase;

  SyncRepository({required this.db, required this.supabase});

  Future<void> syncAll() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Pull first to resolve conflicts locally
    await _pullRoutines();
    await _pullDayPlans();
    await _pullSetLogs();

    // Push local changes
    await _pushRoutines();
    await _pushDayPlans();
    await _pushSetLogs();
  }

  // --- PULL LOGIC ---

  Future<void> _pullRoutines() async {
    try {
      final remoteRoutines = await supabase.from('routines').select();
      for (final remote in remoteRoutines) {
        final remoteId = remote['id'] as String;
        final remoteLastModified = DateTime.parse(remote['last_modified'] as String);

        final local = await (db.select(db.routines)..where((t) => t.remoteId.equals(remoteId))).getSingleOrNull();

        if (local == null) {
          // Insert new local record
          await db.into(db.routines).insert(
                RoutinesCompanion.insert(
                  id: const Uuid().v4(),
                  name: remote['name'] as String,
                  createdAt: Value(DateTime.parse(remote['created_at'] as String)),
                  remoteId: Value(remoteId),
                  isSynced: const Value(true),
                  lastModified: Value(remoteLastModified),
                ),
              );
        } else if (remoteLastModified.isAfter(local.lastModified)) {
          // Remote is newer, update local
          await (db.update(db.routines)..where((t) => t.id.equals(local.id))).write(
            RoutinesCompanion(
              name: Value(remote['name'] as String),
              lastModified: Value(remoteLastModified),
              isSynced: const Value(true),
            ),
          );
        }
      }
    } catch (e) {
      print('Pull error (routines): $e');
    }
  }

  Future<void> _pullDayPlans() async {
    try {
      final remoteDayPlans = await supabase.from('day_plans').select();
      for (final remote in remoteDayPlans) {
        final remoteId = remote['id'] as String;
        final remoteLastModified = DateTime.parse(remote['last_modified'] as String);
        final remoteRoutineId = remote['routine_id'] as String;

        // Find local routine ID
        final localRoutine = await (db.select(db.routines)..where((t) => t.remoteId.equals(remoteRoutineId))).getSingleOrNull();
        if (localRoutine == null) continue; // Skip if parent routine not found locally yet

        final local = await (db.select(db.dayPlans)..where((t) => t.remoteId.equals(remoteId))).getSingleOrNull();

        final exercisePlans = (remote['exercise_plans'] as List)
            .map((e) => ExercisePlan.fromJson(e as Map<String, dynamic>))
            .toList();

        if (local == null) {
          await db.into(db.dayPlans).insert(
                DayPlansCompanion.insert(
                  id: const Uuid().v4(),
                  routineId: localRoutine.id,
                  dayIndex: remote['day_index'] as int,
                  isRest: Value(remote['is_rest'] as bool),
                  exercisePlans: exercisePlans,
                  remoteId: Value(remoteId),
                  isSynced: const Value(true),
                  lastModified: Value(remoteLastModified),
                ),
              );
        } else if (remoteLastModified.isAfter(local.lastModified)) {
          await (db.update(db.dayPlans)..where((t) => t.id.equals(local.id))).write(
            DayPlansCompanion(
              dayIndex: Value(remote['day_index'] as int),
              isRest: Value(remote['is_rest'] as bool),
              exercisePlans: Value(exercisePlans),
              lastModified: Value(remoteLastModified),
              isSynced: const Value(true),
            ),
          );
        }
      }
    } catch (e) {
      print('Pull error (dayPlans): $e');
    }
  }

  Future<void> _pullSetLogs() async {
    try {
      final remoteSetLogs = await supabase.from('set_logs').select();
      for (final remote in remoteSetLogs) {
        final remoteId = remote['id'] as String;
        final remoteLastModified = DateTime.parse(remote['last_modified'] as String);
        final remoteRoutineId = remote['routine_id'] as String;

        // Try to find local routine ID
        final localRoutine = await (db.select(db.routines)..where((t) => t.remoteId.equals(remoteRoutineId))).getSingleOrNull();
        final localRoutineId = localRoutine?.id ?? remoteRoutineId;

        final local = await (db.select(db.setLogs)..where((t) => t.remoteId.equals(remoteId))).getSingleOrNull();

        if (local == null) {
          await db.into(db.setLogs).insert(
                SetLogsCompanion.insert(
                  id: const Uuid().v4(),
                  exerciseName: remote['exercise_name'] as String,
                  weightKg: (remote['weight'] as num).toDouble(),
                  reps: remote['reps'] as int,
                  timestamp: Value(DateTime.parse(remote['timestamp'] as String)),
                  routineId: localRoutineId,
                  dayIndex: remote['day_index'] as int,
                  remoteId: Value(remoteId),
                  isSynced: const Value(true),
                  lastModified: Value(remoteLastModified),
                  setType: Value(remote['set_type'] as String? ?? 'work'),
                ),
              );
        } else if (remoteLastModified.isAfter(local.lastModified)) {
          await (db.update(db.setLogs)..where((t) => t.id.equals(local.id))).write(
            SetLogsCompanion(
              exerciseName: Value(remote['exercise_name'] as String),
              weightKg: Value((remote['weight'] as num).toDouble()),
              reps: Value(remote['reps'] as int),
              timestamp: Value(DateTime.parse(remote['timestamp'] as String)),
              routineId: Value(localRoutineId),
              lastModified: Value(remoteLastModified),
              isSynced: const Value(true),
              setType: Value(remote['set_type'] as String? ?? 'work'),
            ),
          );
        }
      }
    } catch (e) {
      print('Pull error (setLogs): $e');
    }
  }

  // --- PUSH LOGIC ---

  Future<void> _pushRoutines() async {
    final unsynced = await (db.select(db.routines)..where((t) => t.isSynced.equals(false))).get();
    for (final routine in unsynced) {
      try {
        final data = {
          'name': routine.name,
          'created_at': routine.createdAt.toIso8601String(),
          'user_id': supabase.auth.currentUser!.id,
          'last_modified': routine.lastModified.toIso8601String(),
          if (routine.remoteId != null) 'id': routine.remoteId,
        };
        final response = await supabase.from('routines').upsert(data).select().single();
        await (db.update(db.routines)..where((t) => t.id.equals(routine.id))).write(
          RoutinesCompanion(
            remoteId: Value(response['id'] as String),
            isSynced: const Value(true),
          ),
        );
      } catch (e) {
        print('Push error (routine): $e');
      }
    }
  }

  Future<void> _pushDayPlans() async {
    final unsynced = await (db.select(db.dayPlans)..where((t) => t.isSynced.equals(false))).get();
    for (final plan in unsynced) {
      try {
        final routine = await (db.select(db.routines)..where((t) => t.id.equals(plan.routineId))).getSingle();
        if (routine.remoteId == null) continue;

        final data = {
          'routine_id': routine.remoteId,
          'day_index': plan.dayIndex,
          'is_rest': plan.isRest,
          'exercise_plans': plan.exercisePlans.map((e) => e.toJson()).toList(),
          'user_id': supabase.auth.currentUser!.id,
          'last_modified': plan.lastModified.toIso8601String(),
          if (plan.remoteId != null) 'id': plan.remoteId,
        };
        final response = await supabase.from('day_plans').upsert(data).select().single();
        await (db.update(db.dayPlans)..where((t) => t.id.equals(plan.id))).write(
          DayPlansCompanion(
            remoteId: Value(response['id'] as String),
            isSynced: const Value(true),
          ),
        );
      } catch (e) {
        print('Push error (dayPlan): $e');
      }
    }
  }

  Future<void> _pushSetLogs() async {
    final unsynced = await (db.select(db.setLogs)..where((t) => t.isSynced.equals(false))).get();
    for (final log in unsynced) {
      try {
        // Map local routine ID to remote ID
        final routine = await (db.select(db.routines)..where((t) => t.id.equals(log.routineId))).getSingleOrNull();
        final remoteRoutineId = routine?.remoteId ?? log.routineId;

        final data = {
          'exercise_name': log.exerciseName,
          'weight': log.weightKg,
          'reps': log.reps,
          'timestamp': log.timestamp.toIso8601String(),
          'routine_id': remoteRoutineId, 
          'day_index': log.dayIndex,
          'user_id': supabase.auth.currentUser!.id,
          'last_modified': log.lastModified.toIso8601String(),
          'set_type': log.setType,
          if (log.remoteId != null) 'id': log.remoteId,
        };
        final response = await supabase.from('set_logs').upsert(data).select().single();
        await (db.update(db.setLogs)..where((t) => t.id.equals(log.id))).write(
          SetLogsCompanion(
            remoteId: Value(response['id'] as String),
            isSynced: const Value(true),
          ),
        );
      } catch (e) {
        print('Push error (setLog): $e');
      }
    }
  }
}

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
    db: ref.watch(databaseProvider),
    supabase: sb.Supabase.instance.client,
  );
});
