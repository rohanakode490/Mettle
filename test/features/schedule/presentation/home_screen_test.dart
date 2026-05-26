import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';
import 'package:gym_log/features/schedule/presentation/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('HomeScreen shows empty state when no active routine', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Select or create a routine to begin.'), findsOneWidget);
    expect(find.text('MANAGE ROUTINES'), findsOneWidget);

    // Force disposal
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('HomeScreen shows scheduled routine for today', (tester) async {
    final routineId = 'r1';
    await db.into(db.routines).insert(
          RoutinesCompanion.insert(id: routineId, name: 'Massive Quads'),
        );
    
    // Set active routine in mock SharedPreferences
    SharedPreferences.setMockInitialValues({'active_routine_id': routineId});

    // Add day plans
    final today = (DateTime.now().weekday - 1) % 7;
    await db.into(db.dayPlans).insert(
          DayPlansCompanion.insert(
            id: 'dp1',
            routineId: routineId,
            dayIndex: today,
            isRest: const Value(false),
            exercisePlans: [ExercisePlan(id: 'test-id', name: 'Leg Press')],
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Leg Press'), findsOneWidget);

    // Force disposal
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });
}
