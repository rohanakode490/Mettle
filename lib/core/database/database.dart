import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

class ExercisePlan {
  final String id;
  final String name;
  final String? targetSets;
  final String? targetReps;

  ExercisePlan({required this.id, required this.name, this.targetSets, this.targetReps});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'targetSets': targetSets,
    'targetReps': targetReps,
  };

  factory ExercisePlan.fromJson(Map<String, dynamic> json) => ExercisePlan(
    id: json['id'] as String? ?? const Uuid().v4(),
    name: json['name'] as String,
    targetSets: json['targetSets'] as String?,
    targetReps: json['targetReps'] as String?,
  );
}

@DataClassName('Routine')
class Routines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get remoteId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DayPlan')
class DayPlans extends Table {
  TextColumn get id => text()();
  TextColumn get routineId => text().references(Routines, #id)();
  IntColumn get dayIndex => integer()(); // 0-6
  BoolColumn get isRest => boolean().withDefault(const Constant(true))();
  TextColumn get exercisePlans => text().map(const ExercisePlanListConverter())();
  TextColumn get remoteId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SetLog')
class SetLogs extends Table {
  TextColumn get id => text()();
  TextColumn get exerciseName => text()();
  RealColumn get weightKg => real()();
  IntColumn get reps => integer()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get routineId => text()();
  IntColumn get dayIndex => integer()();
  TextColumn get remoteId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();
  TextColumn get setType => text().withDefault(const Constant('work'))(); // 'warmup' or 'work'

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Exercise')
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get muscleGroup => text().nullable()(); // Chest, Back, Legs, etc.
  TextColumn get remoteId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class ExercisePlanListConverter extends TypeConverter<List<ExercisePlan>, String> {
  const ExercisePlanListConverter();

  @override
  List<ExercisePlan> fromSql(String fromDb) {
    return (json.decode(fromDb) as List).map((i) => ExercisePlan.fromJson(i as Map<String, dynamic>)).toList();
  }

  @override
  String toSql(List<ExercisePlan> value) {
    return json.encode(value.map((i) => i.toJson()).toList());
  }
}

@DriftDatabase(tables: [Routines, DayPlans, SetLogs, Exercises])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 8) {
          for (final table in allTables) {
            await m.drop(table);
          }
          await m.createAll();
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
