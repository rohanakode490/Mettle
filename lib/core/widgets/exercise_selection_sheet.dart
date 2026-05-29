import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mettle_input.dart';

class ExerciseSelectionSheet extends ConsumerStatefulWidget {
  final List<String> autocompletePool;
  final Function(String name, String sets, String reps) onSelected;

  const ExerciseSelectionSheet({
    super.key,
    required this.autocompletePool,
    required this.onSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required List<String> autocompletePool,
    required Function(String name, String sets, String reps) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseSelectionSheet(
        autocompletePool: autocompletePool,
        onSelected: onSelected,
      ),
    );
  }

  @override
  ConsumerState<ExerciseSelectionSheet> createState() => _ExerciseSelectionSheetState();
}

class _ExerciseSelectionSheetState extends ConsumerState<ExerciseSelectionSheet> {
  final _searchController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '8-12');
  String? _selectedExercise;
  List<String> _filteredPool = [];

  @override
  void initState() {
    super.initState();
    _filteredPool = widget.autocompletePool;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _filteredPool = widget.autocompletePool
          .where((e) => e.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedExercise == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Type movement name...',
                  prefixIcon: const Icon(Icons.edit_note, size: 28),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    setState(() => _selectedExercise = val.trim());
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_searchController.text.isNotEmpty && 
                      !_filteredPool.any((e) => e.toLowerCase() == _searchController.text.toLowerCase()))
                    ListTile(
                      leading: const Icon(Icons.add_circle, color: Colors.teal),
                      title: Text('Use "${_searchController.text}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: const Text('Create a new movement'),
                      onTap: () => setState(() => _selectedExercise = _searchController.text),
                    ),
                  ..._filteredPool.map((exercise) => ListTile(
                    title: Text(exercise, style: const TextStyle(fontSize: 18)),
                    trailing: const Icon(Icons.history, size: 20, color: Colors.grey),
                    onTap: () => setState(() => _selectedExercise = exercise),
                  )),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => setState(() => _selectedExercise = null),
                      ),
                      Expanded(
                        child: Text(
                          _selectedExercise!,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'SET TARGETS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: MettleInput(
                          label: 'Sets',
                          controller: _setsController,
                          hint: '3',
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MettleInput(
                          label: 'Reps',
                          controller: _repsController,
                          hint: '8-12',
                          keyboardType: TextInputType.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSelected(
                          _selectedExercise!,
                          _setsController.text.isEmpty ? '3' : _setsController.text,
                          _repsController.text.isEmpty ? '8-12' : _repsController.text,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('ADD MOVEMENT'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
