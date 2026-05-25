import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/schedule_repository.dart';
import '../../routine/domain/routine_repository.dart';
import '../../routine/presentation/routine_list_screen.dart';
import '../../workout/presentation/active_workout_screen.dart';
import '../../analytics/presentation/analytics_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleRepository = ref.watch(scheduleRepositoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Mettle', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, size: 28),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Training',
              style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ready for today?',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            FutureBuilder(
              future: scheduleRepository.getTodayRoutine(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final routine = snapshot.data;
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fitness_center_rounded, 
                            color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            routine != null ? 'Today\'s Program' : 'Rest & Recover',
                            style: TextStyle(
                              fontSize: 16, 
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        routine?.name ?? 'Take it easy today, or pick a new goal.',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          if (routine != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ActiveWorkoutScreen(routine: routine),
                              ),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RoutineListScreen()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 64),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(
                          routine != null ? 'START WORKOUT' : 'EXPLORE PROGRAMS',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Week',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RoutineListScreen()),
                    );
                  },
                  child: const Text('All Programs'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder(
              stream: scheduleRepository.watchWeeklySchedule(),
              builder: (context, snapshot) {
                final schedule = snapshot.data ?? [];
                return Container(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final dayIndex = index + 1;
                      final isToday = dayIndex == DateTime.now().weekday;
                      
                      ScheduleWithRoutine? item;
                      try {
                        item = schedule.firstWhere(
                          (s) => s.schedule.dayOfWeek == dayIndex,
                        );
                      } catch (_) {
                        item = null;
                      }

                      return GestureDetector(
                        onTap: () => _showSchedulePicker(context, ref, dayIndex),
                        child: Container(
                          width: 64,
                          decoration: BoxDecoration(
                            color: isToday 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isToday 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.grey[200]!,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getDayAbbreviation(dayIndex),
                                style: TextStyle(
                                  color: isToday ? Colors.white : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (item != null)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isToday ? Colors.white : Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                                const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getDayAbbreviation(int day) {
    switch (day) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  void _showSchedulePicker(BuildContext context, WidgetRef ref, int dayOfWeek) async {
    final routines = await ref.read(routineRepositoryProvider).watchRoutines().first;
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Program for ${_getDayAbbreviation(dayOfWeek)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: routines.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == routines.length) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Rest Day', style: TextStyle(fontSize: 18)),
                          trailing: const Icon(Icons.nightlight_round),
                          onTap: () {
                            // In a real app, we'd delete the schedule entry
                            Navigator.of(context).pop();
                          },
                        );
                      }
                      final routine = routines[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(routine.name, style: const TextStyle(fontSize: 18)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          ref.read(scheduleRepositoryProvider).setSchedule(dayOfWeek, routine.id);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }
}
