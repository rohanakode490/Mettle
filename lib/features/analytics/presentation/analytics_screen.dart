import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import '../../workout/domain/workout_repository.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  final String? initialExercise;
  const ProgressScreen({super.key, this.initialExercise});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String? _selectedExercise;
  String _timeRange = '1M';
  List<String> _allExercises = [];
  List<SetLog> _history = [];

  @override
  void initState() {
    super.initState();
    _selectedExercise = widget.initialExercise;
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final pool = await ref.read(workoutRepositoryProvider).getExerciseAutocompletePool();
    setState(() {
      _allExercises = pool;
      if (_selectedExercise == null && pool.isNotEmpty) {
        _selectedExercise = pool.first;
      }
    });
    if (_selectedExercise != null) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    // For simplicity, we query all and filter locally in v1
    final db = ref.read(databaseProvider);
    final query = db.select(db.setLogs)
      ..where((t) => t.exerciseName.equals(_selectedExercise!))
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]);
    
    final results = await query.get();
    
    setState(() {
      _history = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedExercise,
              decoration: const InputDecoration(labelText: 'Movement', border: OutlineInputBorder()),
              items: _allExercises.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                setState(() => _selectedExercise = val);
                _loadHistory();
              },
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '1M', label: Text('1M')),
                ButtonSegment(value: '3M', label: Text('3M')),
                ButtonSegment(value: 'ALL', label: Text('All')),
              ],
              selected: {_timeRange},
              onSelectionChanged: (val) {
                setState(() => _timeRange = val.first);
                // Filter logic would go here in a more robust version
              },
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _history.isEmpty
                  ? const Center(child: Text('No data for this movement yet.'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (_history.isEmpty) return const SizedBox.shrink();
                                final index = value.toInt();
                                if (index < 0 || index >= _history.length) return const SizedBox.shrink();
                                if (index % ( (_history.length / 4).ceil() ) != 0) return const SizedBox.shrink();
                                
                                return Text(
                                  DateFormat('MMM d').format(_history[index].timestamp),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _history.asMap().entries.map((e) {
                              return FlSpot(e.key.toDouble(), e.value.weightKg);
                            }).toList(),
                            isCurved: true,
                            color: Colors.teal,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.teal.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
