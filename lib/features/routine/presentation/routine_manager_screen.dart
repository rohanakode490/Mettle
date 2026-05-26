import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/routine_repository.dart';
import 'routine_editor_screen.dart';
import 'active_routine_provider.dart';
import '../../navigation/presentation/navigation_provider.dart';

class RoutineManagerScreen extends ConsumerWidget {
  const RoutineManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesStream = ref.watch(routineRepositoryProvider).watchRoutines();
    final activeRoutineAsync = ref.watch(activeRoutineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Programs'),
      ),
      body: StreamBuilder(
        stream: routinesStream,
        builder: (context, snapshot) {
          final routines = snapshot.data ?? [];
          final activeRoutine = activeRoutineAsync.value;

          if (routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center_outlined, size: 64, color: Colors.grey[800]),
                  const SizedBox(height: 16),
                  const Text('No programs found.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: routines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final routine = routines[index];
              final isActive = activeRoutine?.id == routine.id;

              return Card(
                color: isActive ? Colors.teal.withOpacity(0.05) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isActive ? Colors.teal.withOpacity(0.3) : Colors.grey[900]!,
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    ref.read(activeRoutineControllerProvider.notifier).setActive(routine.id);
                    // Switch to Home tab instead of popping
                    ref.read(navigationProvider.notifier).setIndex(0);
                  },
                  title: Text(routine.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isActive ? 'Current active program' : 'Tap to set as active'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => RoutineEditorScreen(routineId: routine.id)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          ref.read(routineRepositoryProvider).deleteRoutine(routine.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RoutineEditorScreen()),
          );
        },
        label: const Text('NEW PROGRAM'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}
