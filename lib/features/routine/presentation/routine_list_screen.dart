import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/routine_repository.dart';
import 'routine_editor_screen.dart';

class RoutineListScreen extends ConsumerWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesStream = ref.watch(routineRepositoryProvider).watchRoutines();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Routines'),
      ),
      body: StreamBuilder(
        stream: routinesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final routines = snapshot.data ?? [];
          if (routines.isEmpty) {
            return const Center(child: Text('No routines found. Create one!'));
          }
          return ListView.builder(
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return ListTile(
                title: Text(routine.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    ref.read(routineRepositoryProvider).deleteRoutine(routine.id);
                  },
                ),
                onTap: () {
                  // Navigate to editor for editing (not implemented yet)
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RoutineEditorScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
