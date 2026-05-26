import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_log/core/database/database.dart';
import '../domain/routine_repository.dart';

final activeRoutineProvider = FutureProvider<Routine?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  const key = 'active_routine_id';
  final id = prefs.getString(key);
  if (id == null) return null;

  final routines = await ref.watch(routineRepositoryProvider).getAllRoutines();
  try {
    return routines.firstWhere((r) => r.id == id);
  } catch (_) {
    return null;
  }
});

final routineWithPlansProvider = FutureProvider.family<RoutineWithPlans, String>((ref, routineId) {
  return ref.watch(routineRepositoryProvider).getRoutineWithPlans(routineId);
});

class ActiveRoutineController extends Notifier<void> {
  static const _key = 'active_routine_id';

  @override
  void build() {}

  Future<void> setActive(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);
    ref.invalidate(activeRoutineProvider);
  }
}

final activeRoutineControllerProvider = NotifierProvider<ActiveRoutineController, void>(() => ActiveRoutineController());
