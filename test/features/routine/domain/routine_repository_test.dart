import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/features/routine/domain/routine_repository.dart';

void main() {
  late AppDatabase db;
  late RoutineRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = RoutineRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('RoutineRepository', () {
    test('saveRoutine should create a routine and 7 day plans', () async {
      final weeklyExercises = {
        1: [ExercisePlan(id: 'test-id', name: 'Bench Press', targetSets: '3', targetReps: '10')],
        3: [ExercisePlan(id: 'test-id', name: 'Squat', targetSets: '5', targetReps: '5')],
      };

      await repository.saveRoutine('Push/Pull', weeklyExercises);

      final routines = await repository.getAllRoutines();
      expect(routines.length, 1);
      expect(routines.first.name, 'Push/Pull');

      final routineWithPlans = await repository.getRoutineWithPlans(routines.first.id);
      expect(routineWithPlans.plans.length, 7);
      
      final mondayPlan = routineWithPlans.plans.firstWhere((p) => p.dayIndex == 1);
      expect(mondayPlan.isRest, isFalse);
      expect(mondayPlan.exercisePlans.first.name, 'Bench Press');

      final tuesdayPlan = routineWithPlans.plans.firstWhere((p) => p.dayIndex == 2);
      expect(tuesdayPlan.isRest, isTrue);
      expect(tuesdayPlan.exercisePlans, isEmpty);
    });

    test('deleteRoutine should remove routine and all its day plans', () async {
      await repository.saveRoutine('Test', {});
      final routines = await repository.getAllRoutines();
      final routineId = routines.first.id;

      await repository.deleteRoutine(routineId);

      final routinesAfter = await repository.getAllRoutines();
      expect(routinesAfter, isEmpty);

      final dayPlans = await db.select(db.dayPlans).get();
      expect(dayPlans, isEmpty);
    });
  });
}
