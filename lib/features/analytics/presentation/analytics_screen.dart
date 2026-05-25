import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/analytics_repository.dart';
import '../../../core/database/database.dart';
import '../../routine/domain/routine_repository.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int? _selectedExerciseId;
  List<Exercise> _exercises = [];
  List<ExerciseProgressPoint> _dataPoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final exercises = await ref.read(routineRepositoryProvider).getAllExercises();
    if (exercises.isNotEmpty) {
      setState(() {
        _exercises = exercises;
        _selectedExerciseId = exercises.first.id;
      });
      _loadData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    if (_selectedExerciseId == null) return;
    setState(() => _isLoading = true);
    final data = await ref.read(analyticsRepositoryProvider).getExerciseProgress(_selectedExerciseId!);
    setState(() {
      _dataPoints = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<int>(
              value: _selectedExerciseId,
              isExpanded: true,
              items: _exercises.map((e) {
                return DropdownMenuItem(value: e.id, child: Text(e.name));
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedExerciseId = val);
                _loadData();
              },
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _dataPoints.isEmpty
                      ? const Center(child: Text('No data for this exercise yet.'))
                      : LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: const FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _dataPoints.asMap().entries.map((entry) {
                                  return FlSpot(entry.key.toDouble(), entry.value.maxWeight);
                                }).toList(),
                                isCurved: true,
                                color: Theme.of(context).colorScheme.primary,
                                barWidth: 4,
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
            ),
            const SizedBox(height: 16),
            const Text('Max Weight (kg) over time', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
