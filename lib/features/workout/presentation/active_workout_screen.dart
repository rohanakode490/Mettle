import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/core/database/database.dart';
import '../domain/workout_repository.dart';

class SetDraft {
  double weight;
  int reps;
  bool isDone;
  SetLog? previousSet;

  SetDraft({this.weight = 0, this.reps = 0, this.isDone = false, this.previousSet});
}

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Routine? routine;
  const ActiveWorkoutScreen({super.key, this.routine});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  int? _sessionId;
  List<Exercise> _exercises = [];
  Map<int, List<SetDraft>> _sets = {}; // exerciseId -> sets
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWorkout();
  }

  Future<void> _initializeWorkout() async {
    final repo = ref.read(workoutRepositoryProvider);
    final sessionId = await repo.startWorkout(widget.routine?.id);
    
    List<Exercise> exercises = [];
    if (widget.routine != null) {
      exercises = await repo.getExercisesForRoutine(widget.routine!.id);
    }

    final Map<int, List<SetDraft>> sets = {};
    for (final exercise in exercises) {
      final prev = await repo.getPreviousSet(
        exerciseId: exercise.id,
        orderIndex: 0,
        currentSessionId: sessionId,
      );
      sets[exercise.id] = [SetDraft(previousSet: prev)];
    }

    if (mounted) {
      setState(() {
        _sessionId = sessionId;
        _exercises = exercises;
        _sets = sets;
        _isLoading = false;
      });
    }
  }

  void _addSet(int exerciseId) async {
    final repo = ref.read(workoutRepositoryProvider);
    final setIndex = _sets[exerciseId]!.length;
    final prev = await repo.getPreviousSet(
      exerciseId: exerciseId,
      orderIndex: setIndex,
      currentSessionId: _sessionId!,
    );
    
    setState(() {
      _sets[exerciseId]!.add(SetDraft(previousSet: prev));
    });
  }

  void _finishWorkout() async {
    final repo = ref.read(workoutRepositoryProvider);
    
    // Log all done sets
    for (final exerciseId in _sets.keys) {
      final sets = _sets[exerciseId]!;
      for (var i = 0; i < sets.length; i++) {
        final s = sets[i];
        if (s.isDone) {
          await repo.logSet(
            sessionId: _sessionId!,
            exerciseId: exerciseId,
            weight: s.weight,
            reps: s.reps,
            orderIndex: i,
          );
        }
      }
    }

    await repo.finishWorkout(_sessionId!, null);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine?.name ?? 'Free Workout'),
        actions: [
          TextButton(
            onPressed: _finishWorkout,
            child: const Text('FINISH', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _exercises.length,
        itemBuilder: (context, index) {
          final exercise = _exercises[index];
          final sets = _sets[exercise.id] ?? [];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...sets.asMap().entries.map((entry) {
                    final setIndex = entry.key;
                    final setDraft = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 12, child: Text('${setIndex + 1}', style: const TextStyle(fontSize: 12))),
                          const SizedBox(width: 8),
                          if (setDraft.previousSet != null)
                            Expanded(
                              child: Text(
                                'Prev: ${setDraft.previousSet!.weight}kg x ${setDraft.previousSet!.reps}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            )
                          else
                            const Spacer(),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'kg'),
                              onChanged: (v) => setDraft.weight = double.tryParse(v) ?? 0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 40,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'reps'),
                              onChanged: (v) => setDraft.reps = int.tryParse(v) ?? 0,
                            ),
                          ),
                          Checkbox(
                            value: setDraft.isDone,
                            onChanged: (v) => setState(() => setDraft.isDone = v ?? false),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => _addSet(exercise.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Set'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
