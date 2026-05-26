import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class SyncRepository {
  final AppDatabase db;
  final sb.SupabaseClient supabase;

  SyncRepository({required this.db, required this.supabase});

  Future<void> syncAll() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await _syncRoutines();
    await _syncDayPlans();
    await _syncSetLogs();
  }

  Future<void> _syncRoutines() async {
    final unsynced = await (db.select(db.routines)..where((t) => t.isSynced.equals(false))).get();
    for (final routine in unsynced) {
      try {
        final data = {
          'name': routine.name,
          'created_at': routine.createdAt.toIso8601String(),
          'user_id': supabase.auth.currentUser!.id,
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
        print('Sync error (routine): $e');
      }
    }
  }

  Future<void> _syncDayPlans() async {
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
        print('Sync error (dayPlan): $e');
      }
    }
  }

  Future<void> _syncSetLogs() async {
    final unsynced = await (db.select(db.setLogs)..where((t) => t.isSynced.equals(false))).get();
    for (final log in unsynced) {
      try {
        final data = {
          'exercise_name': log.exerciseName,
          'weight': log.weightKg,
          'reps': log.reps,
          'timestamp': log.timestamp.toIso8601String(),
          'routine_id': log.routineId, // local reference, might need mapping if syncing routines
          'day_index': log.dayIndex,
          'user_id': supabase.auth.currentUser!.id,
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
        print('Sync error (setLog): $e');
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
