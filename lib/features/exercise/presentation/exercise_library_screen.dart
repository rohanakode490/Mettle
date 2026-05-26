import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/core/database/database.dart';
import '../domain/exercise_repository.dart';

// Using simple Notifiers since StateProvider is unavailable or restricted in this project's version
class SearchQueryNotifier extends AutoDisposeNotifier<String> {
  @override
  String build() => '';
  void update(String query) => state = query;
}

final exerciseSearchQueryProvider = NotifierProvider.autoDispose<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class MuscleGroupNotifier extends AutoDisposeNotifier<String?> {
  @override
  String? build() => null;
  void set(String? group) => state = group;
}

final selectedMuscleGroupProvider = NotifierProvider.autoDispose<MuscleGroupNotifier, String?>(MuscleGroupNotifier.new);

final filteredExercisesProvider = Provider.autoDispose<AsyncValue<List<Exercise>>>((ref) {
  final exercisesAsync = ref.watch(exercisesStreamProvider);
  final searchQuery = ref.watch(exerciseSearchQueryProvider).toLowerCase();
  final selectedMuscleGroup = ref.watch(selectedMuscleGroupProvider);

  return exercisesAsync.whenData((exercises) {
    return exercises.where((exercise) {
      final matchesSearch = exercise.name.toLowerCase().contains(searchQuery);
      final matchesMuscleGroup = selectedMuscleGroup == null || 
                                exercise.muscleGroup == selectedMuscleGroup;
      return matchesSearch && matchesMuscleGroup;
    }).toList();
  });
});

class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key});

  void _showFilters(BuildContext context, WidgetRef ref) {
    final muscleGroups = ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final selectedMuscleGroup = ref.watch(selectedMuscleGroupProvider);
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by Muscle',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: selectedMuscleGroup == null,
                        onSelected: (_) {
                          ref.read(selectedMuscleGroupProvider.notifier).set(null);
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: Colors.blue[50],
                        checkmarkColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      ...muscleGroups.map((group) => FilterChip(
                        label: Text(group),
                        selected: selectedMuscleGroup == group,
                        onSelected: (selected) {
                          ref.read(selectedMuscleGroupProvider.notifier).set(selected ? group : null);
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: Colors.blue[50],
                        checkmarkColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[200]!),
                      )),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Show Results'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredExercisesAsync = ref.watch(filteredExercisesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Choose a Movement',
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
        toolbarHeight: 80,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      onChanged: (value) => ref.read(exerciseSearchQueryProvider.notifier).update(value),
                      decoration: const InputDecoration(
                        hintText: 'What movement today?',
                        prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showFilters(context, ref),
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: filteredExercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 48, color: Colors.blue[200]),
                          const SizedBox(height: 24),
                          const Text(
                            'No movements found yet.\nTry a different name?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey, 
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: exercises.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return ExerciseCard(exercise: exercise);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;

  const ExerciseCard({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          exercise.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            exercise.muscleGroup ?? 'Other',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ),
        trailing: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.add, size: 20, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added ${exercise.name}'),
                  backgroundColor: Colors.black,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ),
        onTap: () {
          // Show exercise details
        },
      ),
    );
  }
}
