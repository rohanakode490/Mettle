import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../routine/presentation/active_routine_provider.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../routine/domain/routine_repository.dart';
import '../../workout/domain/workout_repository.dart';
import '../../workout/presentation/completion_provider.dart';
import '../../../core/database/database.dart';
import '../../navigation/presentation/navigation_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRoutineAsync = ref.watch(activeRoutineProvider);
    final today = DateTime.now();
    final dayIndex = (today.weekday - 1) % 7; // Monday = 0, Sunday = 6

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart, color: Colors.teal),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProgressScreen()),
              );
            },
          ),
          activeRoutineAsync.when(
            data: (routine) => _RoutineSelector(activeRoutine: routine),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMM yyyy').format(today),
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              activeRoutineAsync.when(
                data: (routine) {
                  if (routine == null) {
                    return const _EmptyState(message: 'Select or create a routine to begin.');
                  }
                  return _TodayWorkout(routine: routine, dayIndex: dayIndex);
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),

              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineSelector extends ConsumerWidget {
  final Routine? activeRoutine;
  const _RoutineSelector({this.activeRoutine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Routine>>(
      future: ref.read(routineRepositoryProvider).getAllRoutines(),
      builder: (context, snapshot) {
        final routines = snapshot.data ?? [];
        return PopupMenuButton<String>(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                activeRoutine?.name ?? 'No Routine',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal),
                overflow: TextOverflow.ellipsis,
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.teal),
            ],
          ),
          onSelected: (id) {
            if (id == 'manage') {
              ref.read(navigationProvider.notifier).setIndex(1); // Switch to Routines tab
            } else {
              ref.read(activeRoutineControllerProvider.notifier).setActive(id);
            }
          },
          itemBuilder: (context) => [
            ...routines.map((r) => PopupMenuItem(
                  value: r.id,
                  child: Text(r.name),
                )),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'manage',
              child: Text('Manage Routines', style: TextStyle(color: Colors.teal)),
            ),
          ],
        );
      },
    );
  }
}

class _TodayWorkout extends ConsumerWidget {
  final Routine routine;
  final int dayIndex;
  const _TodayWorkout({required this.routine, required this.dayIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(routineWithPlansProvider(routine.id));

    return plansAsync.when(
      data: (data) {
        final plans = data.plans;
        if (plans.isEmpty) {
          return const Center(child: Text('No plan found for this routine.'));
        }
        final plan = plans.firstWhere((p) => p.dayIndex == dayIndex, orElse: () => plans.first);

        if (plan.isRest) {
          return const Center(child: Text('Rest Day'));
        }

        final completion = ref.watch(completionProvider);

        return Column(
          children: plan.exercisePlans.map((p) => ExerciseAccordionCard(
                  key: ValueKey(p.name),
                  plan: p,
                  routineId: routine.id,
                  dayIndex: dayIndex,
                  isCompleted: completion[p.name] ?? false,
                  allCompleted: false,
                )).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class ExerciseAccordionCard extends ConsumerStatefulWidget {
  final ExercisePlan plan;
  final String routineId;
  final int dayIndex;
  final bool isCompleted;
  final bool allCompleted;

  const ExerciseAccordionCard({
    super.key,
    required this.plan,
    required this.routineId,
    required this.dayIndex,
    required this.isCompleted,
    required this.allCompleted,
  });

  @override
  ConsumerState<ExerciseAccordionCard> createState() => _ExerciseAccordionCardState();
}

class _ExerciseAccordionCardState extends ConsumerState<ExerciseAccordionCard> {
  bool _isExpanded = false;
  List<SetLog> _previousSets = [];
  int _extraPlaceholders = 0;

  @override
  void initState() {
    _loadPreviousSets();
    super.initState();
  }

  Future<void> _loadPreviousSets() async {
    final sets = await ref.read(workoutRepositoryProvider).getPreviousSessionSets(widget.plan.name);
    if (mounted) {
      setState(() {
        _previousSets = sets;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            onLongPress: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProgressScreen(initialExercise: widget.plan.name)),
              );
            },
            leading: Checkbox(
              value: widget.isCompleted,
              onChanged: (_) {
                ref.read(completionProvider.notifier).toggle(widget.routineId, widget.plan.name);
              },
            ),
            title: Text(
              widget.plan.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: widget.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.plan.targetSets != null || widget.plan.targetReps != null)
                  Text(
                    'Target: ${widget.plan.targetSets ?? "?"} × ${widget.plan.targetReps ?? "?"}',
                    style: TextStyle(color: Colors.teal.withOpacity(0.8), fontSize: 12),
                  ),
                _previousSets.isNotEmpty
                    ? Text('Last: ${_previousSets.last.weightKg}kg × ${_previousSets.last.reps}', style: const TextStyle(fontSize: 12))
                    : const Text('No history yet', style: TextStyle(fontSize: 12)),
              ],
            ),
            trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        _TodaySetsList(
                          routineId: widget.routineId,
                          dayIndex: widget.dayIndex,
                          exerciseName: widget.plan.name,
                          targetSets: widget.plan.targetSets,
                          previousSets: _previousSets,
                          extraPlaceholders: _extraPlaceholders,
                          onPlaceholderSaved: () {
                            if (mounted && _extraPlaceholders > 0) {
                              setState(() => _extraPlaceholders--);
                            }
                          },
                          onDeletePlaceholder: () {
                            if (mounted && _extraPlaceholders > 0) {
                              setState(() => _extraPlaceholders--);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() => _extraPlaceholders++);
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('ADD EXTRA SET', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _TodaySetsList extends ConsumerWidget {
  final String routineId;
  final int dayIndex;
  final String exerciseName;
  final String? targetSets;
  final List<SetLog> previousSets;
  final int extraPlaceholders;
  final VoidCallback onPlaceholderSaved;
  final VoidCallback onDeletePlaceholder;

  const _TodaySetsList({
    required this.routineId,
    required this.dayIndex,
    required this.exerciseName,
    required this.onPlaceholderSaved,
    required this.onDeletePlaceholder,
    this.targetSets,
    this.previousSets = const [],
    this.extraPlaceholders = 0,
  });

  int _parseTargetCount() {
    if (targetSets == null || targetSets!.isEmpty) return 0;
    final firstNum = RegExp(r'\d+').firstMatch(targetSets!);
    return firstNum != null ? int.parse(firstNum.group(0)!) : 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(todaySetsProvider('$routineId|$dayIndex'));

    return setsAsync.when(
      data: (allSets) {
        final loggedSets = allSets.where((s) => s.exerciseName == exerciseName).toList();
        final previousCount = previousSets.length;
        final targetCount = _parseTargetCount();
        final effectivePlaceholderCount = previousCount > 0 ? previousCount : targetCount;
        
        final List<Widget> rows = [];
        
        // Header
        rows.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('TYPE', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                SizedBox(width: 12),
                Expanded(flex: 3, child: Text('WEIGHT', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('REPS', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                SizedBox(width: 48), // Checkbox area
                SizedBox(width: 40), // Delete area
              ],
            ),
          ),
        );

        final displayRows = <Widget>[];
        
        // Add all logged sets
        for (int i = 0; i < loggedSets.length; i++) {
          displayRows.add(
            _EditableSetRow(
              key: ValueKey(loggedSets[i].id),
              setIndex: i + 1,
              setLog: loggedSets[i],
              exerciseName: exerciseName,
              routineId: routineId,
              dayIndex: dayIndex,
            ),
          );
        }
        
        // Fill placeholders if needed
        final placeholdersNeeded = (effectivePlaceholderCount - loggedSets.length).clamp(0, effectivePlaceholderCount);
        for (int i = 0; i < placeholdersNeeded; i++) {
          final placeholderIndex = loggedSets.length + i;
          final previousSetLog = (placeholderIndex < previousSets.length) ? previousSets[placeholderIndex] : null;
          
          displayRows.add(
            _EditableSetRow(
              key: ValueKey('placeholder-$placeholderIndex'),
              setIndex: placeholderIndex + 1,
              setLog: null,
              previousSetLog: previousSetLog,
              exerciseName: exerciseName,
              routineId: routineId,
              dayIndex: dayIndex,
            ),
          );
        }
        
        // Add extra placeholders
        for (int i = 0; i < extraPlaceholders; i++) {
          final index = (loggedSets.length > effectivePlaceholderCount ? loggedSets.length : effectivePlaceholderCount) + i;
          displayRows.add(
            _EditableSetRow(
              key: ValueKey('extra-$i'),
              setIndex: index + 1,
              setLog: null,
              exerciseName: exerciseName,
              routineId: routineId,
              dayIndex: dayIndex,
              isExtraPlaceholder: true,
              onSaved: onPlaceholderSaved,
              onDeletePlaceholder: onDeletePlaceholder,
            ),
          );
        }

        return Column(children: [rows.first, ...displayRows]);
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
      error: (err, _) => Text('Error: $err'),
    );
  }
}

class _EditableSetRow extends ConsumerStatefulWidget {
  final int setIndex;
  final SetLog? setLog;
  final SetLog? previousSetLog;
  final String exerciseName;
  final String routineId;
  final int dayIndex;
  final bool isExtraPlaceholder;
  final VoidCallback? onSaved;
  final VoidCallback? onDeletePlaceholder;

  const _EditableSetRow({
    super.key,
    required this.setIndex,
    required this.setLog,
    this.previousSetLog,
    required this.exerciseName,
    required this.routineId,
    required this.dayIndex,
    this.isExtraPlaceholder = false,
    this.onSaved,
    this.onDeletePlaceholder,
  });

  @override
  _EditableSetRowState createState() => _EditableSetRowState();
}

class _EditableSetRowState extends ConsumerState<_EditableSetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  bool _isWarmup = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.setLog?.weightKg.toString() ?? '');
    _repsController = TextEditingController(text: widget.setLog?.reps.toString() ?? '');
    _isWarmup = widget.setLog?.setType == 'warmup' || (widget.setLog == null && widget.previousSetLog?.setType == 'warmup');
  }

  @override
  void didUpdateWidget(_EditableSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.setLog != oldWidget.setLog) {
      if (widget.setLog != null) {
        _weightController.text = widget.setLog!.weightKg.toString();
        _repsController.text = widget.setLog!.reps.toString();
        _isWarmup = widget.setLog!.setType == 'warmup';
      } else if (!widget.isExtraPlaceholder) {
        _weightController.clear();
        _repsController.clear();
        _isWarmup = widget.previousSetLog?.setType == 'warmup';
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;

    if (weight > 0 || reps > 0) {
      if (widget.setLog != null) {
        ref.read(workoutRepositoryProvider).updateSetLog(
              id: widget.setLog!.id,
              weight: weight,
              reps: reps,
              setType: _isWarmup ? 'warmup' : 'work',
            );
      } else {
        ref.read(workoutRepositoryProvider).logSet(
              exerciseName: widget.exerciseName,
              weight: weight,
              reps: reps,
              routineId: widget.routineId,
              dayIndex: widget.dayIndex,
              setType: _isWarmup ? 'warmup' : 'work',
            );
        if (widget.isExtraPlaceholder) {
          widget.onSaved?.call();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogged = widget.setLog != null;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // Set Type Toggle (W/S)
          SizedBox(
            width: 40,
            child: TextButton(
              onPressed: () {
                setState(() => _isWarmup = !_isWarmup);
                if (isLogged) {
                  final weight = double.tryParse(_weightController.text) ?? 0;
                  final reps = int.tryParse(_repsController.text) ?? 0;
                  ref.read(workoutRepositoryProvider).updateSetLog(
                        id: widget.setLog!.id,
                        weight: weight,
                        reps: reps,
                        setType: _isWarmup ? 'warmup' : 'work',
                      );
                }
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(30, 30),
                backgroundColor: _isWarmup ? Colors.orange.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: Text(
                _isWarmup ? 'W' : 'S',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isWarmup ? Colors.orange : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Weight Input
          Expanded(
            flex: 3,
            child: TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                hintText: widget.previousSetLog != null ? '${widget.previousSetLog!.weightKg}' : 'kg',
                fillColor: isLogged ? theme.colorScheme.primary.withOpacity(0.05) : null,
                filled: isLogged,
              ),
              onChanged: (_) => _onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          // Reps Input
          Expanded(
            flex: 2,
            child: TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                hintText: widget.previousSetLog != null ? '${widget.previousSetLog!.reps}' : '0',
                fillColor: isLogged ? theme.colorScheme.primary.withOpacity(0.05) : null,
                filled: isLogged,
              ),
              onChanged: (_) => _onChanged(),
            ),
          ),
          // Status Checkmark
          SizedBox(
            width: 48,
            child: Icon(
              isLogged ? Icons.check_circle : Icons.check_circle_outline,
              color: isLogged ? Colors.green : Colors.grey.withOpacity(0.3),
              size: 20,
            ),
          ),
          // Delete Button
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
              onPressed: () {
                if (isLogged) {
                  ref.read(workoutRepositoryProvider).deleteSetLog(widget.setLog!.id);
                } else if (widget.isExtraPlaceholder) {
                  widget.onDeletePlaceholder?.call();
                } else {
                  _weightController.clear();
                  _repsController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 64),
          Icon(Icons.fitness_center, size: 64, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(navigationProvider.notifier).setIndex(1); // Switch to Routines tab
              },
              child: const Text('MANAGE ROUTINES'),
            ),
          ),
        ],
      ),
    );
  }
}
