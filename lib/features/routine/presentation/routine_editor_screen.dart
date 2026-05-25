import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/features/routine/domain/routine_repository.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  const RoutineEditorScreen({super.key});

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  final _nameController = TextEditingController();
  final List<Exercise> _selectedExercises = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addExercise(Exercise exercise) {
    setState(() {
      _selectedExercises.add(exercise);
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _selectedExercises.removeAt(oldIndex);
      _selectedExercises.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Routine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              if (_nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a routine name')),
                );
                return;
              }
              if (_selectedExercises.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please add at least one exercise')),
                );
                return;
              }

              await ref.read(routineRepositoryProvider).createRoutine(
                    _nameController.text,
                    _selectedExercises.map((e) => e.id).toList(),
                  );
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Routine Name',
                hintText: 'e.g. Leg Day',
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _selectedExercises.length,
              itemBuilder: (context, index) {
                final exercise = _selectedExercises[index];
                return ListTile(
                  key: ValueKey('${exercise.id}_$index'),
                  title: Text(exercise.name),
                  subtitle: Text(exercise.muscleGroup ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeExercise(index),
                  ),
                );
              },
              onReorder: _reorder,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final allExercises = await ref.read(routineRepositoryProvider).getAllExercises();
          if (mounted) {
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return ListView.builder(
                  itemCount: allExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = allExercises[index];
                    return ListTile(
                      title: Text(exercise.name),
                      onTap: () {
                        _addExercise(exercise);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
            );
          }
        },
        label: const Text('Add Exercise'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
