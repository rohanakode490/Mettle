import 'package:drift/drift.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';
import 'package:gym_log/core/database/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'sync_repository.g.dart';

class SyncRepository {
  final AppDatabase db;
  final SupabaseClient supabase;

  SyncRepository({required this.db, required this.supabase});

  Future<void> syncAll() async {
    await _syncRoutines();
    await _syncWorkoutSessions();
    await _syncSetLogs();
    // Add more as needed
  }

  Future<void> _syncRoutines() async {
    final unsynced = await (db.select(db.routines)..where((t) => t.isSynced.equals(false))).get();
    
    for (final routine in unsynced) {
      try {
        final response = await supabase.from('routines').upsert({
          'name': routine.name,
          'created_at': routine.createdAt.toIso8601String(),
          if (routine.remoteId != null) 'id': routine.remoteId,
        }).select().single();

        final remoteId = response['id'] as String;
        await (db.update(db.routines)..where((t) => t.id.equals(routine.id))).write(
          RoutinesCompanion(
            remoteId: Value(remoteId),
            isSynced: const Value(true),
          ),
        );
      } catch (e) {
        // Log error and continue with next
        print('Error syncing routine ${routine.id}: $e');
      }
    }
  }

  Future<void> _syncWorkoutSessions() async {
    final unsynced = await (db.select(db.workoutSessions)..where((t) => t.isSynced.equals(false))).get();

    for (final session in unsynced) {
      try {
        final response = await supabase.from('workout_sessions').upsert({
          'start_time': session.startTime.toIso8601String(),
          'end_time': session.endTime?.toIso8601String(),
          'note': session.note,
          if (session.remoteId != null) 'id': session.remoteId,
        }).select().single();

        final remoteId = response['id'] as String;
        await (db.update(db.workoutSessions)..where((t) => t.id.equals(session.id))).write(
          WorkoutSessionsCompanion(
            remoteId: Value(remoteId),
            isSynced: const Value(true),
          ),
        );
      } catch (e) {
        print('Error syncing session ${session.id}: $e');
      }
    }
  }

  Future<void> _syncSetLogs() async {
    final unsynced = await (db.select(db.setLogs)..where((t) => t.isSynced.equals(false))).get();

    for (final log in unsynced) {
      try {
        // Need to ensure the session and exercise also have remoteIds
        final session = await (db.select(db.workoutSessions)..where((t) => t.id.equals(log.workoutSessionId))).getSingle();
        if (session.remoteId == null) continue; // Sync session first

        final response = await supabase.from('set_logs').upsert({
          'workout_session_id': session.remoteId,
          'weight': log.weight,
          'reps': log.reps,
          'order_index': log.orderIndex,
          'created_at': log.createdAt.toIso8601String(),
          if (log.remoteId != null) 'id': log.remoteId,
        }).select().single();

        final remoteId = response['id'] as String;
        await (db.update(db.setLogs)..where((t) => t.id.equals(log.id))).write(
          SetLogsCompanion(
            remoteId: Value(remoteId),
            isSynced: const Value(true),
          ),
        );
      } catch (e) {
        print('Error syncing set log ${log.id}: $e');
      }
    }
  }
}

@riverpod
SyncRepository syncRepository(Ref ref) {
  return SyncRepository(
    db: ref.watch(databaseProvider),
    supabase: ref.watch(supabaseClientProvider),
  );
}
