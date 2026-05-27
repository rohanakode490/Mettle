import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';
import 'dart:math';

part 'analytics_repository.g.dart';

class ChartPoint {
  final DateTime date;
  final double value;

  ChartPoint({required this.date, required this.value});
}

class AnalyticsRepository {
  final AppDatabase db;

  AnalyticsRepository(this.db);

  Future<List<ChartPoint>> getMaxWeightHistory(String exerciseName) async {
    final query = db.selectOnly(db.setLogs)
      ..addColumns([db.setLogs.timestamp, db.setLogs.weightKg.max()])
      ..where(db.setLogs.exerciseName.equals(exerciseName))
      ..groupBy([db.setLogs.timestamp.date]);

    final rows = await query.get();
    
    return rows.map((row) {
      return ChartPoint(
        date: row.read(db.setLogs.timestamp)!,
        value: row.read(db.setLogs.weightKg.max()) ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<ChartPoint>> getVolumeHistory(String exerciseName) async {
    // DRIFT doesn't directly support sum(weight * reps) in selectOnly as easily as raw SQL
    // So we fetch and aggregate in Dart for simplicity and reliability across platforms
    final query = db.select(db.setLogs)
      ..where((t) => t.exerciseName.equals(exerciseName))
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]);

    final logs = await query.get();
    
    final Map<DateTime, double> grouped = {};
    for (final log in logs) {
      final date = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      final volume = log.weightKg * log.reps;
      grouped[date] = (grouped[date] ?? 0) + volume;
    }

    return grouped.entries
        .map((e) => ChartPoint(date: e.key, value: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<ChartPoint>> getOneRepMaxHistory(String exerciseName) async {
    final query = db.select(db.setLogs)
      ..where((t) => t.exerciseName.equals(exerciseName))
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]);

    final logs = await query.get();
    
    final Map<DateTime, double> grouped = {};
    for (final log in logs) {
      final date = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      // Epley Formula: 1RM = Weight * (1 + Reps / 30)
      // Only for reps > 1. If reps = 1, 1RM = weight.
      final double estimated1RM;
      if (log.reps > 1) {
        estimated1RM = log.weightKg * (1 + log.reps / 30.0);
      } else {
        estimated1RM = log.weightKg;
      }
      
      grouped[date] = max(grouped[date] ?? 0, estimated1RM);
    }

    return grouped.entries
        .map((e) => ChartPoint(date: e.key, value: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}

@riverpod
AnalyticsRepository analyticsRepository(Ref ref) {
  return AnalyticsRepository(ref.watch(databaseProvider));
}
