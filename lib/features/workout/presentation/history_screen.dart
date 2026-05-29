import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database.dart';
import '../domain/workout_repository.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historicalSetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
      ),
      body: historyAsync.when(
        data: (sets) {
          if (sets.isEmpty) {
            return const Center(child: Text('No history found.'));
          }

          // Group sets by date
          final groupedSets = <String, List<SetLog>>{};
          for (final set in sets) {
            final dateStr = DateFormat('EEEE, d MMMM yyyy').format(set.timestamp);
            groupedSets.putIfAbsent(dateStr, () => []).add(set);
          }

          final dates = groupedSets.keys.toList();

          return ListView.builder(
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final setsForDate = groupedSets[date]!;

              // Group sets for the same date by exercise
              final exerciseGroups = <String, List<SetLog>>{};
              for (final set in setsForDate) {
                exerciseGroups.putIfAbsent(set.exerciseName, () => []).add(set);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                  ...exerciseGroups.entries.map((group) {
                    return _ExerciseHistoryCard(
                      exerciseName: group.key,
                      sets: group.value,
                    );
                  }),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ExerciseHistoryCard extends StatelessWidget {
  final String exerciseName;
  final List<SetLog> sets;

  const _ExerciseHistoryCard({
    required this.exerciseName,
    required this.sets,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exerciseName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...sets.asMap().entries.map((entry) {
              final idx = entry.key;
              final set = entry.value;
              return _HistorySetRow(
                index: idx + 1,
                setLog: set,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _HistorySetRow extends ConsumerWidget {
  final int index;
  final SetLog setLog;

  const _HistorySetRow({
    required this.index,
    required this.setLog,
  });

  void _editSet(BuildContext context, WidgetRef ref) {
    final weightController = TextEditingController(text: setLog.weightKg.toString());
    final repsController = TextEditingController(text: setLog.reps.toString());
    String currentType = setLog.setType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${setLog.exerciseName} Set'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Type: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: currentType,
                    items: const [
                      DropdownMenuItem(value: 'warmup', child: Text('Warmup')),
                      DropdownMenuItem(value: 'work', child: Text('Working')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => currentType = val);
                    },
                  ),
                ],
              ),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: repsController,
                decoration: const InputDecoration(labelText: 'Reps'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                ref.read(workoutRepositoryProvider).deleteSetLog(setLog.id);
                Navigator.pop(context);
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                final weight = double.tryParse(weightController.text) ?? 0;
                final reps = int.tryParse(repsController.text) ?? 0;
                if (weight > 0 && reps > 0) {
                  ref.read(workoutRepositoryProvider).updateSetLog(
                    id: setLog.id,
                    weight: weight,
                    reps: reps,
                    setType: currentType,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: setLog.setType == 'warmup' ? Colors.orange.withValues(alpha: 0.2) : Colors.teal.withValues(alpha: 0.2),
            child: Text(
              setLog.setType == 'warmup' ? 'W' : 'S',
              style: TextStyle(
                fontSize: 10,
                color: setLog.setType == 'warmup' ? Colors.orange : Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('Set $index', style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('${setLog.weightKg} kg × ${setLog.reps} reps'),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
            onPressed: () => _editSet(context, ref),
          ),
        ],
      ),
    );
  }
}
