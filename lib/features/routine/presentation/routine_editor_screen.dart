import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/routine_repository.dart';
import '../../workout/domain/workout_repository.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/mettle_input.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  final String? routineId;
  const RoutineEditorScreen({super.key, this.routineId});

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final Map<int, List<ExercisePlan>> _weeklyExercises = {
    0: [], 1: [], 2: [], 3: [], 4: [], 5: [], 6: [],
  };
  final Map<int, bool> _isRestDay = {
    0: true, 1: true, 2: true, 3: true, 4: true, 5: true, 6: true,
  };
  List<String> _autocompletePool = [];

  final List<String> _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    _autocompletePool = await ref.read(workoutRepositoryProvider).getExerciseAutocompletePool();
    if (widget.routineId != null) {
      final routineWithPlans = await ref.read(routineRepositoryProvider).getRoutineWithPlans(widget.routineId!);
      setState(() {
        _nameController.text = routineWithPlans.routine.name;
        for (final plan in routineWithPlans.plans) {
          _weeklyExercises[plan.dayIndex] = List.from(plan.exercisePlans);
          _isRestDay[plan.dayIndex] = plan.isRest;
        }
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showTargetDialog(int dayIndex, String name) async {
    final setsController = TextEditingController();
    final repsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Targets for $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MettleInput(
                  label: 'Sets',
                  hint: '3-4',
                  controller: setsController,
                  keyboardType: TextInputType.text,
                  width: 80,
                ),
                const SizedBox(width: 16),
                MettleInput(
                  label: 'Reps',
                  hint: '8-12',
                  controller: repsController,
                  keyboardType: TextInputType.text,
                  width: 120,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final sets = setsController.text.isEmpty ? null : setsController.text;
              final reps = repsController.text.isEmpty ? null : repsController.text;
              _addExercise(dayIndex, name, sets, reps);
              Navigator.pop(context);
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _addExercise(int dayIndex, String name, String? sets, String? reps) {
    if (name.isEmpty) return;
    setState(() {
      _weeklyExercises[dayIndex]!.add(ExercisePlan(
        id: const Uuid().v4(),
        name: name,
        targetSets: sets,
        targetReps: reps,
      ));
      _isRestDay[dayIndex] = false;
      if (!_autocompletePool.contains(name)) {
        _autocompletePool.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routineId == null ? 'Build Program' : 'Edit Program'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _days.map((d) => Tab(text: d)).toList(),
          labelColor: Colors.teal,
          indicatorColor: Colors.teal,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Program Name',
                hintText: 'e.g. Hypertrophy PPL',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(7, (index) => _buildDayEditor(index)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isEmpty) return;
                  if (widget.routineId == null) {
                    await ref.read(routineRepositoryProvider).saveRoutine(_nameController.text, _weeklyExercises);
                  } else {
                    await ref.read(routineRepositoryProvider).updateRoutine(widget.routineId!, _nameController.text, _weeklyExercises);
                  }
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('SAVE PROGRAM'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayEditor(int dayIndex) {
    final exercises = _weeklyExercises[dayIndex]!;
    final isRest = _isRestDay[dayIndex]!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        SwitchListTile(
          title: const Text('Rest Day', style: TextStyle(fontWeight: FontWeight.bold)),
          value: isRest,
          onChanged: (val) {
            setState(() {
              _isRestDay[dayIndex] = val;
              if (val) _weeklyExercises[dayIndex]!.clear();
            });
          },
          activeColor: Colors.teal,
        ),
        if (!isRest) ...[
          const SizedBox(height: 16),
          _buildExerciseInput(dayIndex),
          const SizedBox(height: 16),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: exercises.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                final item = _weeklyExercises[dayIndex]!.removeAt(oldIndex);
                _weeklyExercises[dayIndex]!.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final plan = exercises[index];
              return ListTile(
                key: ValueKey(plan.id),
                title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: (plan.targetSets != null || plan.targetReps != null)
                    ? Text('Target: ${plan.targetSets ?? "?"} sets × ${plan.targetReps ?? "?"}')
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                      onPressed: () {
                        setState(() => _weeklyExercises[dayIndex]!.removeAt(index));
                      },
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.drag_handle, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildExerciseInput(int dayIndex) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        return _autocompletePool.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _showTargetDialog(dayIndex, selection);
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Add exercise...',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.teal),
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  _showTargetDialog(dayIndex, textController.text);
                  textController.clear();
                }
              },
            ),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (val) {
            if (val.isNotEmpty) {
              _showTargetDialog(dayIndex, val);
              textController.clear();
            }
          },
        );
      },
    );
  }
}
