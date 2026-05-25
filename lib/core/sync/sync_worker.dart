import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'sync_repository.dart';
import '../database/database_provider.dart';
import '../database/supabase_provider.dart';

const syncTaskName = "com.mettle.syncTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Create a new ProviderContainer for the background task
    final container = ProviderContainer();
    try {
      final syncRepo = container.read(syncRepositoryProvider);
      await syncRepo.syncAll();
      return true;
    } catch (e) {
      // In a real app, log this to a service
      return false;
    } finally {
      container.dispose();
    }
  });
}

class SyncWorker {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Set to false in production
    );
  }

  static Future<void> schedulePeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      "1",
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> triggerOneOffSync() async {
    await Workmanager().registerOneOffTask(
      DateTime.now().millisecondsSinceEpoch.toString(),
      syncTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
