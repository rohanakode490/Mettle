import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

final completionProvider = NotifierProvider<CompletionNotifier, Map<String, bool>>(() => CompletionNotifier());

class CompletionNotifier extends Notifier<Map<String, bool>> {
  static const _key = 'completion_ticks';

  @override
  Map<String, bool> build() {
    _load();
    return {};
  }

  String _getDateKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _getDateKey();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return;

    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final todayData = data[dateKey] as Map<String, dynamic>? ?? {};
    state = todayData.map((key, value) => MapEntry(key, value as bool));
  }

  Future<void> toggle(String routineId, String exerciseName) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _getDateKey();
    final jsonStr = prefs.getString(_key);
    
    Map<String, dynamic> allData = {};
    if (jsonStr != null) {
      allData = json.decode(jsonStr) as Map<String, dynamic>;
    }

    final todayData = Map<String, dynamic>.from(allData[dateKey] ?? {});
    final currentStatus = todayData[exerciseName] ?? false;
    todayData[exerciseName] = !currentStatus;
    
    allData[dateKey] = todayData;
    await prefs.setString(_key, json.encode(allData));
    
    state = todayData.map((key, value) => MapEntry(key, value as bool));
  }
}
