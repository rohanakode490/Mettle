import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'database.dart';

class SeedData {
  static final _uuid = const Uuid();

  static Future<void> seed(AppDatabase db) async {
    final routines = await db.select(db.routines).get();
    if (routines.isNotEmpty) return;

    await db.transaction(() async {
      // 1. 6-Day PPL
      await _insertRoutine(db, '6-Day PPL (Push/Pull/Legs)', {
        0: [ExercisePlan(id: _uuid.v4(), name: 'Bench Press', targetSets: '3', targetReps: '8-12'), ExercisePlan(id: _uuid.v4(), name: 'Overhead Press', targetSets: '3', targetReps: '8-12')],
        1: [ExercisePlan(id: _uuid.v4(), name: 'Deadlift', targetSets: '3', targetReps: '5'), ExercisePlan(id: _uuid.v4(), name: 'Pull Ups', targetSets: '3', targetReps: '8-12')],
        2: [ExercisePlan(id: _uuid.v4(), name: 'Squat', targetSets: '3', targetReps: '8-12'), ExercisePlan(id: _uuid.v4(), name: 'Leg Press', targetSets: '3', targetReps: '12-15')],
        3: [ExercisePlan(id: _uuid.v4(), name: 'Incline Bench', targetSets: '3', targetReps: '8-12')],
        4: [ExercisePlan(id: _uuid.v4(), name: 'Barbell Row', targetSets: '3', targetReps: '8-12')],
        5: [ExercisePlan(id: _uuid.v4(), name: 'Hack Squat', targetSets: '3', targetReps: '10-12')],
        6: [], // Rest
      });

      // 2. 5-Day Bro Split
      await _insertRoutine(db, '5-Day Classic Split', {
        0: [ExercisePlan(id: _uuid.v4(), name: 'Chest Press', targetSets: '4', targetReps: '10')],
        1: [ExercisePlan(id: _uuid.v4(), name: 'Lat Pulldown', targetSets: '4', targetReps: '10')],
        2: [ExercisePlan(id: _uuid.v4(), name: 'Shoulder Press', targetSets: '4', targetReps: '10')],
        3: [ExercisePlan(id: _uuid.v4(), name: 'Squats', targetSets: '4', targetReps: '10')],
        4: [ExercisePlan(id: _uuid.v4(), name: 'Bicep Curls', targetSets: '3', targetReps: '12'), ExercisePlan(id: _uuid.v4(), name: 'Tricep Pushdown', targetSets: '3', targetReps: '12')],
        5: [], 6: [],
      });

      // 3. 4-Day Upper/Lower
      await _insertRoutine(db, '4-Day Upper/Lower', {
        0: [ExercisePlan(id: _uuid.v4(), name: 'Bench Press', targetSets: '3-4', targetReps: '6-8')],
        1: [ExercisePlan(id: _uuid.v4(), name: 'Squat', targetSets: '3-4', targetReps: '6-8')],
        2: [], 
        3: [ExercisePlan(id: _uuid.v4(), name: 'Overhead Press', targetSets: '3-4', targetReps: '8-10')],
        4: [ExercisePlan(id: _uuid.v4(), name: 'Deadlift', targetSets: '3-4', targetReps: '5')],
        5: [], 6: [],
      });

      // 4. 3-Day Full Body
      await _insertRoutine(db, '3-Day Full Body', {
        0: [ExercisePlan(id: _uuid.v4(), name: 'Squat', targetSets: '3', targetReps: '8-10'), ExercisePlan(id: _uuid.v4(), name: 'Bench Press', targetSets: '3', targetReps: '8-10'), ExercisePlan(id: _uuid.v4(), name: 'Row', targetSets: '3', targetReps: '8-10')],
        1: [],
        2: [ExercisePlan(id: _uuid.v4(), name: 'Deadlift', targetSets: '3', targetReps: '5'), ExercisePlan(id: _uuid.v4(), name: 'OHP', targetSets: '3', targetReps: '8-10'), ExercisePlan(id: _uuid.v4(), name: 'Pull Ups', targetSets: '3', targetReps: 'AMRAP')],
        3: [],
        4: [ExercisePlan(id: _uuid.v4(), name: 'Leg Press', targetSets: '3', targetReps: '12'), ExercisePlan(id: _uuid.v4(), name: 'Incline DB Press', targetSets: '3', targetReps: '10'), ExercisePlan(id: _uuid.v4(), name: 'Curls', targetSets: '3', targetReps: '12')],
        5: [], 6: [],
      });
    });
  }

  static Future<void> _insertRoutine(AppDatabase db, String name, Map<int, List<ExercisePlan>> days) async {
    final routineId = _uuid.v4();
    await db.into(db.routines).insert(RoutinesCompanion.insert(id: routineId, name: name));
    for (int i = 0; i < 7; i++) {
      final plans = days[i] ?? [];
      await db.into(db.dayPlans).insert(DayPlansCompanion.insert(
        id: _uuid.v4(),
        routineId: routineId,
        dayIndex: i,
        isRest: Value(plans.isEmpty),
        exercisePlans: plans,
      ));
    }
  }
}
