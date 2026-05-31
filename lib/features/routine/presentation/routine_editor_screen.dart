import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/routine_repository.dart';
import '../../workout/domain/workout_repository.dart';
import '../../../core/database/database.dart';
import 'active_routine_provider.dart';
import '../../../core/widgets/exercise_selection_sheet.dart';

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
  bool _isLoading = true;
  List<String> _autocompletePool = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadRoutine();
    _loadAutocomplete();
  }

  Future<void> _loadAutocomplete() async {
    final pool = await ref.read(workoutRepositoryProvider).getExerciseAutocompletePool();
    setState(() {
      _autocompletePool = pool;
    });
  }

  Future<void> _loadRoutine() async {
    if (widget.routineId != null) {
      final routine = await ref.read(routineRepositoryProvider).getRoutineWithPlans(widget.routineId!);
      _nameController.text = routine.routine.name;
      for (final plan in routine.plans) {
        _weeklyExercises[plan.dayIndex] = List.from(plan.exercisePlans);
        _isRestDay[plan.dayIndex] = plan.isRest;
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _addExercise(int dayIndex, String name, String? sets, String? reps) {
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

  void _toggleSuperset(int dayIndex, int index) {
    if (index == 0) return;
    setState(() {
      final exercises = _weeklyExercises[dayIndex]!;
      final current = exercises[index];
      final previous = exercises[index - 1];

      if (current.supersetId != null && current.supersetId == previous.supersetId) {
        // Break the link
        exercises[index] = ExercisePlan(
          id: current.id,
          name: current.name,
          targetSets: current.targetSets,
          targetReps: current.targetReps,
          supersetId: null,
        );
      } else {
        // Link to previous
        final id = previous.supersetId ?? const Uuid().v4();
        if (previous.supersetId == null) {
          exercises[index - 1] = ExercisePlan(
            id: previous.id,
            name: previous.name,
            targetSets: previous.targetSets,
            targetReps: previous.targetReps,
            supersetId: id,
          );
        }
        exercises[index] = ExercisePlan(
          id: current.id,
          name: current.name,
          targetSets: current.targetSets,
          targetReps: current.targetReps,
          supersetId: id,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routineId == null ? 'New Program' : 'Edit Program'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'MON'), Tab(text: 'TUE'), Tab(text: 'WED'),
            Tab(text: 'THU'), Tab(text: 'FRI'), Tab(text: 'SAT'), Tab(text: 'SUN'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Program Name',
                border: InputBorder.none,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(7, (index) => _buildDayEditor(index)),
            ),
          ),
          SafeArea(
            child: Padding(
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
                      ref.invalidate(routineWithPlansProvider(widget.routineId!));
                    }
                    ref.invalidate(activeRoutineProvider);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text('SAVE PROGRAM'),
                ),
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
          activeThumbColor: Colors.teal,
        ),
        if (!isRest) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () {
                ExerciseSelectionSheet.show(
                  context: context,
                  autocompletePool: _autocompletePool,
                  onSelected: (name, sets, reps) {
                    _addExercise(dayIndex, name, sets, reps);
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('CHOOSE A MOVEMENT'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: exercises.length,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final item = _weeklyExercises[dayIndex]!.removeAt(oldIndex);
                _weeklyExercises[dayIndex]!.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final plan = exercises[index];
              final isSuperset = plan.supersetId != null && 
                                index > 0 && 
                                exercises[index-1].supersetId == plan.supersetId;
              
              return Column(
                key: ValueKey(plan.id),
                children: [
                  if (isSuperset)
                    const Padding(
                      padding: EdgeInsets.only(left: 32),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.link, size: 16, color: Colors.teal),
                      ),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Target: ${plan.targetSets ?? "3"} sets × ${plan.targetReps ?? "8-12"} reps'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index > 0)
                          IconButton(
                            icon: Icon(
                              isSuperset ? Icons.link_off : Icons.link,
                              color: isSuperset ? Colors.teal : Colors.grey,
                            ),
                            onPressed: () => _toggleSuperset(dayIndex, index),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _weeklyExercises[dayIndex]!.removeAt(index);
                              if (_weeklyExercises[dayIndex]!.isEmpty) _isRestDay[dayIndex] = true;
                            });
                          },
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
