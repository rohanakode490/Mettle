import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../workout/domain/workout_repository.dart';
import '../domain/analytics_repository.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  final String? initialExercise;
  const ProgressScreen({super.key, this.initialExercise});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

enum AnalyticsMetric {
  maxWeight('Max Weight', 'kg'),
  volume('Volume', 'kg'),
  oneRepMax('Est. 1RM', 'kg');

  final String label;
  final String unit;
  const AnalyticsMetric(this.label, this.unit);
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String? _selectedExercise;
  AnalyticsMetric _selectedMetric = AnalyticsMetric.maxWeight;
  String _timeRange = '1M';
  List<String> _allExercises = [];
  List<ChartPoint> _history = [];

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
    if (_selectedExercise == null) return;
    
    final repo = ref.read(analyticsRepositoryProvider);
    final List<ChartPoint> data;
    
    switch (_selectedMetric) {
      case AnalyticsMetric.maxWeight:
        data = await repo.getMaxWeightHistory(_selectedExercise!);
        break;
      case AnalyticsMetric.volume:
        data = await repo.getVolumeHistory(_selectedExercise!);
        break;
      case AnalyticsMetric.oneRepMax:
        data = await repo.getOneRepMaxHistory(_selectedExercise!);
        break;
    }
    
    setState(() {
      _history = data;
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SegmentedButton<AnalyticsMetric>(
                    segments: AnalyticsMetric.values.map((m) => ButtonSegment(value: m, label: Text(m.label))).toList(),
                    selected: {_selectedMetric},
                    onSelectionChanged: (val) {
                      setState(() => _selectedMetric = val.first);
                      _loadHistory();
                    },
                  ),
                ],
              ),
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
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (_history.isEmpty) return const SizedBox.shrink();
                                final index = value.toInt();
                                if (index < 0 || index >= _history.length) return const SizedBox.shrink();
                                if (index % ( (_history.length / 4).ceil().clamp(1, 100) ) != 0) return const SizedBox.shrink();
                                
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('MMM d').format(_history[index].date),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true, 
                              reservedSize: 45,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value > 1000 ? '${(value/1000).toStringAsFixed(1)}t' : value.toStringAsFixed(0),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                );
                              }
                            )
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _history.asMap().entries.map((e) {
                              return FlSpot(e.key.toDouble(), e.value.value);
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
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final point = _history[spot.x.toInt()];
                                return LineTooltipItem(
                                  '${DateFormat('MMM d').format(point.date)}\n${point.value.toStringAsFixed(1)} ${_selectedMetric.unit}',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
