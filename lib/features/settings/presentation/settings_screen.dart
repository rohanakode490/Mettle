import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/auth_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('APPEARANCE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
            ],
            selected: {themeMode},
            onSelectionChanged: (val) {
              ref.read(themeModeProvider.notifier).setThemeMode(val.first);
            },
          ),
          const SizedBox(height: 32),
          if (user == null) ...[
            const Text(
              'Sign in to sync your data across devices.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  ).then((_) => setState(() {}));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('SIGN IN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            ListTile(
              title: const Text('Logged in as'),
              subtitle: Text(user.email ?? 'Unknown'),
              trailing: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  setState(() {});
                },
              ),
            ),
            const Divider(),
            const SwitchListTile(
              title: Text('Backup to Cloud'),
              subtitle: Text('Sync your workouts automatically'),
              value: true,
              onChanged: null, // Placeholder
            ),
          ],
          const SizedBox(height: 32),
          const Text('UNITS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const ListTile(
            title: Text('Weight Unit'),
            trailing: Text('kg', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          ),
        ],
      ),
    );
  }
}
