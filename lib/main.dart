import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/database/database_provider.dart';
import 'core/database/seed_data.dart';
import 'core/sync/sync_worker.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/navigation/presentation/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: .env file not found. Supabase may fail to initialize.");
  }

  // Initialize Supabase using env variables
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (e) {
    print("Error: Failed to initialize Supabase: $e");
  }

  try {
    await SyncWorker.initialize();
    await SyncWorker.schedulePeriodicSync();
  } catch (e) {
    print("Warning: Failed to initialize SyncWorker: $e");
  }

  // Create a container to access providers before runApp
  final container = ProviderContainer();
  
  // Seed the database with initial routines
  print("App: Initializing Database...");
  final db = container.read(databaseProvider);
  print("App: Seeding Data...");
  await SeedData.seed(db);
  print("App: Data Seeding Complete.");

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Gym Log',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const MainNavigationScreen(),
    );
  }
}
