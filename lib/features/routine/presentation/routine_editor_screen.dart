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
        title: const Text('Build a Program', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Program Name',
                hintText: 'e.g. Morning Push',
                labelStyle: TextStyle(color: Colors.grey[600]),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Movements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showExercisePicker,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Choose a Movement'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              itemCount: _selectedExercises.length,
              itemBuilder: (context, index) {
                final exercise = _selectedExercises[index];
                return Padding(
                  key: ValueKey('${exercise.id}_$index'),
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(exercise.muscleGroup ?? '', style: TextStyle(color: Colors.grey[500])),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                            onPressed: () => _removeExercise(index),
                          ),
                          const Icon(Icons.drag_handle, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
              onReorder: _reorder,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please name your program')),
                  );
                  return;
                }
                if (_selectedExercises.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add at least one movement')),
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
              child: const Text('ALL SET!'),
            ),
          ),
        ],
      ),
    );
  }

  void _showExercisePicker() async {
    final allExercises = await ref.read(routineRepositoryProvider).getAllExercises();
    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
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
                const Text(
                  'Choose a Movement',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: allExercises.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final exercise = allExercises[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(exercise.name, style: const TextStyle(fontSize: 18)),
                        trailing: const Icon(Icons.add_circle_outline, color: Colors.blue),
                        onTap: () {
                          _addExercise(exercise);
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
