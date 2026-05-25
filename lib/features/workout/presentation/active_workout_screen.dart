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
        title: Text(widget.routine?.name ?? 'Free Session', 
          style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: _finishWorkout,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              child: const Text('FINISH'),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        itemCount: _exercises.length,
        itemBuilder: (context, index) {
          final exercise = _exercises[index];
          final sets = _sets[exercise.id] ?? [];
          return Container(
            margin: const EdgeInsets.only(bottom: 24.0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ...sets.asMap().entries.map((entry) {
                  final setIndex = entry.key;
                  final setDraft = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${setIndex + 1}', 
                              style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (setDraft.previousSet != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PREVIOUS', 
                                  style: TextStyle(fontSize: 9, color: Colors.grey[400], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                Text(
                                  '${setDraft.previousSet!.weight}kg × ${setDraft.previousSet!.reps}',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        else
                          const Spacer(),
                        _CompactInputField(
                          hint: 'kg',
                          onChanged: (v) => setDraft.weight = double.tryParse(v) ?? 0,
                        ),
                        const SizedBox(width: 8),
                        _CompactInputField(
                          hint: 'reps',
                          width: 60,
                          onChanged: (v) => setDraft.reps = int.tryParse(v) ?? 0,
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: setDraft.isDone,
                          activeColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => setDraft.isDone = v ?? false),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _addSet(exercise.id),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Add Set', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompactInputField extends StatelessWidget {
  final String hint;
  final double width;
  final ValueChanged<String> onChanged;

  const _CompactInputField({
    required this.hint,
    this.width = 70,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 44,
      child: TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[300], fontWeight: FontWeight.normal),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
