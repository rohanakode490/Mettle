import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/schedule_repository.dart';
import '../../routine/domain/routine_repository.dart';
import '../../routine/presentation/routine_list_screen.dart';
import '../../workout/presentation/active_workout_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleRepository = ref.watch(scheduleRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mettle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Workout',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: scheduleRepository.getTodayRoutine(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final routine = snapshot.data;
                if (routine == null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('No routine scheduled for today.'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RoutineListScreen()),
                              );
                            },
                            child: const Text('Manage Routines'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ActiveWorkoutScreen(routine: routine),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                            child: const Text('START WORKOUT'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Weekly Schedule',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder(
              stream: scheduleRepository.watchWeeklySchedule(),
              builder: (context, snapshot) {
                final schedule = snapshot.data ?? [];
                return Column(
                  children: List.generate(7, (index) {
                    final dayIndex = index + 1;
                    final dayName = _getDayName(dayIndex);
                    
                    ScheduleWithRoutine? item;
                    try {
                      item = schedule.firstWhere(
                        (s) => s.schedule.dayOfWeek == dayIndex,
                      );
                    } catch (_) {
                      item = null;
                    }

                    return ListTile(
                      title: Text(dayName),
                      subtitle: Text(item?.routine.name ?? 'Rest Day'),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () {
                          _showSchedulePicker(context, ref, dayIndex);
                        },
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RoutineListScreen()),
          );
        },
        tooltip: 'Routines',
        child: const Icon(Icons.fitness_center),
      ),
    );
  }

  void _showSchedulePicker(BuildContext context, WidgetRef ref, int dayOfWeek) async {
    final routines = await ref.read(routineRepositoryProvider).watchRoutines().first;
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return ListView.builder(
            itemCount: routines.length + 1,
            itemBuilder: (context, index) {
              if (index == routines.length) {
                return ListTile(
                  title: const Text('Rest Day'),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                );
              }
              final routine = routines[index];
              return ListTile(
                title: Text(routine.name),
                onTap: () {
                  ref.read(scheduleRepositoryProvider).setSchedule(dayOfWeek, routine.id);
                  Navigator.of(context).pop();
                },
              );
            },
          );
        },
      );
    }
  }

  String _getDayName(int day) {
    switch (day) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }
}
