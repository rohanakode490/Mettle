import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';

part 'analytics_repository.g.dart';

class ExerciseProgressPoint {
  final DateTime date;
  final double maxWeight;

  ExerciseProgressPoint({required this.date, required this.maxWeight});
}

class AnalyticsRepository {
  final AppDatabase db;

  AnalyticsRepository(this.db);

  Future<List<ExerciseProgressPoint>> getExerciseProgress(String exerciseName) async {
    // Query max weight per day for a specific exercise
    final query = db.selectOnly(db.setLogs)
      ..addColumns([db.setLogs.timestamp, db.setLogs.weightKg.max()])
      ..where(db.setLogs.exerciseName.equals(exerciseName))
      ..groupBy([db.setLogs.timestamp.date]);

    final rows = await query.get();
    
    return rows.map((row) {
      return ExerciseProgressPoint(
        date: row.read(db.setLogs.timestamp)!,
        maxWeight: row.read(db.setLogs.weightKg.max()) ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}

@riverpod
AnalyticsRepository analyticsRepository(Ref ref) {
  return AnalyticsRepository(ref.watch(databaseProvider));
}
