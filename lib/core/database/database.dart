import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

@DataClassName('Exercise')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get muscleGroup => text().nullable()();
}

@DataClassName('Routine')
class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('RoutineExercise')
class RoutineExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer().references(Routines, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
}

@DataClassName('Schedule')
class Schedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer().references(Routines, #id)();
  IntColumn get dayOfWeek => integer().unique()(); // 1-7 (Monday-Sunday)
}

@DataClassName('WorkoutSession')
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer().references(Routines, #id).nullable()();
  DateTimeColumn get startTime => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get note => text().nullable()();
}

@DataClassName('SetLog')
class SetLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutSessionId => integer().references(WorkoutSessions, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  RealColumn get weight => real()();
  IntColumn get reps => integer()();
  IntColumn get orderIndex => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Exercises, Routines, RoutineExercises, Schedules, WorkoutSessions, SetLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> seedExercises() async {
    final count = await select(exercises).get().then((value) => value.length);
    if (count == 0) {
      await batch((batch) {
        batch.insertAll(exercises, [
          ExercisesCompanion.insert(name: 'Bench Press', muscleGroup: const Value('Chest')),
          ExercisesCompanion.insert(name: 'Squat', muscleGroup: const Value('Legs')),
          ExercisesCompanion.insert(name: 'Deadlift', muscleGroup: const Value('Back')),
          ExercisesCompanion.insert(name: 'Overhead Press', muscleGroup: const Value('Shoulders')),
          ExercisesCompanion.insert(name: 'Pull Up', muscleGroup: const Value('Back')),
          ExercisesCompanion.insert(name: 'Barbell Row', muscleGroup: const Value('Back')),
        ]);
      });
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
