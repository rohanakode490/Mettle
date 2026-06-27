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

  testWidgets('Clicking checkmark twice unchecks a set', (tester) async {
    final routineId = 'r1';
    await db.into(db.routines).insert(
          RoutinesCompanion.insert(id: routineId, name: 'Test Routine'),
        );
    
    SharedPreferences.setMockInitialValues({'active_routine_id': routineId});

    final today = (DateTime.now().weekday - 1) % 7;
    await db.into(db.dayPlans).insert(
          DayPlansCompanion.insert(
            id: 'dp1',
            routineId: routineId,
            dayIndex: today,
            isRest: const Value(false),
            exercisePlans: [ExercisePlan(id: 'e1', name: 'Bench Press', targetSets: '1', targetReps: '10')],
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

    // Expand the exercise card
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();

    // 1. Log a set
    // Find text fields for weight and reps
    final weightField = find.widgetWithText(TextField, ''); // It has hintText 'kg' but we can use index
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));
    
    await tester.enterText(textFields.at(0), '60');
    await tester.enterText(textFields.at(1), '10');
    
    // Tap the checkmark outline icon
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();
    
    // Verify it is logged (icon changes to check_circle)
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    
    // 2. Click checkmark again (without changes) to uncheck
    await tester.tap(find.byIcon(Icons.check_circle));
    await tester.pumpAndSettle();
    
    // Verify it is unchecked (icon changes back to check_circle_outline)
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);

    // 3. Change values and click again - should log it back
    await tester.enterText(textFields.at(0), '65');
    await tester.enterText(textFields.at(1), '10');
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    
    // 4. Change values while logged - should update (remain logged)
    await tester.enterText(textFields.at(0), '70');
    await tester.tap(find.byIcon(Icons.check_circle));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    
    // 5. Tap again without changes - should uncheck
    await tester.tap(find.byIcon(Icons.check_circle));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

    // Force disposal
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });
}
